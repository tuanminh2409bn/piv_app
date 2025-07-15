import {onCall, HttpsError, CallableRequest} from "firebase-functions/v2/https";
import {
  onDocumentCreated,
  onDocumentUpdated,
  FirestoreEvent,
  QueryDocumentSnapshot,
  Change, // SỬA: Thêm Change
} from "firebase-functions/v2/firestore";
import {DocumentSnapshot} from "firebase-admin/firestore"; // SỬA: Thêm DocumentSnapshot
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import * as crypto from "crypto";
import * as qs from "qs";
import {format} from "date-fns-tz";

admin.initializeApp();
const db = admin.firestore();

// --- HÀM HELPER GỬI THÔNG BÁO DATA-ONLY ---
const sendDataOnlyNotification = async (
  token: string | string[] | undefined,
  data: {[key: string]: string}
) => {
  if (!token || (Array.isArray(token) && token.length === 0)) {
    logger.warn("No valid token provided for notification.", {data});
    return;
  }
  const message = {data};
  try {
    if (Array.isArray(token)) {
      await admin.messaging().sendToDevice(token, message);
    } else {
      await admin.messaging().send({token: token, ...message});
    }
    logger.info("Successfully sent data-only message:", data);
  } catch (error) {
    logger.error("Error sending data-only message:", error, {data});
  }
};

