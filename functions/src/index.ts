import {onCall, HttpsError} from "firebase-functions/v2/https";
import {onDocumentUpdated} from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import * as crypto from "crypto";
import * as qs from "qs";
import {format} from "date-fns-tz";

admin.initializeApp();
const db = admin.firestore();

// ===================================================================
// FUNCTION 1: TÍNH TOÁN CHIẾT KHẤU ĐẠI LÝ (Giữ nguyên)
// ===================================================================
export const calculateOrderDiscount = onCall(
    {region: "asia-southeast1"},
    async (request) => {
        if (!request.auth) {
            throw new HttpsError("unauthenticated", "Authentication required.");
        }
        const userId = request.auth.uid;
        const orderItems = request.data.items;

        if (!orderItems || !Array.isArray(orderItems)) {
            throw new HttpsError("invalid-argument", "Missing 'items' array.");
        }

        try {
            const userDoc = await db.collection("users").doc(userId).get();
            if (!userDoc.exists) {
                throw new HttpsError("not-found", "User not found.");
            }
            const userRole = userDoc.data()?.role;

            const productIds: string[] = orderItems.map(
                (item: { productId: string }) => item.productId,
            );
            if (productIds.length === 0) return {discount: 0};

            const productsSnapshot = await db.collection("products")
                .where(admin.firestore.FieldPath.documentId(), "in", productIds).get();
            const productsMap = new Map<string, any>();
            productsSnapshot.forEach((doc) => productsMap.set(doc.id, doc.data()));

            let foliarTotalValue = 0;
            let rootTotalValue = 0;

            for (const item of orderItems) {
                const productInfo = productsMap.get(item.productId);
                if (productInfo) {
                    const itemValue = item.subtotal;
                    if (productInfo.productType === "foliar_fertilizer") {
                        foliarTotalValue += itemValue;
                    } else if (productInfo.productType === "root_fertilizer") {
                        rootTotalValue += itemValue;
                    }
                }
            }

            let totalDiscount = 0;
            if ((userRole === "agent_1" || userRole === "agent_2") && (foliarTotalValue > 0 || rootTotalValue > 0)) {
                totalDiscount += calculateDiscountForFoliar(foliarTotalValue, userRole);
                totalDiscount += calculateDiscountForRoot(rootTotalValue, userRole);
            }

            logger.info(`Calculated discount for user ${userId}: ${totalDiscount}`);
            return {discount: totalDiscount};
        } catch (error) {
            logger.error("Error in calculateOrderDiscount:", error);
            throw new HttpsError("internal", "Error calculating discount.", error);
        }
    });

// ===================================================================
// FUNCTION 2: TẠO LINK THANH TOÁN VNPAY (Giữ nguyên)
// ===================================================================
export const createVnpayPaymentUrl = onCall(
    {
        region: "asia-southeast1",
        secrets: ["VNP_TMNCODE", "VNP_HASHSECRET"],
    },
    async (request) => {
        if (!request.auth) {
            throw new HttpsError("unauthenticated", "Authentication required.");
        }
        const {orderId, amount, orderInfo} = request.data;
        if (!orderId || !amount || !orderInfo) {
            throw new HttpsError("invalid-argument", "Missing order data.");
        }

        const tmnCode = process.env.VNP_TMNCODE;
        const secretKey = process.env.VNP_HASHSECRET;
        const vnpUrl = "https://sandbox.vnpayment.vn/paymentv2/vpcpay.html";
        const returnUrl = "https://piv-fertilizer-app.web.app/payment-return";

        if (!tmnCode || !secretKey) {
            logger.error("VNPAY secrets are not configured in environment.");
            throw new HttpsError("internal", "Server configuration error.");
        }

        const createDate = format(new Date(), "yyyyMMddHHmmss", {timeZone: "Asia/Ho_Chi_Minh"});
        const ipAddr = request.rawRequest.ip ?? "127.0.0.1";
        const txnRef = `${orderId.substring(0, 10)}${createDate}`;

        const vnpParams: {[key: string]: any} = {};
        vnpParams["vnp_Version"] = "2.1.0";
        vnpParams["vnp_Command"] = "pay";
        vnpParams["vnp_TmnCode"] = tmnCode;
        vnpParams["vnp_Amount"] = amount * 100;
        vnpParams["vnp_CurrCode"] = "VND";
        vnpParams["vnp_TxnRef"] = txnRef;
        vnpParams["vnp_OrderInfo"] = orderInfo;
        vnpParams["vnp_OrderType"] = "other";
        vnpParams["vnp_Locale"] = "vn";
        vnpParams["vnp_ReturnUrl"] = returnUrl;
        vnpParams["vnp_IpAddr"] = ipAddr;
        vnpParams["vnp_CreateDate"] = createDate;

        const sortedParams: {[key: string]: any} = {};
        Object.keys(vnpParams).sort().forEach((key) => {
            sortedParams[key] = vnpParams[key];
        });

        const signData = qs.stringify(sortedParams, {encode: false});
        const hmac = crypto.createHmac("sha512", secretKey);
        const secureHash = hmac.update(Buffer.from(signData, "utf-8")).digest("hex");
        sortedParams["vnp_SecureHash"] = secureHash;

        const checkoutUrl = vnpUrl + "?" + qs.stringify(sortedParams, {encode: false});

        logger.info(`Created VNPAY URL for order: ${orderId}`);
        return {checkoutUrl: checkoutUrl};
    },
);

