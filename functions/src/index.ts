// functions/src/index.ts

import {onCall, HttpsError, CallableRequest} from "firebase-functions/v2/https";
import {
  onDocumentCreated,
  onDocumentUpdated,
  QueryDocumentSnapshot,
} from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import {format} from "date-fns-tz";

admin.initializeApp();
const db = admin.firestore();

const sendDataOnlyNotification = async (
  token: string | string[] | undefined,
  data: {[key: string]: string},
) => {
  if (!token || (Array.isArray(token) && token.length === 0)) {
    logger.warn("No valid token provided for notification.", {data});
    return;
  }

  const validTokens = (Array.isArray(token) ? token : [token]).filter(
      (t): t is string => !!t && typeof t === "string" && t.length > 0
  );

  if (validTokens.length === 0) {
    logger.warn("Token list is empty after filtering.", {data});
    return;
  }

  const message = {
    data: data,
    tokens: validTokens,
  };

  try {
    const response = await admin.messaging().sendEachForMulticast(message);
    logger.info(`Successfully sent ${response.successCount} messages.`, {
        failureCount: response.failureCount,
        data,
    });
    if (response.failureCount > 0) {
        response.responses.forEach((resp, idx) => {
            if (!resp.success) {
                logger.error(`Failed to send to token: ${validTokens[idx]}`, resp.error);
            }
        });
    }
  } catch (error) {
    logger.error("Error sending multicast message:", error, {data});
  }
};

