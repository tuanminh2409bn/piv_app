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

admin.initializeApp({ projectId: 'piv-fertilizer-app' });
const db = admin.firestore();

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
// FUNCTION 2: GỬI THÔNG BÁO KHI CÓ SẢN PHẨM MỚI
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
// FUNCTION 3: XỬ LÝ KHI THÔNG TIN USER THAY ĐỔI
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
        if (before.role === "sales_rep" && (after.status === "suspended" || after.role !== "sales_rep")) {
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

        // Kịch bản 3: Tự động gỡ đại lý khi được nâng cấp lên NVKD
        const wasAgent = before.role === 'agent_1' || before.role === 'agent_2';
        const isNowSalesRep = after.role === 'sales_rep';

        if (wasAgent && isNowSalesRep && after.salesRepId) {
            logger.info(`Agent ${updatedUserId} was promoted to Sales Rep. Un-assigning from old Sales Rep.`);
            await db.collection("users").doc(updatedUserId).update({
                salesRepId: null
            });
        }
        return null;
    });

// ===================================================================
// FUNCTION 4: GỬI THÔNG BÁO KHI CÓ HOA HỒNG
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
            const salesRepData = salesRepDoc.data();

            if (!salesRepData) {
                logger.warn(`Sales rep data not found for ID ${salesRepId}, commission ${commissionId}.`);
                return null;
            }

            if (salesRepData.fcmToken) {
                await sendDataOnlyNotification(salesRepData.fcmToken, {
                    title: `💰 Bạn có hoa hồng mới ${formattedAmount}!`,
                    body: `Bạn vừa nhận được hoa hồng từ đơn hàng #${orderIdShort}.`,
                    type: "new_commission",
                    commissionId: commissionId,
                    payload: JSON.stringify({ id: commissionId, orderId, amount }),
                });
            }

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
// FUNCTION 5: KHI TẠO ĐƠN HÀNG MỚI
// ===================================================================
export const onOrderCreated = onDocumentCreated(
    {document: "orders/{orderId}", region: "asia-southeast1"},
    async (event) => {
        const orderData = event.data?.data();
        const orderId = event.params.orderId;
        if (!orderData) return null;

        const { userId, salesRepId, shippingAddress, total, placedBy, status } = orderData;
        const userName = shippingAddress?.recipientName ?? "Quý khách";
        const orderIdShort = orderId.substring(0, 8).toUpperCase();
        const formattedTotal = new Intl.NumberFormat("vi-VN", {style: "currency", currency: "VND"}).format(total);

        if (status === "pending_approval" && placedBy) {
            const agentDoc = await db.collection("users").doc(userId).get();
            const placerDoc = await db.collection("users").doc(placedBy.userId).get();
            const placerName = placerDoc.data()?.displayName ?? "Cấp trên";

            if (agentDoc.exists && agentDoc.data()?.fcmToken) {
                await sendDataOnlyNotification(agentDoc.data()?.fcmToken, {
                    title: "🔔 Bạn có đơn hàng mới cần phê duyệt",
                    body: `${placerName} vừa tạo một đơn hàng hộ cho bạn trị giá ${formattedTotal}. Vui lòng xác nhận.`,
                    type: "order_approval_request",
                    orderId: orderId,
                });
            }
            logger.info(`Sent approval notification for order ${orderId} to agent ${userId}.`);
            return null;
        }

        const userDoc = await db.collection("users").doc(userId).get();
        if (userDoc.exists) {
            await sendDataOnlyNotification(userDoc.data()?.fcmToken, {
                title: "🎉 Đặt hàng thành công!",
                body: `Đơn hàng #${orderIdShort} trị giá ${formattedTotal} của bạn đã được tiếp nhận.`,
                type: "order_status",
                orderId: orderId,
            });
        }

        if (salesRepId) {
            const salesRepDoc = await db.collection("users").doc(salesRepId).get();
            if (salesRepDoc.exists) {
                await sendDataOnlyNotification(salesRepDoc.data()?.fcmToken, {
                    title: "📈 Có đơn hàng mới!",
                    body: `Đại lý "${userName}" của bạn vừa đặt đơn hàng #${orderIdShort}.`,
                    type: "new_order_for_rep",
                    orderId: orderId,
                });
            }
        }

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
            });
        }

        return null;
    });


// ===================================================================
// FUNCTION 6: KHI CẬP NHẬT TRẠNG THÁI ĐƠN HÀNG
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

        const userDoc = await db.collection("users").doc(userId).get();
        if (userDoc.exists) await sendDataOnlyNotification(userDoc.data()?.fcmToken, { title, body, type: "order_status", orderId, payload });

        const salesRepDoc = salesRepId ? await db.collection("users").doc(salesRepId).get() : null;
        const adminsSnapshot = await db.collection("users").where("role", "==", "admin").get();
        const adminTokens = adminsSnapshot.docs.map(doc => doc.data().fcmToken).filter((token): token is string => !!token);

        if (salesRepDoc?.exists) await sendDataOnlyNotification(salesRepDoc.data()?.fcmToken, { title, body, type: "order_status_update_for_rep", orderId, payload });
        if (adminTokens.length > 0) await sendDataOnlyNotification(adminTokens, { title, body, type: "order_status_update_for_admin", orderId, payload });

        return null;
    });