// ===================================================================
// FUNCTION 1: TÍNH TOÁN CHIẾT KHẤU ĐẠI LÝ (Đã đúng region)
// ===================================================================
export const calculateOrderDiscount = onCall(
    {region: "asia-southeast1"},
    async (request: CallableRequest) => {
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
              (item: { productId: string }) => item.productId
            );
            if (productIds.length === 0) return {discount: 0};

            const productsSnapshot = await db.collection("products")
              .where(admin.firestore.FieldPath.documentId(), "in", productIds).get();
            const productsMap = new Map<string, any>();
            productsSnapshot.forEach((doc: QueryDocumentSnapshot) => productsMap.set(doc.id, doc.data()));

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
// FUNCTION 2: TẠO LINK THANH TOÁN VNPAY (Đã đúng region)
// ===================================================================
export const createVnpayPaymentUrl = onCall(
    {
        region: "asia-southeast1",
        secrets: ["VNP_TMNCODE", "VNP_HASHSECRET"],
    },
    async (request: CallableRequest) => {
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
// FUNCTION 3: GỬI THÔNG BÁO KHI CÓ SẢN PHẨM MỚI
// ===================================================================
export const onProductCreated = onDocumentCreated(
    // SỬA: Thêm region
    {document: "products/{productId}", region: "asia-southeast1"},
    async (event: FirestoreEvent<QueryDocumentSnapshot | undefined, {productId: string}>) => {
        const product = event.data?.data();
        if (!product) return null;

        const usersSnapshot = await db.collection("users")
            .where("status", "==", "active")
            .where("role", "in", ["agent_1", "agent_2", "admin"])
            .get();

        const tokens = usersSnapshot.docs
            .map((doc: QueryDocumentSnapshot) => doc.data().fcmToken)
            .filter((token): token is string => !!token);

        if (tokens.length > 0) {
            await sendDataOnlyNotification(tokens, {
                title: "🌟 Có sản phẩm mới!",
                body: `Sản phẩm "${product.name}" vừa được ra mắt. Xem ngay!`,
                type: "new_product",
                productId: event.params.productId,
            });
        }
        return null;
    });

// ===================================================================
// FUNCTION 4: XỬ LÝ KHI THÔNG TIN USER THAY ĐỔI
// ===================================================================
export const onUserUpdate = onDocumentUpdated(
    // SỬA: Thêm region và kiểu cho event
    {document: "users/{userId}", region: "asia-southeast1"},
    async (event: FirestoreEvent<Change<DocumentSnapshot> | undefined, {userId: string}>) => {
        const before = event.data?.before.data();
        const after = event.data?.after.data();

        if (!before || !after) return null;

        const updatedUserId = event.params.userId;
        const updatedUserName = after.displayName ?? "Người dùng";

        // --- Kịch bản 1: Tài khoản được duyệt ---
        if (before.status === "pending_approval" && after.status === "active") {
            await sendDataOnlyNotification(after.fcmToken, {
                title: "✅ Tài khoản đã được duyệt!",
                body: "Chúc mừng! Tài khoản của bạn đã được kích hoạt. Hãy bắt đầu trải nghiệm ngay.",
                type: "account_approved",
                userId: updatedUserId,
            });

            const adminsSnapshot = await db.collection("users").where("role", "==", "admin").get();
            const adminTokens = adminsSnapshot.docs
                .map((doc: QueryDocumentSnapshot) => doc.data().fcmToken)
                .filter((token): token is string => !!token);
            if (adminTokens.length > 0) {
                await sendDataOnlyNotification(adminTokens, {
                    title: "👤 Tài khoản đã được duyệt",
                    body: `Tài khoản của "${updatedUserName}" đã được kích hoạt.`,
                    type: "account_management",
                    userId: updatedUserId,
                });
            }

            if (after.salesRepId) {
                const salesRepDoc = await db.collection("users").doc(after.salesRepId).get();
                await sendDataOnlyNotification(salesRepDoc.data()?.fcmToken, {
                    title: "🎉 Đại lý mới được duyệt!",
                    body: `Tài khoản của đại lý "${updatedUserName}" mà bạn quản lý đã được kích hoạt.`,
                    type: "agent_approved",
                    agentId: updatedUserId,
                });
            }
        }

        // --- Kịch bản 2: Giải phóng đại lý khi NVKD bị khóa hoặc đổi vai trò ---
        const wasSalesRep = before.role === "sales_rep";
        const isNowSuspended = after.status === "suspended";
        const roleChanged = after.role !== "sales_rep";

        if (wasSalesRep && (isNowSuspended || roleChanged)) {
             logger.info(`Sales rep ${updatedUserId} status changed. Un-assigning agents...`);
             const agentsSnapshot = await db.collection("users").where("salesRepId", "==", updatedUserId).get();
             if (!agentsSnapshot.empty) {
                const batch = db.batch();
                agentsSnapshot.forEach((doc: QueryDocumentSnapshot) => {
                    batch.update(doc.ref, {salesRepId: null});
                });
                await batch.commit();
                logger.info(`Un-assigned ${agentsSnapshot.size} agents from Sales Rep ${updatedUserId}.`);
             }
        }
        return null;
    });

// ===================================================================
// FUNCTION 5: GỬI THÔNG BÁO KHI CÓ HOA HỒNG
// ===================================================================
export const onCommissionCreated = onDocumentCreated(
    // SỬA: Thêm region
    {document: "commissions/{commissionId}", region: "asia-southeast1"},
    async (event: FirestoreEvent<QueryDocumentSnapshot | undefined, {commissionId: string}>) => {
        const commission = event.data?.data();
        if (!commission) return null;

        const salesRepId = commission.salesRepId;
        const orderIdShort = commission.orderId.substring(0, 8).toUpperCase();
        const amount = new Intl.NumberFormat("vi-VN", {style: "currency", currency: "VND"}).format(commission.amount);

        try {
            const salesRepDoc = await db.collection("users").doc(salesRepId).get();
            const salesRepData = salesRepDoc.data();

            if (salesRepData) {
                await sendDataOnlyNotification(salesRepData.fcmToken, {
                    title: "💰 Bạn có hoa hồng mới!",
                    body: `Bạn nhận được ${amount} từ đơn hàng #${orderIdShort}.`,
                    type: "new_commission",
                    commissionId: event.params.commissionId,
                });

                const adminsSnapshot = await db.collection("users").where("role", "==", "admin").get();
                const adminTokens = adminsSnapshot.docs
                    .map((doc: QueryDocumentSnapshot) => doc.data().fcmToken)
                    .filter((token): token is string => !!token);

                if (adminTokens.length > 0) {
                    await sendDataOnlyNotification(adminTokens, {
                        title: "📈 Hoa hồng đã được tạo",
                        body: `Hoa hồng ${amount} đã được ghi nhận cho NVKD "${salesRepData.displayName}" từ đơn #${orderIdShort}.`,
                        type: "commission_created_for_admin",
                        commissionId: event.params.commissionId,
                    });
                }
            }
        } catch (e) {
            logger.error(`Error sending commission notification for ${event.params.commissionId}:`, e);
        }
        return null;
    });

// ===================================================================
// CÁC HÀM CŨ (onOrderCreated, onOrderStatusUpdate)
// ===================================================================
export const onOrderCreated = onDocumentCreated(
    // SỬA: Thêm region và kiểu cho event
    {document: "orders/{orderId}", region: "asia-southeast1"},
    async (event: FirestoreEvent<QueryDocumentSnapshot | undefined, {orderId: string}>) => {
        const snapshot = event.data;
        if (!snapshot) return null;
        const orderData = snapshot.data();
        const userId = orderData.userId;
        const userName = orderData.shippingAddress?.recipientName ?? "Quý khách";
        const orderIdShort = event.params.orderId.substring(0, 8).toUpperCase();

        try {
            const userDoc = await db.collection("users").doc(userId).get();
            await sendDataOnlyNotification(userDoc.data()?.fcmToken, {
                title: "🎉 Đặt hàng thành công!",
                body: `Chào ${userName}, đơn hàng #${orderIdShort} của bạn đã được tiếp nhận.`,
                type: "order_status",
                orderId: event.params.orderId,
            });
        } catch (e) { logger.error(`Error queuing notification for agent ${userId}:`, e); }

        const salesRepId = orderData.salesRepId;
        if (salesRepId) {
            try {
                const salesRepDoc = await db.collection("users").doc(salesRepId).get();
                await sendDataOnlyNotification(salesRepDoc.data()?.fcmToken, {
                    title: "📈 Có đơn hàng mới!",
                    body: `Đại lý "${userName}" của bạn vừa đặt đơn hàng #${orderIdShort}.`,
                    type: "new_order_for_rep",
                    orderId: event.params.orderId,
                });
            } catch (e) { logger.error(`Error queuing notification for Sales Rep ${salesRepId}:`, e); }
        }

        try {
            const adminsSnapshot = await db.collection("users").where("role", "==", "admin").get();
            const adminTokens = adminsSnapshot.docs
                .map((doc: QueryDocumentSnapshot) => doc.data().fcmToken) // SỬA: Thêm kiểu
                .filter((token): token is string => !!token);

            if (adminTokens.length > 0) {
                await sendDataOnlyNotification(adminTokens, {
                    title: "🔔 Có đơn hàng mới",
                    body: `Đại lý "${userName}" vừa tạo đơn hàng #${orderIdShort}.`,
                    type: "new_order_for_admin",
                    orderId: event.params.orderId,
                });
            }
        } catch (e) { logger.error("Error queuing notification to admins:", e); }

        return null;
    });

export const onOrderStatusUpdate = onDocumentUpdated(
    // SỬA: Thêm region và kiểu cho event
    {document: "orders/{orderId}", region: "asia-southeast1"},
    async (event: FirestoreEvent<Change<DocumentSnapshot> | undefined, {orderId: string}>) => {
    const beforeData = event.data?.before.data();
    const afterData = event.data?.after.data();

    if (!beforeData || !afterData || beforeData.status === afterData.status) {
        return null;
    }

    const userId = afterData.userId;
    const salesRepId = afterData.salesRepId;
    const userName = afterData.shippingAddress?.recipientName ?? "Khách hàng";
    const orderIdShort = event.params.orderId.substring(0, 8).toUpperCase();
    const newStatus = afterData.status;

    let customerTitle: string | null = null;
    let customerBody: string | null = null;
    let salesRepTitle: string | null = null;
    let salesRepBody: string | null = null;
    let adminTitle: string | null = null;
    let adminBody: string | null = null;

    switch (newStatus) {
        case "processing":
            customerTitle = "✅ Đơn hàng đã được xác nhận";
            customerBody = `Đơn hàng #${orderIdShort} của bạn đang được chuẩn bị.`;
            adminTitle = "⚙️ Đơn hàng đang được xử lý";
            adminBody = `Đơn hàng #${orderIdShort} của đại lý ${userName} đã được xác nhận.`;
            salesRepTitle = adminTitle;
            salesRepBody = adminBody;
            break;
        case "shipped":
            customerTitle = "🚚 Đơn hàng đang được giao";
            customerBody = `Đơn hàng #${orderIdShort} của bạn đang trên đường giao đến bạn.`;
            adminTitle = "🚚 Đơn hàng đã giao";
            adminBody = `Đơn hàng #${orderIdShort} của đại lý ${userName} đã được giao.`;
            salesRepTitle = adminTitle;
            salesRepBody = adminBody;
            break;
        case "completed":
            customerTitle = "✨ Đơn hàng đã hoàn thành";
            customerBody = `Đơn hàng #${orderIdShort} đã được giao thành công. Cảm ơn bạn!`;
            adminTitle = "✨ Đơn hàng hoàn thành";
            adminBody = `Đơn hàng #${orderIdShort} của đại lý ${userName} đã hoàn thành.`;
            salesRepTitle = adminTitle;
            salesRepBody = adminBody;
            break;
        case "cancelled":
            customerTitle = "❌ Đơn hàng đã bị hủy";
            customerBody = `Rất tiếc, đơn hàng #${orderIdShort} của bạn đã bị hủy.`;
            adminTitle = "❌ Đơn hàng bị hủy";
            adminBody = `Đơn hàng #${orderIdShort} của đại lý ${userName} đã bị hủy.`;
            salesRepTitle = adminTitle;
            salesRepBody = adminBody;
            break;
        default:
            return null;
    }

    if (customerTitle && customerBody) {
        try {
            const userDoc = await db.collection("users").doc(userId).get();
            await sendDataOnlyNotification(userDoc.data()?.fcmToken, {
                title: customerTitle,
                body: customerBody,
                type: "order_status",
                orderId: event.params.orderId,
            });
        } catch (e) { logger.error(`Error sending status update to customer ${userId}:`, e); }
    }

    if (salesRepId && salesRepTitle && salesRepBody) {
        try {
            const salesRepDoc = await db.collection("users").doc(salesRepId).get();
            await sendDataOnlyNotification(salesRepDoc.data()?.fcmToken, {
                title: salesRepTitle,
                body: salesRepBody,
                type: "order_status_update_for_rep",
                orderId: event.params.orderId,
            });
        } catch (e) { logger.error(`Error sending status update to sales rep ${salesRepId}:`, e); }
    }

    if (adminTitle && adminBody) {
        try {
            const adminsSnapshot = await db.collection("users").where("role", "==", "admin").get();
            const adminTokens = adminsSnapshot.docs.map((doc: QueryDocumentSnapshot) => doc.data().fcmToken).filter((token): token is string => !!token);
            if (adminTokens.length > 0) {
                await sendDataOnlyNotification(adminTokens, {
                    title: adminTitle,
                    body: adminBody,
                    type: "order_status_update_for_admin",
                    orderId: event.params.orderId,
                });
            }
        } catch (e) { logger.error("Error sending status update to admins:", e); }
    }
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