// ===================================================================
// FUNCTION 1: TÍNH TOÁN CHIẾT KHẤU ĐẠI LÝ
// ===================================================================
export const calculateOrderDiscount = onCall({region: "asia-southeast1"}, async (request: CallableRequest) => {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "Authentication required.");
    }
    const callerId = request.auth.uid;
    const { items: orderItems, agentId } = request.data;

    if (!orderItems || !Array.isArray(orderItems)) {
        throw new HttpsError("invalid-argument", "Missing 'items' array.");
    }

    try {
        if (agentId && typeof agentId === "string") {
            const callerDoc = await db.collection("users").doc(callerId).get();
            const callerRole = callerDoc.data()?.role;
            if (!["admin", "sales_rep", "accountant"].includes(callerRole)) {
                throw new HttpsError("permission-denied", "You do not have permission to calculate discounts for other users.");
            }
        }

        const targetUserId = agentId || callerId;

        const userDoc = await db.collection("users").doc(targetUserId).get();
        if (!userDoc.exists) {
            throw new HttpsError("not-found", `User with ID ${targetUserId} not found.`);
        }
        const userData = userDoc.data()!;
        const userRole = userData.role;

        if (userData.activeRewardProgram === "sales_target") {
            logger.info(`User ${targetUserId} is on sales_target program. Skipping discount calculation.`);
            return {discount: 0};
        }
        // ================================================================

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

        logger.info(`Calculated discount for user ${targetUserId}: ${totalDiscount}`);
        return {discount: totalDiscount};
    } catch (error) {
        logger.error("Error in calculateOrderDiscount:", error);
        if (error instanceof HttpsError) {
          throw error;
        }
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

        // KỊCH BẢN 1: ĐƠN HÀNG CẦN PHÊ DUYỆT (Giữ nguyên)
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
            // Kết thúc hàm tại đây vì đây là luồng riêng
            return null;
        }

        // KỊCH BẢN 2: ĐƠN HÀNG THÔNG THƯỜNG (SỬA LỖI: logic gửi thông báo giờ sẽ chạy đúng)
        const userDoc = await db.collection("users").doc(userId).get();
        if (userDoc.exists && userDoc.data()?.fcmToken) {
            await sendDataOnlyNotification(userDoc.data()?.fcmToken, {
                title: "🎉 Đặt hàng thành công!",
                body: `Đơn hàng #${orderIdShort} trị giá ${formattedTotal} của bạn đã được tiếp nhận.`,
                type: "order_status",
                orderId: orderId,
            });
        }

        // Logic thông báo cho NVKD và Nhân viên khác (Giữ nguyên)
        if (salesRepId) {
            const salesRepDoc = await db.collection("users").doc(salesRepId).get();
            if (salesRepDoc.exists && salesRepDoc.data()?.fcmToken) {
                await sendDataOnlyNotification(salesRepDoc.data()?.fcmToken, {
                    title: "📈 Có đơn hàng mới!",
                    body: `Đại lý "${userName}" của bạn vừa đặt đơn hàng #${orderIdShort}.`,
                    type: "new_order_for_rep",
                    orderId: orderId,
                });
            }
        }

        const staffSnapshot = await db.collection("users").where("role", "in", ["admin", "accountant"]).get();
        const staffTokens = staffSnapshot.docs
            .map((doc) => doc.data().fcmToken)
            .filter((token): token is string => !!token);

        if (staffTokens.length > 0) {
            await sendDataOnlyNotification(staffTokens, {
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

        if (!beforeData || !afterData || beforeData.status === afterData.status) {
            return null;
        }

        const orderId = event.params.orderId;
        const { userId, total, status: newStatus, salesRepId, shippingAddress, placedBy, shippingDate } = afterData;
        const oldStatus = beforeData.status;


        if (newStatus === "completed" && oldStatus !== "completed") {
            try {
                const userDoc = await db.collection("users").doc(userId).get();
                if (userDoc.exists) {
                    const userData = userDoc.data()!;

                    if (userData.activeRewardProgram === "sales_target") {
                        const now = new Date();
                        const activeCommitmentQuery = db.collection("sales_commitments")
                            .where("userId", "==", userId)
                            .where("status", "==", "active")
                            .where("startDate", "<=", admin.firestore.Timestamp.fromDate(now))
                            .where("endDate", ">=", admin.firestore.Timestamp.fromDate(now))
                            .limit(1);

                        const commitmentSnapshot = await activeCommitmentQuery.get();

                        if (!commitmentSnapshot.empty) {
                            const commitmentDoc = commitmentSnapshot.docs[0];
                            const commitment = commitmentDoc.data();
                            const newAmount = (commitment.currentAmount || 0) + total;

                            await commitmentDoc.ref.update({ currentAmount: newAmount });
                            logger.info(`Successfully updated sales commitment ${commitmentDoc.id} for user ${userId}. New amount: ${newAmount}`);

                            if (newAmount >= commitment.targetAmount) {
                                await commitmentDoc.ref.update({ status: "completed" });
                                logger.info(`Sales commitment ${commitmentDoc.id} for user ${userId} has been completed.`);
                                if (userData.fcmToken) {
                                    await sendDataOnlyNotification(userData.fcmToken, {
                                        title: "🎉 Chúc mừng! Bạn đã đạt mục tiêu!",
                                        body: `Bạn đã hoàn thành cam kết doanh thu của mình. Liên hệ với công ty để nhận thưởng!`,
                                        type: "commitment_completed",
                                        commitmentId: commitmentDoc.id,
                                    });
                                }
                            }
                        } else {
                            logger.warn(`No active sales commitment found for user ${userId} to apply order ${orderId} total.`);
                        }
                    }
                }
            } catch (error) {
                logger.error(`Failed to update sales commitment for order ${orderId}. Error:`, error);
            }
        }

        if (newStatus === "completed" && oldStatus !== "completed") {
                try {
                    const userDoc = await db.collection("users").doc(userId).get();
                    if (userDoc.exists) {
                        const campaignQuery = db.collection("lucky_wheel_campaigns")
                            .where("isActive", "==", true)
                            .where("startDate", "<=", admin.firestore.Timestamp.now())
                            .where("endDate", ">=", admin.firestore.Timestamp.now());

                        const campaignSnapshot = await campaignQuery.get();
                        if (!campaignSnapshot.empty) {
                            let spinsToGrant = 0;
                            campaignSnapshot.forEach(doc => {
                                const campaign = doc.data();
                                const spendRule = campaign.rules.find((r: any) => r.type === "SPEND_THRESHOLD");
                                if (spendRule && spendRule.amount > 0) {
                                    spinsToGrant += Math.floor(total / spendRule.amount) * spendRule.spinsGranted;
                                }
                            });

                            if (spinsToGrant > 0) {
                                await db.collection("users").doc(userId).update({
                                    spinCount: admin.firestore.FieldValue.increment(spinsToGrant)
                                });
                                logger.info(`Granted ${spinsToGrant} spins to user ${userId} for order ${orderId}`);
                            }
                        }
                    }
                } catch (error) {
                    logger.error(`Failed to grant spins for order ${orderId}. Error:`, error);
                }
            }
        // =====================================================================

        // SỬA LỖI: Di chuyển toàn bộ logic thông báo ra ngoài để nó luôn được chạy
        const userName = shippingAddress?.recipientName ?? "Khách hàng";
        const orderIdShort = orderId.substring(0, 8).toUpperCase();
        const formattedTotal = new Intl.NumberFormat("vi-VN", {style: "currency", currency: "VND"}).format(total);

        // --- KỊCH BẢN 1: THÔNG BÁO KẾT QUẢ PHÊ DUYỆT CHO NGƯỜI ĐẶT HỘ ---
        if (oldStatus === "pending_approval" && placedBy?.userId) {
            const placerDoc = await db.collection("users").doc(placedBy.userId).get();
            const placerData = placerDoc.data();
            if (placerDoc.exists && placerData?.fcmToken) {
                let title = "";
                let body = "";

                if (newStatus === "pending") {
                    title = "✅ Đơn hàng đã được phê duyệt";
                    body = `Đại lý "${userName}" đã đồng ý đơn hàng #${orderIdShort} bạn tạo hộ.`;
                } else if (newStatus === "rejected") {
                    title = "❌ Đơn hàng đã bị từ chối";
                    body = `Đại lý "${userName}" đã từ chối đơn hàng #${orderIdShort} bạn tạo hộ.`;
                }

                if (title && body) {
                    await sendDataOnlyNotification(placerData.fcmToken, {
                        title: title,
                        body: body,
                        type: "order_approval_result",
                        orderId: orderId,
                    });
                }
            }
        }

        // --- KỊCH BẢN 2: THÔNG BÁO CÁC CẬP NHẬT TRẠNG THÁI KHÁC ---
        let notificationTitle: string | null = null;
        let notificationBody: string | null = null;

        switch (newStatus) {
            case "processing":
                notificationTitle = "✅ Đơn hàng đã được xác nhận";
                notificationBody = `Đơn hàng #${orderIdShort} của "${userName}" trị giá ${formattedTotal} đang được chuẩn bị.`;
                break;
            case "shipped":
                notificationTitle = "🚚 Đơn hàng đang được giao";
                if (shippingDate?.toDate) {
                    const formattedDate = format(shippingDate.toDate(), "dd/MM/yyyy", {timeZone: "Asia/Ho_Chi_Minh"});
                    notificationBody = `Đơn hàng #${orderIdShort} của "${userName}" đang được vận chuyển, dự kiến giao ngày ${formattedDate}.`;
                } else {
                    notificationBody = `Đơn hàng #${orderIdShort} của "${userName}" đang trên đường vận chuyển.`;
                }
                break;
            case "completed":
                notificationTitle = "✨ Đơn hàng đã hoàn thành";
                notificationBody = `Đơn hàng #${orderIdShort} của "${userName}" đã giao thành công.`;
                break;
            case "cancelled":
                notificationTitle = "❌ Đơn hàng đã bị hủy";
                notificationBody = `Đơn hàng #${orderIdShort} của "${userName}" đã bị hủy.`;
                break;
        }

        if (notificationTitle && notificationBody) {
            const commonPayload = {
                title: notificationTitle,
                body: notificationBody,
                orderId: orderId,
            };

            const userDoc = await db.collection("users").doc(userId).get();
            const salesRepDoc = salesRepId ? await db.collection("users").doc(salesRepId).get() : null;
            const staffSnapshot = await db.collection("users").where("role", "in", ["admin", "accountant"]).get();

            const allTokensToSend: Set<string> = new Set();

            if (userDoc.exists && userDoc.data()?.fcmToken) {
                allTokensToSend.add(userDoc.data()!.fcmToken);
            }
            if (salesRepDoc?.exists && salesRepDoc.data()?.fcmToken) {
                allTokensToSend.add(salesRepDoc.data()!.fcmToken);
            }
            staffSnapshot.forEach((doc) => {
                const token = doc.data().fcmToken;
                if (token) {
                    allTokensToSend.add(token);
                }
            });

            if (allTokensToSend.size > 0) {
                 await sendDataOnlyNotification(Array.from(allTokensToSend), {
                    ...commonPayload,
                    type: "order_status_general",
                });
            }
        }
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

// ===================================================================
// FUNCTION 10: TẠO MỘT CAM KẾT DOANH THU MỚI
// ===================================================================
export const createSalesCommitment = onCall({region: "asia-southeast1"}, async (request: CallableRequest) => {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "Authentication required.");
    }
    const userId = request.auth.uid;
    const { targetAmount, startDate, endDate } = request.data;

    if (!targetAmount || !startDate || !endDate) {
        throw new HttpsError("invalid-argument", "Missing required fields: targetAmount, startDate, endDate.");
    }

    try {
        const userRef = db.collection("users").doc(userId);
        const userDoc = await userRef.get();

        if (!userDoc.exists) {
            throw new HttpsError("not-found", "User not found.");
        }
        const userData = userDoc.data()!;
        if (userData.role !== "agent_1" && userData.role !== "agent_2") {
             throw new HttpsError("permission-denied", "Only agents can create a sales commitment.");
        }

        // Bắt đầu một transaction để đảm bảo cả hai thao tác cùng thành công
        await db.runTransaction(async (transaction) => {
            // 1. Tạo document cam kết mới
            const commitmentRef = db.collection("sales_commitments").doc();
            transaction.set(commitmentRef, {
                userId: userId,
                userDisplayName: userData.displayName,
                userRole: userData.role,
                targetAmount: Number(targetAmount),
                currentAmount: 0,
                startDate: admin.firestore.Timestamp.fromDate(new Date(startDate)),
                endDate: admin.firestore.Timestamp.fromDate(new Date(endDate)),
                status: "active",
                commitmentDetails: null,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });

            transaction.update(userRef, {
                activeRewardProgram: "sales_target"
            });
        });

        logger.info(`Successfully created sales commitment for user ${userId}.`);
        return { success: true, message: "Đăng ký cam kết doanh thu thành công!" };
    } catch (error) {
        logger.error("Error in createSalesCommitment:", error);
        if (error instanceof HttpsError) {
          throw error;
        }
        throw new HttpsError("internal", "Failed to create sales commitment.", error);
    }
});

// ===================================================================
// FUNCTION 11: THIẾT LẬP CHI TIẾT CAM KẾT (BỞI ADMIN/NVKD)
// ===================================================================
export const setSalesCommitmentDetails = onCall({region: "asia-southeast1"}, async (request: CallableRequest) => {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "Authentication required.");
    }
    const setterId = request.auth.uid; // ID của người thiết lập (Admin/NVKD)
    const { commitmentId, detailsText } = request.data;

    if (!commitmentId || !detailsText) {
        throw new HttpsError("invalid-argument", "Missing required fields: commitmentId, detailsText.");
    }

    try {
        const setterDoc = await db.collection("users").doc(setterId).get();
        const setterData = setterDoc.data();
        if (!setterDoc.exists || !["admin", "sales_rep", "accountant"].includes(setterData?.role)) {
            throw new HttpsError("permission-denied", "You do not have permission to perform this action.");
        }

        const commitmentRef = db.collection("sales_commitments").doc(commitmentId);
        await commitmentRef.update({
            "commitmentDetails": {
                text: detailsText,
                setByUserId: setterId,
                setByUserName: setterData?.displayName ?? "Không rõ",
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            }
        });

        // Gửi thông báo cho đại lý
        const commitmentDoc = await commitmentRef.get();
        const agentId = commitmentDoc.data()?.userId;
        if(agentId) {
             const agentDoc = await db.collection("users").doc(agentId).get();
             if (agentDoc.exists && agentDoc.data()?.fcmToken) {
                 await sendDataOnlyNotification(agentDoc.data()?.fcmToken, {
                     title: "🎁 Cam kết của bạn đã được xác nhận!",
                     body: `Công ty đã xác nhận phần thưởng cho cam kết doanh thu của bạn. Hãy xem ngay!`,
                     type: "commitment_details_set",
                     commitmentId: commitmentId,
                 });
             }
        }

        logger.info(`Admin/Rep ${setterId} set details for commitment ${commitmentId}.`);
        return { success: true, message: "Thiết lập cam kết thành công." };
    } catch (error) {
        logger.error("Error in setSalesCommitmentDetails:", error);
        if (error instanceof HttpsError) {
          throw error;
        }
        throw new HttpsError("internal", "Failed to set commitment details.", error);
    }
});