// ===================================================================
// FUNCTION 7: GỬI THÔNG BÁO KHI CÓ BÀI VIẾT MỚI
// ===================================================================
export const onNewsArticleCreated = onDocumentCreated(
    {document: "newsArticles/{articleId}", region: "asia-southeast1"},
    async (event) => {
        const article = event.data?.data();
        const articleId = event.params.articleId;
        if (!article) return null;

        const usersSnapshot = await db.collection("users").where("status", "==", "active").where("role", "in", ["agent_1", "agent_2", "admin"]).get();
        const tokens = usersSnapshot.docs.map((doc) => doc.data().fcmToken).filter((token): token is string => !!token);

        if (tokens.length > 0) {
            await sendDataOnlyNotification(tokens, {
                title: `📰 Tin Tức Mới: ${article.title}`,
                body: article.summary ?? "Có một bài viết mới đang chờ bạn khám phá!",
                type: "new_article",
                articleId: articleId,
                payload: JSON.stringify({
                    id: articleId,
                    title: article.title,
                    headerImageUrl: article.imageUrl ?? "",
                }),
            });
        }
        return null;
    }
);

// ===================================================================
// FUNCTION 8: GỬI THÔNG BÁO THỦ CÔNG
// ===================================================================
export const sendManualNotification = onCall(
    {region: "asia-southeast1"},
    async (request: CallableRequest) => {
        if (!request.auth) throw new HttpsError("unauthenticated", "Yêu cầu xác thực.");

        const adminId = request.auth.uid;
        const adminDoc = await db.collection("users").doc(adminId).get();
        if (adminDoc.data()?.role !== 'admin') {
            throw new HttpsError("permission-denied", "Bạn không có quyền thực hiện hành động này.");
        }

        const { title, body, salesRepId } = request.data;
        if (!title || !body) {
            throw new HttpsError("invalid-argument", "Vui lòng nhập đầy đủ tiêu đề và nội dung.");
        }

        let userQuery = db.collection("users")
            .where("status", "==", "active")
            .where("role", "in", ["agent_1", "agent_2", "sales_rep"]);

        if (salesRepId && typeof salesRepId === 'string') {
            logger.info(`Targeting agents of Sales Rep: ${salesRepId}`);
            userQuery = userQuery.where("salesRepId", "==", salesRepId);
        } else {
            logger.info(`Targeting all agents and sales reps.`);
        }

        const usersSnapshot = await userQuery.get();
        const tokens = usersSnapshot.docs
            .map((doc) => doc.data().fcmToken)
            .filter((token): token is string => !!token);

        if (tokens.length === 0) {
            logger.warn("No active tokens found for the selected target.");
            return { success: true, message: "Không tìm thấy người dùng nào phù hợp để gửi." };
        }

        await sendDataOnlyNotification(tokens, {
            title: title,
            body: body,
            type: "manual_promo",
            payload: JSON.stringify({ sentAt: new Date().toISOString() }),
        });

        const targetDescription = salesRepId ? `Đại lý của NVKD (${salesRepId})` : "Tất cả Đại lý & NVKD";

        await db.collection("manualNotifications").add({
            title,
            body,
            sentAt: new Date(),
            sentBy: adminId,
            target: {
                type: salesRepId ? 'sales_rep_group' : 'all',
                id: salesRepId ?? null,
                description: targetDescription
            },
            recipientCount: tokens.length,
        });

        logger.info(`Successfully sent manual notification to ${tokens.length} users.`);
        return { success: true, message: `Đã gửi thông báo thành công đến ${tokens.length} người dùng.` };
    }
);

// ===================================================================
// FUNCTION 9: NVKD DUYỆT ĐẠI LÝ
// ===================================================================
export const approveAgentBySalesRep = onCall(
    {region: "asia-southeast1"},
    async (request: CallableRequest) => {
        if (!request.auth) {
            throw new HttpsError("unauthenticated", "Yêu cầu xác thực.");
        }
        const salesRepId = request.auth.uid;
        const salesRepDoc = await db.collection("users").doc(salesRepId).get();
        if (salesRepDoc.data()?.role !== 'sales_rep') {
            throw new HttpsError("permission-denied", "Chỉ Nhân viên kinh doanh mới có quyền thực hiện.");
        }

        const { agentId, roleToSet } = request.data;
        if (!agentId || !roleToSet) {
            throw new HttpsError("invalid-argument", "Thiếu ID của đại lý hoặc vai trò cần gán.");
        }
        if (roleToSet !== 'agent_1' && roleToSet !== 'agent_2') {
             throw new HttpsError("invalid-argument", "Vai trò không hợp lệ.");
        }

        const agentRef = db.collection("users").doc(agentId);
        const agentDoc = await agentRef.get();
        if (!agentDoc.exists || agentDoc.data()?.status !== 'pending_approval') {
             throw new HttpsError("not-found", "Không tìm thấy đại lý đang chờ duyệt hợp lệ.");
        }

        await agentRef.update({
            status: 'active',
            role: roleToSet,
            salesRepId: salesRepId
        });

        logger.info(`Sales Rep ${salesRepId} approved agent ${agentId} with role ${roleToSet}.`);
        return { success: true, message: "Duyệt đại lý thành công!" };
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