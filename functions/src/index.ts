import {onCall, HttpsError, CallableRequest} from "firebase-functions/v2/https";
import {
  onDocumentCreated,
  onDocumentUpdated,
  QueryDocumentSnapshot,
} from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import * as crypto from "crypto";
import * as qs from "qs";
import {format} from "date-fns-tz";

// Khởi tạo app với project ID để đảm bảo tính tường minh
admin.initializeApp({ projectId: 'piv-fertilizer-app' });
const db = admin.firestore();

// --- HÀM HELPER GỬI THÔNG BÁO (Hoàn thiện) ---
const sendDataOnlyNotification = async (
  token: string | string[] | undefined,
  data: {[key: string]: string},
) => {
  if (!token || (Array.isArray(token) && token.length === 0)) {
    logger.warn("No valid token provided for notification.", {data});
    return;
  }
  const tokens = Array.isArray(token) ? token : [token];
  const message = { data: data };

  for (const singleToken of tokens) {
    if (!singleToken || typeof singleToken !== 'string') continue;
    try {
      const response = await admin.messaging().send({ ...message, token: singleToken });
      logger.info(`Successfully sent message to token: ${singleToken}`, {response, data});
    } catch (error) {
      logger.error(`Error sending message to token: ${singleToken}`, error, {data});
    }
  }
};