// ===================================================================
// FUNCTION 12: VÒNG QUAY MAY MẮN FUNCTIONS
// ===================================================================
/**
 * Thưởng lượt quay miễn phí cho lần đăng nhập đầu tiên trong ngày.
 * Client sẽ gọi hàm này mỗi khi khởi động app.
 */
export const grantDailyLoginSpin = onCall({region: "asia-southeast1"}, async (request: CallableRequest) => {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "Yêu cầu xác thực.");
    }
    const userId = request.auth.uid;
    const userRef = db.collection("users").doc(userId);

    const today = new Date();
    const todayStr = today.toISOString().split("T")[0]; // Lấy chuỗi YYYY-MM-DD

    try {
        const userDoc = await userRef.get();
        if (!userDoc.exists) {
            throw new HttpsError("not-found", "Không tìm thấy người dùng.");
        }
        const userData = userDoc.data()!;

        // Nếu hôm nay đã nhận lượt quay rồi thì bỏ qua
        if (userData.lastDailySpin === todayStr) {
            return { success: false, message: "Hôm nay bạn đã nhận lượt quay rồi." };
        }

        // Kiểm tra xem có chiến dịch nào có luật DAILY_LOGIN đang hoạt động không
        const campaignQuery = db.collection("lucky_wheel_campaigns")
            .where("isActive", "==", true)
            .where("startDate", "<=", admin.firestore.Timestamp.now())
            .where("endDate", ">=", admin.firestore.Timestamp.now())
            .where("rules", "array-contains", { type: "DAILY_LOGIN", spinsGranted: 1 }); // Giả sử chỉ có 1 loại rule daily

        const campaignSnapshot = await campaignQuery.get();
        if (campaignSnapshot.empty) {
            return { success: false, message: "Hiện không có chương trình tặng lượt quay hàng ngày." };
        }

        // Cộng lượt quay và cập nhật ngày nhận cuối cùng
        await userRef.update({
            spinCount: admin.firestore.FieldValue.increment(1),
            lastDailySpin: todayStr,
        });

        logger.info(`Granted daily spin for user ${userId}`);
        return { success: true, message: "Bạn nhận được 1 lượt quay miễn phí!" };
    } catch (error) {
        logger.error("Error in grantDailyLoginSpin:", error);
        throw new HttpsError("internal", "Lỗi khi nhận lượt quay hàng ngày.", error);
    }
});