// ===================================================================
// FUNCTION 3: TỰ ĐỘNG GIẢI PHÓNG ĐẠI LÝ (Function mới)
// ===================================================================
export const onSalesRepStatusChange = onDocumentUpdated("users/{userId}", async (event) => {
    const beforeData = event.data?.before.data();
    const afterData = event.data?.after.data();

    // Nếu không có dữ liệu trước hoặc sau, thoát
    if (!beforeData || !afterData) {
        logger.info("No data change, function terminated.");
        return null;
    }

    // Điều kiện 1: Chỉ chạy khi tài khoản TRƯỚC ĐÓ là NVKD.
    if (beforeData.role !== "sales_rep") {
        return null;
    }

    // Điều kiện 2: Kiểm tra xem NVKD có bị khóa hoặc bị thay đổi vai trò không.
    const isSuspended = beforeData.status !== "suspended" && afterData.status === "suspended";
    const isRoleChanged = afterData.role !== "sales_rep";

    if (!isSuspended && !isRoleChanged) {
        return null;
    }

    const salesRepId = event.params.userId;
    logger.info(`Sales rep ${salesRepId} has been suspended or role changed. Finding assigned agents...`);

    const agentsSnapshot = await db.collection("users")
        .where("salesRepId", "==", salesRepId)
        .get();

    if (agentsSnapshot.empty) {
        logger.info("No agents found for this sales rep. Nothing to do.");
        return null;
    }

    const batch = db.batch();
    agentsSnapshot.forEach((doc) => {
        logger.log(`Un-assigning agent: ${doc.id}`);
        // Cập nhật salesRepId thành null để giải phóng đại lý
        batch.update(doc.ref, {salesRepId: null});
    });

    await batch.commit();
    logger.info(`Successfully un-assigned ${agentsSnapshot.size} agents from sales rep ${salesRepId}.`);
    return null;
});


// --- Các hàm phụ trợ tính toán (giữ nguyên) ---
function calculateDiscountForFoliar(total: number, role: string): number {
    let discountRate = 0;
    if (role === "agent_1") {
      if (total >= 100000000) discountRate = 0.10;
      else if (total >= 50000000) discountRate = 0.07;
      else if (total >= 30000000) discountRate = 0.05;
      else if (total >= 10000000) discountRate = 0.03;
    } else if (role === "agent_2") {
      if (total >= 50000000) discountRate = 0.10;
      else if (total >= 30000000) discountRate = 0.08;
      else if (total >= 10000000) discountRate = 0.06;
      else if (total >= 3000000) discountRate = 0.04;
    }
    return total * discountRate;
}

function calculateDiscountForRoot(total: number, role: string): number {
    let discountRate = 0;
    if (role === "agent_1") {
      if (total >= 100000000) discountRate = 0.05;
      else if (total >= 50000000) discountRate = 0.03;
    } else if (role === "agent_2") {
      if (total >= 50000000) discountRate = 0.05;
      else if (total >= 30000000) discountRate = 0.03;
    }
    return total * discountRate;
}