// ===================================================================
// FUNCTION 1: TÍNH TOÁN CHIẾT KHẤU ĐẠI LÝ
// ===================================================================
export const calculateOrderDiscount = onCall({region: "asia-southeast1"}, async (request: CallableRequest) => {
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
// FUNCTION 2: TẠO LINK THANH TOÁN VNPAY
// ===================================================================
export const createVnpayPaymentUrl = onCall({region: "asia-southeast1", secrets: ["VNP_TMNCODE", "VNP_HASHSECRET"],}, async (request: CallableRequest) => {
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
});

// ===================================================================
// FUNCTION 3: GỬI THÔNG BÁO KHI CÓ SẢN PHẨM MỚI (ĐÃ NÂNG CẤP 🚀)
// ===================================================================
export const onProductCreated = onDocumentCreated(
    {document: "products/{productId}", region: "asia-southeast1"},
    async (event) => {
        const product = event.data?.data();
        const productId = event.params.productId;
        if (!product) return null;

        const usersSnapshot = await db.collection("users").where("status", "==", "active").where("role", "in", ["agent_1", "agent_2", "admin"]).get();
        const tokens = usersSnapshot.docs.map((doc) => doc.data().fcmToken).filter((token): token is string => !!token);

        if (tokens.length > 0) {
            const formattedPrice = new Intl.NumberFormat("vi-VN", {style: "currency", currency: "VND"}).format(product.price);
            await sendDataOnlyNotification(tokens, {
                title: "🌟 Có sản phẩm mới!",
                body: `Sản phẩm "${product.name}" giá ${formattedPrice} vừa được ra mắt. Xem ngay!`,
                type: "new_product",
                productId: productId,
                payload: JSON.stringify({
                    id: productId,
                    name: product.name,
                    price: product.price,
                    imageUrl: product.imageUrl ?? "",
                }),
            });
        }
        return null;
    });

// ===================================================================
// FUNCTION 4: XỬ LÝ KHI THÔNG TIN USER THAY ĐỔI (ĐÃ NÂNG CẤP 🚀)
// ===================================================================
export const onUserUpdate = onDocumentUpdated(
    {document: "users/{userId}", region: "asia-southeast1"},
    async (event) => {
        const before = event.data?.before.data();
        const after = event.data?.after.data();
        if (!before || !after) return null;

        const updatedUserId = event.params.userId;
        const updatedUserName = after.displayName ?? "Người dùng";

        // Kịch bản 1: Tài khoản được duyệt
        if (before.status === "pending_approval" && after.status === "active") {
            await sendDataOnlyNotification(after.fcmToken, {
                title: "✅ Tài khoản đã được duyệt!",
                body: `Chúc mừng ${updatedUserName}! Tài khoản của bạn đã được kích hoạt.`,
                type: "account_approved",
                userId: updatedUserId,
                payload: JSON.stringify({ userId: updatedUserId, status: "active" }),
            });

            const adminsSnapshot = await db.collection("users").where("role", "==", "admin").get();
            const adminTokens = adminsSnapshot.docs
                .map((doc) => doc.data().fcmToken)
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
                if(salesRepDoc.exists) {
                    await sendDataOnlyNotification(salesRepDoc.data()?.fcmToken, {
                        title: "🎉 Đại lý mới được duyệt!",
                        body: `Tài khoản của đại lý "${updatedUserName}" mà bạn quản lý đã được kích hoạt.`,
                        type: "agent_approved",
                        agentId: updatedUserId,
                    });
                }
            }
        }

        // Kịch bản 2: Giải phóng đại lý khi NVKD bị khóa hoặc đổi vai trò
        const wasSalesRep = before.role === "sales_rep";
        const isNowSuspended = after.status === "suspended";
        const roleChanged = after.role !== "sales_rep";

        if (wasSalesRep && (isNowSuspended || roleChanged)) {
             logger.info(`Sales rep ${updatedUserId} status changed. Un-assigning agents...`);
             const agentsSnapshot = await db.collection("users").where("salesRepId", "==", updatedUserId).get();
             if (!agentsSnapshot.empty) {
                const batch = db.batch();
                agentsSnapshot.forEach((doc) => {
                    batch.update(doc.ref, {salesRepId: null});
                });
                await batch.commit();
                logger.info(`Un-assigned ${agentsSnapshot.size} agents from Sales Rep ${updatedUserId}.`);
             }
        }
        return null;
    });

// ===================================================================
// FUNCTION 5: GỬI THÔNG BÁO KHI CÓ HOA HỒNG (ĐÃ SỬA LỖI 🛠️)
// ===================================================================
export const onCommissionCreated = onDocumentCreated(
    {document: "commissions/{commissionId}", region: "asia-southeast1"},
    async (event) => {
        const commission = event.data?.data();
        const commissionId = event.params.commissionId;
        if (!commission) return null;

        try {
            const { salesRepId, orderId, amount } = commission;
            const orderIdShort = orderId.substring(0, 8).toUpperCase();
            const formattedAmount = new Intl.NumberFormat("vi-VN", {style: "currency", currency: "VND"}).format(amount);

            const salesRepDoc = await db.collection("users").doc(salesRepId).get();
            const salesRepData = salesRepDoc.data(); // Lấy dữ liệu ra trước

            // **SỬA LỖI:** Chỉ tiếp tục nếu salesRepData thực sự tồn tại
            if (!salesRepData) {
                logger.warn(`Sales rep data not found for ID ${salesRepId}, commission ${commissionId}.`);
                return null;
            }

            // Gửi thông báo cho NVKD
            if (salesRepData.fcmToken) {
                await sendDataOnlyNotification(salesRepData.fcmToken, {
                    title: `💰 Bạn có hoa hồng mới ${formattedAmount}!`,
                    body: `Bạn vừa nhận được hoa hồng từ đơn hàng #${orderIdShort}.`,
                    type: "new_commission",
                    commissionId: commissionId,
                    payload: JSON.stringify({ id: commissionId, orderId, amount }),
                });
            }

            // Gửi thông báo cho Admin
            const adminsSnapshot = await db.collection("users").where("role", "==", "admin").get();
            const adminTokens = adminsSnapshot.docs
                .map((doc) => doc.data().fcmToken)
                .filter((token): token is string => !!token);

            if (adminTokens.length > 0) {
                await sendDataOnlyNotification(adminTokens, {
                    title: "📈 Hoa hồng đã được tạo",
                    body: `Hoa hồng ${formattedAmount} đã được ghi nhận cho NVKD "${salesRepData.displayName}" từ đơn #${orderIdShort}.`,
                    type: "commission_created_for_admin",
                    commissionId: commissionId,
                    payload: JSON.stringify({ id: commissionId, orderId, amount, salesRepName: salesRepData.displayName }),
                });
            }
        } catch (e) {
            logger.error(`Error sending commission notification for ${commissionId}:`, e);
        }
        return null;
    });

// ===================================================================
// FUNCTION 6: KHI TẠO ĐƠN HÀNG MỚI (ĐÃ NÂNG CẤP 🚀)
// ===================================================================
export const onOrderCreated = onDocumentCreated(
    {document: "orders/{orderId}", region: "asia-southeast1"},
    async (event) => {
        const order = event.data?.data();
        const orderId = event.params.orderId;
        if (!order) return null;

        const { userId, salesRepId, shippingAddress, total } = order;
        const userName = shippingAddress?.recipientName ?? "Quý khách";
        const orderIdShort = orderId.substring(0, 8).toUpperCase();
        const formattedTotal = new Intl.NumberFormat("vi-VN", {style: "currency", currency: "VND"}).format(total);

        // Thông báo cho khách hàng
        const userDoc = await db.collection("users").doc(userId).get();
        if (userDoc.exists) {
            await sendDataOnlyNotification(userDoc.data()?.fcmToken, {
                title: "🎉 Đặt hàng thành công!",
                body: `Đơn hàng #${orderIdShort} trị giá ${formattedTotal} của bạn đã được tiếp nhận.`,
                type: "order_status",
                orderId: orderId,
                payload: JSON.stringify({ id: orderId, status: "pending", total }),
            });
        }

        // Thông báo cho NVKD
        if (salesRepId) {
            const salesRepDoc = await db.collection("users").doc(salesRepId).get();
            if (salesRepDoc.exists) {
                await sendDataOnlyNotification(salesRepDoc.data()?.fcmToken, {
                    title: "📈 Có đơn hàng mới!",
                    body: `Đại lý "${userName}" của bạn vừa đặt đơn hàng #${orderIdShort}.`,
                    type: "new_order_for_rep",
                    orderId: orderId,
                    payload: JSON.stringify({ id: orderId, status: "pending", total, customerName: userName }),
                });
            }
        }

        // Thông báo cho Admin
        const adminsSnapshot = await db.collection("users").where("role", "==", "admin").get();
        const adminTokens = adminsSnapshot.docs
            .map((doc) => doc.data().fcmToken)
            .filter((token): token is string => !!token);

        if (adminTokens.length > 0) {
            await sendDataOnlyNotification(adminTokens, {
                title: "🔔 Có đơn hàng mới",
                body: `Đại lý "${userName}" vừa tạo đơn hàng #${orderIdShort}.`,
                type: "new_order_for_admin",
                orderId: orderId,
                payload: JSON.stringify({ id: orderId, status: "pending", total, customerName: userName }),
            });
        }

        return null;
    });

// ===================================================================
// FUNCTION 7: KHI CẬP NHẬT TRẠNG THÁI ĐƠN HÀNG (ĐÃ NÂNG CẤP 🚀)
// ===================================================================
export const onOrderStatusUpdate = onDocumentUpdated(
    {document: "orders/{orderId}", region: "asia-southeast1"},
    async (event) => {
        const beforeData = event.data?.before.data();
        const afterData = event.data?.after.data();
        if (!beforeData || !afterData || beforeData.status === afterData.status) return null;

        const { userId, salesRepId, shippingAddress, total, status } = afterData;
        const orderId = event.params.orderId;
        const userName = shippingAddress?.recipientName ?? "Khách hàng";
        const orderIdShort = orderId.substring(0, 8).toUpperCase();
        const formattedTotal = new Intl.NumberFormat("vi-VN", {style: "currency", currency: "VND"}).format(total);

        let title: string | null = null;
        let body: string | null = null;

        switch (status) {
            case "processing": title = "✅ Đơn hàng đã được xác nhận"; body = `Đơn hàng #${orderIdShort} của bạn trị giá ${formattedTotal} đang được chuẩn bị.`; break;
            case "shipped": title = "🚚 Đơn hàng đang được giao"; body = `Đơn hàng #${orderIdShort} của bạn đang trên đường vận chuyển.`; break;
            case "completed": title = "✨ Đơn hàng đã hoàn thành"; body = `Cảm ơn bạn đã mua đơn hàng #${orderIdShort}. PIV rất mong được phục vụ bạn lần sau!`; break;
            case "cancelled": title = "❌ Đơn hàng đã bị hủy"; body = `Rất tiếc, đơn hàng #${orderIdShort} của bạn đã bị hủy.`; break;
            default: return null;
        }

        const payload = JSON.stringify({ id: orderId, status, total, customerName: userName });

        // Gửi cho khách hàng
        const userDoc = await db.collection("users").doc(userId).get();
        if (userDoc.exists) await sendDataOnlyNotification(userDoc.data()?.fcmToken, { title, body, type: "order_status", orderId, payload });

        // Gửi cho NVKD và Admin
        const salesRepDoc = salesRepId ? await db.collection("users").doc(salesRepId).get() : null;
        const adminsSnapshot = await db.collection("users").where("role", "==", "admin").get();
        const adminTokens = adminsSnapshot.docs.map(doc => doc.data().fcmToken).filter((token): token is string => !!token);

        if (salesRepDoc?.exists) await sendDataOnlyNotification(salesRepDoc.data()?.fcmToken, { title, body, type: "order_status_update_for_rep", orderId, payload });
        if (adminTokens.length > 0) await sendDataOnlyNotification(adminTokens, { title, body, type: "order_status_update_for_admin", orderId, payload });

        return null;
    });

// ===================================================================
// FUNCTION 8: GỬI THÔNG BÁO KHI CÓ BÀI VIẾT MỚI (ĐÃ NÂNG CẤP 🚀)
// ===================================================================
export const onNewsArticlePublished = onDocumentCreated(
    {document: "newsArticles/{articleId}", region: "asia-southeast1"},
    async (event) => {
        const article = event.data?.data();
        const articleId = event.params.articleId;
        if (!article || article.isPublished !== true) return null;

        const usersSnapshot = await db.collection("users").where("status", "==", "active").where("role", "in", ["agent_1", "agent_2", "admin"]).get();
        const tokens = usersSnapshot.docs.map((doc) => doc.data().fcmToken).filter((token): token is string => !!token);

        if (tokens.length > 0) {
            await sendDataOnlyNotification(tokens, {
                title: `📰 Tin Tức Mới: ${article.title}`,
                body: article.metaDescription ?? "Có một bài viết mới đang chờ bạn khám phá!",
                type: "new_article",
                articleId: articleId,
                payload: JSON.stringify({
                    id: articleId,
                    title: article.title,
                    headerImageUrl: article.headerImageUrl ?? "",
                }),
            });
        }
        return null;
    }
);

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