/**
 * Thực hiện quay thưởng, chọn phần thưởng và ghi lại lịch sử.
 */
export const spinTheWheel = onCall({region: "asia-southeast1"}, async (request: CallableRequest) => {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "Yêu cầu xác thực.");
    }
    const userId = request.auth.uid;
    const userRef = db.collection("users").doc(userId);

    try {
        let winningReward: any;

        await db.runTransaction(async (transaction) => {
            const userDoc = await transaction.get(userRef);
            if (!userDoc.exists) {
                throw new HttpsError("not-found", "Không tìm thấy người dùng.");
            }
            const userData = userDoc.data()!;

            // 1. Kiểm tra và trừ lượt quay
            if (!userData.spinCount || userData.spinCount <= 0) {
                throw new HttpsError("failed-precondition", "Bạn đã hết lượt quay.");
            }
            transaction.update(userRef, {
                spinCount: admin.firestore.FieldValue.increment(-1),
            });

            // 2. Tìm chiến dịch đang hoạt động cho vai trò của người dùng
            const campaignQuery = db.collection("lucky_wheel_campaigns")
                .where("isActive", "==", true)
                .where("wheelConfig.appliesToRole", "array-contains", userData.role)
                .where("startDate", "<=", admin.firestore.Timestamp.now())
                .where("endDate", ">=", admin.firestore.Timestamp.now())
                .limit(1);

            const campaignSnapshot = await transaction.get(campaignQuery);
            if (campaignSnapshot.empty) {
                throw new HttpsError("not-found", "Không có chương trình vòng quay nào dành cho bạn lúc này.");
            }
            const campaignDoc = campaignSnapshot.docs[0];
            const campaign = campaignDoc.data();
            const rewards = campaign.wheelConfig.rewards;

            // 3. Thuật toán chọn phần thưởng theo tỷ lệ
            const totalProbability = rewards.reduce((sum: number, reward: any) => sum + reward.probability, 0);
            let randomPoint = Math.random() * totalProbability;

            let chosenReward = null;
            for (const reward of rewards) {
                if (randomPoint < reward.probability) {
                    chosenReward = reward;
                    break;
                }
                randomPoint -= reward.probability;
            }

            // Nếu không chọn được (do lỗi làm tròn), chọn phần thưởng cuối cùng
            if (!chosenReward) {
                chosenReward = rewards[rewards.length - 1];
            }

            winningReward = chosenReward; // Lưu lại để trả về cho client

            // 4. Ghi lại lịch sử
            const historyRef = db.collection("spin_history").doc();
            transaction.set(historyRef, {
                userId: userId,
                userDisplayName: userData.displayName,
                campaignId: campaignDoc.id,
                campaignName: campaign.name,
                rewardName: chosenReward.name,
                spunAt: admin.firestore.FieldValue.serverTimestamp(),
            });

             // 5. (Tùy chọn) Giảm số lượng phần thưởng nếu có giới hạn
            if (chosenReward.limit !== null) {
                // Cần có cơ chế riêng để xử lý việc giảm `limit` một cách an toàn
                // Hiện tại chỉ ghi log, sẽ hoàn thiện sau nếu cần
                logger.info(`User ${userId} won a limited prize: ${chosenReward.name}`);
            }
        });

        logger.info(`User ${userId} won: ${winningReward.name}`);
        return { success: true, reward: winningReward };

    } catch (error) {
        logger.error("Error in spinTheWheel:", error);
        if (error instanceof HttpsError) {
          throw error;
        }
        throw new HttpsError("internal", "Đã có lỗi xảy ra khi quay thưởng.", error);
    }
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