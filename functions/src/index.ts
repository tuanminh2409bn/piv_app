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

// ===================================================================
// SECTION: HELPER FUNCTIONS
// ===================================================================
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

/**
 * [MỚI] Lưu một bản sao của thông báo vào Cloud Firestore.
 */
const saveNotificationToFirestore = async (
  recipientId: string,
  title: string,
  body: string,
  type: string,
  payload: { [key: string]: any } = {}
) => {
  if (!recipientId) {
    logger.warn("Cannot save notification without a recipientId.", {title, body});
    return;
  }
  try {
    await db.collection("notifications").add({
      userId: recipientId,
      title: title,
      body: body,
      type: type,
      payload: payload,
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    logger.info(`Notification saved for user ${recipientId}.`);
  } catch (error) {
    logger.error(`Failed to save notification for user ${recipientId}:`, error);
  }
};

// ===================================================================
// FUNCTION 1: TÍNH TOÁN CHIẾT KHẤU ĐẠI LÝ (Không thay đổi)
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

        // [SỬA ĐỔI] Thu thập cả userId và fcmToken
        const recipients = usersSnapshot.docs.map(doc => ({
            id: doc.id,
            token: doc.data().fcmToken as string
        })).filter(r => r.token);

        if (recipients.length > 0) {
            const formattedPrice = new Intl.NumberFormat("vi-VN", {style: "currency", currency: "VND"}).format(product.price);
            const title = "🌟 Có sản phẩm mới!";
            const body = `Sản phẩm "${product.name}" giá ${formattedPrice} vừa được ra mắt. Xem ngay!`;
            const type = "new_product";
            const payload = {
                id: productId,
                name: product.name,
                price: product.price,
                imageUrl: product.imageUrl ?? "",
            };

            const tokens = recipients.map(r => r.token);
            await sendDataOnlyNotification(tokens, {
                title,
                body,
                type,
                productId: productId,
                payload: JSON.stringify(payload),
            });

            // [MỚI] Lưu thông báo vào Firestore cho từng người nhận
            const savePromises = recipients.map(recipient =>
                saveNotificationToFirestore(recipient.id, title, body, type, { productId })
            );
            await Promise.all(savePromises);
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

        // Thoát sớm nếu không có dữ liệu
        if (!before || !after) {
            return null;
        }

        const updatedUserId = event.params.userId;
        const updatedUserName = after.displayName ?? "Người dùng";

        // Kịch bản 1: Tài khoản được duyệt (logic không đổi)
        if (before.status === "pending_approval" && after.status === "active") {
            const title1 = "✅ Tài khoản đã được duyệt!";
            const body1 = `Chúc mừng ${updatedUserName}! Tài khoản của bạn đã được kích hoạt.`;
            const type1 = "account_approved";
            await sendDataOnlyNotification(after.fcmToken, {
                title: title1,
                body: body1,
                type: type1,
                userId: updatedUserId,
                payload: JSON.stringify({ userId: updatedUserId, status: "active" }),
            });
            await saveNotificationToFirestore(updatedUserId, title1, body1, type1, { userId: updatedUserId });


            const adminsSnapshot = await db.collection("users").where("role", "==", "admin").get();
            const adminRecipients = adminsSnapshot.docs.map(doc => ({id: doc.id, token: doc.data().fcmToken as string})).filter(r => r.token);
            if (adminRecipients.length > 0) {
                const title2 = "👤 Tài khoản đã được duyệt";
                const body2 = `Tài khoản của "${updatedUserName}" đã được kích hoạt.`;
                const type2 = "account_management";
                await sendDataOnlyNotification(adminRecipients.map(r => r.token), {
                    title: title2,
                    body: body2,
                    type: type2,
                    userId: updatedUserId,
                });
                const savePromises = adminRecipients.map(r => saveNotificationToFirestore(r.id, title2, body2, type2, { userId: updatedUserId }));
                await Promise.all(savePromises);
            }

            if (after.salesRepId) {
                const salesRepDoc = await db.collection("users").doc(after.salesRepId).get();
                if(salesRepDoc.exists && salesRepDoc.data()?.fcmToken) {
                    const title3 = "🎉 Đại lý mới được duyệt!";
                    const body3 = `Tài khoản của đại lý "${updatedUserName}" mà bạn quản lý đã được kích hoạt.`;
                    const type3 = "agent_approved";
                    await sendDataOnlyNotification(salesRepDoc.data()?.fcmToken, {
                        title: title3,
                        body: body3,
                        type: type3,
                        agentId: updatedUserId,
                    });
                    await saveNotificationToFirestore(after.salesRepId, title3, body3, type3, { agentId: updatedUserId });
                }
            }
        }

        // --- BẮT ĐẦU LOGIC XỬ LÝ THAY ĐỔI VAI TRÒ ---
        if (before.role !== after.role) {
            const wasAgent = before.role === "agent_1" || before.role === "agent_2";
            const isNowStaff = ["admin", "sales_rep", "accountant"].includes(after.role);
            const wasStaff = ["admin", "sales_rep", "accountant"].includes(before.role);
            const isNowAgent = after.role === "agent_1" || after.role === "agent_2";

            // Kịch bản 2: NVKD bị thay đổi vai trò -> Giải phóng đại lý của họ
            if (before.role === "sales_rep") {
                 logger.info(`Sales rep ${updatedUserId} role changed from sales_rep to ${after.role}. Un-assigning agents...`);
                 const agentsSnapshot = await db.collection("users").where("salesRepId", "==", updatedUserId).get();
                 if (!agentsSnapshot.empty) {
                    const batch = db.batch();
                    agentsSnapshot.forEach((doc) => {
                        batch.update(doc.ref, {
                            salesRepId: admin.firestore.FieldValue.delete(),
                            referrerId: admin.firestore.FieldValue.delete()
                        });
                    });
                    await batch.commit();
                    logger.info(`Un-assigned ${agentsSnapshot.size} agents from former Sales Rep ${updatedUserId}.`);
                 }
            }

            // Kịch bản 3: Đại lý được nâng cấp thành nhân viên -> Xóa trường cũ
            if (wasAgent && isNowStaff) {
                logger.info(`Agent ${updatedUserId} was promoted to a staff role (${after.role}). Removing agent-specific fields.`);
                await db.collection("users").doc(updatedUserId).update({
                    salesRepId: admin.firestore.FieldValue.delete(),
                    referrerId: admin.firestore.FieldValue.delete()
                });
                logger.info(`Fields salesRepId and referrerId removed for user ${updatedUserId}.`);
            }

            // [MỚI] Kịch bản 4: Nhân viên bị chuyển về làm đại lý -> Yêu cầu nhập lại mã giới thiệu
            if (wasStaff && isNowAgent) {
                logger.info(`Staff ${updatedUserId} was changed to an agent role (${after.role}). Setting referral prompt flag.`);
                await db.collection("users").doc(updatedUserId).update({
                    referralPromptPending: true
                });
                logger.info(`referralPromptPending flag set for user ${updatedUserId}.`);
            }
        }
        // --- KẾT THÚC LOGIC XỬ LÝ THAY ĐỔI VAI TRÒ ---

        // Logic cũ khác: NVKD bị khóa (chạy độc lập với thay đổi vai trò)
        if (before.status !== "suspended" && after.status === "suspended" && before.role === "sales_rep") {
             logger.info(`Sales rep ${updatedUserId} was suspended. Un-assigning agents...`);
             const agentsSnapshot = await db.collection("users").where("salesRepId", "==", updatedUserId).get();
             if (!agentsSnapshot.empty) {
                const batch = db.batch();
                agentsSnapshot.forEach((doc) => {
                    batch.update(doc.ref, {
                        salesRepId: admin.firestore.FieldValue.delete(),
                        referrerId: admin.firestore.FieldValue.delete()
                    });
                });
                await batch.commit();
                logger.info(`Un-assigned ${agentsSnapshot.size} agents from suspended Sales Rep ${updatedUserId}.`);
             }
        }

        return null;
    });

// ===================================================================
// FUNCTION 4: GỬI THÔNG BÁO KHI CÓ HOA HỒNG
// ===================================================================
/* export const onCommissionCreated = onDocumentCreated(
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
                const title1 = `💰 Bạn có hoa hồng mới ${formattedAmount}!`;
                const body1 = `Bạn vừa nhận được hoa hồng từ đơn hàng #${orderIdShort}.`;
                const type1 = "new_commission";
                await sendDataOnlyNotification(salesRepData.fcmToken, {
                    title: title1,
                    body: body1,
                    type: type1,
                    commissionId: commissionId,
                    payload: JSON.stringify({ id: commissionId, orderId, amount }),
                });
                // [MỚI] Lưu thông báo
                await saveNotificationToFirestore(salesRepId, title1, body1, type1, { commissionId });
            }

            const adminsSnapshot = await db.collection("users").where("role", "==", "admin").get();
            const adminRecipients = adminsSnapshot.docs
                .map((doc) => ({id: doc.id, token: doc.data().fcmToken as string}))
                .filter((r) => r.token);

            if (adminRecipients.length > 0) {
                const title2 = "📈 Hoa hồng đã được tạo";
                const body2 = `Hoa hồng ${formattedAmount} đã được ghi nhận cho NVKD "${salesRepData.displayName}" từ đơn #${orderIdShort}.`;
                const type2 = "commission_created_for_admin";

                await sendDataOnlyNotification(adminRecipients.map(r => r.token), {
                    title: title2,
                    body: body2,
                    type: type2,
                    commissionId: commissionId,
                    payload: JSON.stringify({ id: commissionId, orderId, amount, salesRepName: salesRepData.displayName }),
                });
                // [MỚI] Lưu thông báo cho admin
                const savePromises = adminRecipients.map(r => saveNotificationToFirestore(r.id, title2, body2, type2, { commissionId }));
                await Promise.all(savePromises);
            }
        } catch (e) {
            logger.error(`Error sending commission notification for ${commissionId}:`, e);
        }
        return null;
    }); */

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

        // Kịch bản 1: Đơn hàng cần phê duyệt
        if (status === "pending_approval" && placedBy) {
            const agentDoc = await db.collection("users").doc(userId).get();
            const placerDoc = await db.collection("users").doc(placedBy.userId).get();
            const placerName = placerDoc.data()?.displayName ?? "Cấp trên";

            if (agentDoc.exists && agentDoc.data()?.fcmToken) {
                const title = "🔔 Bạn có đơn hàng mới cần phê duyệt";
                const body = `${placerName} vừa tạo một đơn hàng hộ cho bạn trị giá ${formattedTotal}. Vui lòng xác nhận.`;
                const type = "order_approval_request";

                await sendDataOnlyNotification(agentDoc.data()?.fcmToken, {
                    title,
                    body,
                    type,
                    orderId: orderId,
                });
                 // [MỚI] Lưu thông báo
                await saveNotificationToFirestore(userId, title, body, type, { orderId });
            }
            logger.info(`Sent approval notification for order ${orderId} to agent ${userId}.`);
            return null;
        }

        // Kịch bản 2: Đơn hàng thông thường
        const userDoc = await db.collection("users").doc(userId).get();
        if (userDoc.exists && userDoc.data()?.fcmToken) {
            const title = "🎉 Đặt hàng thành công!";
            const body = `Đơn hàng #${orderIdShort} trị giá ${formattedTotal} của bạn đã được tiếp nhận.`;
            const type = "order_status";
            await sendDataOnlyNotification(userDoc.data()?.fcmToken, {
                title, body, type, orderId,
            });
            // [MỚI] Lưu thông báo
            await saveNotificationToFirestore(userId, title, body, type, { orderId });
        }

        // Thông báo cho NVKD
        if (salesRepId) {
            const salesRepDoc = await db.collection("users").doc(salesRepId).get();
            if (salesRepDoc.exists && salesRepDoc.data()?.fcmToken) {
                const title = "📈 Có đơn hàng mới!";
                const body = `Đại lý "${userName}" của bạn vừa đặt đơn hàng #${orderIdShort}.`;
                const type = "new_order_for_rep";
                await sendDataOnlyNotification(salesRepDoc.data()?.fcmToken, {
                   title, body, type, orderId,
                });
                // [MỚI] Lưu thông báo
                await saveNotificationToFirestore(salesRepId, title, body, type, { orderId });
            }
        }

        // Thông báo cho nhân viên khác
        const staffSnapshot = await db.collection("users").where("role", "in", ["admin", "accountant"]).get();
        const staffRecipients = staffSnapshot.docs
            .map((doc) => ({id: doc.id, token: doc.data().fcmToken as string }))
            .filter((r) => r.token);

        if (staffRecipients.length > 0) {
            const title = "🔔 Có đơn hàng mới";
            const body = `Đại lý "${userName}" vừa tạo đơn hàng #${orderIdShort}.`;
            const type = "new_order_for_admin";
            await sendDataOnlyNotification(staffRecipients.map(r=>r.token), {
                title, body, type, orderId,
            });
            // [MỚI] Lưu thông báo cho nhân viên
            const savePromises = staffRecipients.map(r => saveNotificationToFirestore(r.id, title, body, type, { orderId }));
            await Promise.all(savePromises);
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
                const userRef = db.collection("users").doc(userId); // <<< SỬA: Dùng userRef để cập nhật
                const userDoc = await userRef.get();

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

                                // <<< THÊM LOGIC QUAN TRỌNG TẠI ĐÂY >>>
                                // Chuyển trạng thái chương trình thưởng của user về lại mặc định
                                await userRef.update({ activeRewardProgram: "instant_discount" });
                                logger.info(`User ${userId}'s reward program has been reset to 'instant_discount'.`);

                                if (userData.fcmToken) {
                                    const title = "🎉 Chúc mừng! Bạn đã đạt mục tiêu!";
                                    const body = `Bạn đã hoàn thành cam kết doanh thu của mình. Liên hệ với công ty để nhận thưởng!`;
                                    const type = "commitment_completed";
                                    await sendDataOnlyNotification(userData.fcmToken, {
                                        title,
                                        body,
                                        type,
                                        commitmentId: commitmentDoc.id,
                                    });
                                    await saveNotificationToFirestore(userId, title, body, type, { commitmentId: commitmentDoc.id });
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
                             if (spendRule && total >= spendRule.amount) {
                                 spinsToGrant += spendRule.spinsGranted;
                             }
                         });

                         if (spinsToGrant > 0) {
                             await db.collection("users").doc(userId).update({
                                 spinCount: admin.firestore.FieldValue.increment(spinsToGrant)
                             });
                             logger.info(`Granted ${spinsToGrant} spin(s) to user ${userId} for order ${orderId}`);
                         }
                     }
                 }
             } catch (error) {
                 logger.error(`Failed to grant spins for order ${orderId}. Error:`, error);
             }
        }


        const userName = shippingAddress?.recipientName ?? "Khách hàng";
                const orderIdShort = orderId.substring(0, 8).toUpperCase();
                const formattedTotal = new Intl.NumberFormat("vi-VN", {style: "currency", currency: "VND"}).format(total);

                if (oldStatus === "pending_approval" && placedBy?.userId) {
                    const placerDoc = await db.collection("users").doc(placedBy.userId).get();
                    const placerData = placerDoc.data();
                    if (placerDoc.exists) {
                        let title = "";
                        let body = "";
                        const type = "order_approval_result";

                        if (newStatus === "pending") {
                            title = "✅ Đơn hàng đã được phê duyệt";
                            body = `Đại lý "${userName}" đã đồng ý đơn hàng #${orderIdShort} bạn tạo hộ.`;
                        } else if (newStatus === "rejected") {
                            title = "❌ Đơn hàng đã bị từ chối";
                            body = `Đại lý "${userName}" đã từ chối đơn hàng #${orderIdShort} bạn tạo hộ.`;
                        }

                        if (title && body) {
                            // Luôn lưu lịch sử
                            await saveNotificationToFirestore(placedBy.userId, title, body, type, { orderId });

                            // Chỉ gửi thông báo nếu có token
                            if (placerData?.fcmToken) {
                                 await sendDataOnlyNotification(placerData.fcmToken, {
                                    title, body, type, orderId,
                                });
                            }
                        }
                    }
                }

                let notificationTitle: string | null = null;
                let notificationBody: string | null = null;

                switch (newStatus) {
                    case "processing":
                        notificationTitle = "✅ Đơn hàng đã được xác nhận";
                        notificationBody = `Đơn hàng #${orderIdShort} của bạn trị giá ${formattedTotal} đang được chuẩn bị.`;
                        break;
                    case "shipped":
                        notificationTitle = "🚚 Đơn hàng đang được giao";
                        if (shippingDate?.toDate) {
                            const formattedDate = format(shippingDate.toDate(), "dd/MM/yyyy", {timeZone: "Asia/Ho_Chi_Minh"});
                            notificationBody = `Đơn hàng #${orderIdShort} của bạn đang được vận chuyển, dự kiến giao ngày ${formattedDate}.`;
                        } else {
                            notificationBody = `Đơn hàng #${orderIdShort} của bạn đang trên đường vận chuyển.`;
                        }
                        break;
                    case "completed":
                        notificationTitle = "✨ Đơn hàng đã hoàn thành";
                        notificationBody = `Đơn hàng #${orderIdShort} của bạn đã giao thành công.`;
                        break;
                    case "cancelled":
                        notificationTitle = "❌ Đơn hàng đã bị hủy";
                        notificationBody = `Đơn hàng #${orderIdShort} của bạn đã bị hủy.`;
                        break;
                }

                if (notificationTitle && notificationBody) {
                    const commonPayload = {
                        title: notificationTitle,
                        body: notificationBody,
                        orderId: orderId,
                    };
                    const type = "order_status_general";

                    const recipientIds = new Set<string>();

                    if (userId) recipientIds.add(userId);

                    if (salesRepId) recipientIds.add(salesRepId);

                    const staffSnapshot = await db.collection("users").where("role", "in", ["admin", "accountant"]).get();
                    staffSnapshot.forEach((doc) => {
                        recipientIds.add(doc.id);
                    });

                    const savePromises = Array.from(recipientIds).map(id =>
                        saveNotificationToFirestore(id, commonPayload.title, commonPayload.body, type, { orderId })
                    );
                    await Promise.all(savePromises);


                    if (recipientIds.size > 0) {
                         const usersSnapshot = await db.collection("users")
                            .where(admin.firestore.FieldPath.documentId(), "in", Array.from(recipientIds))
                            .get();

                         const tokensToSend = usersSnapshot.docs
                            .map(doc => doc.data().fcmToken as string)
                            .filter(token => token);

                         if (tokensToSend.length > 0) {
                            await sendDataOnlyNotification(tokensToSend, {
                               ...commonPayload,
                               type,
                            });
                         }
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
        // [SỬA ĐỔI]
        const recipients = usersSnapshot.docs.map(doc => ({
            id: doc.id,
            token: doc.data().fcmToken as string
        })).filter(r => r.token);

        if (recipients.length > 0) {
            const title = `📰 Tin Tức Mới: ${article.title}`;
            const body = article.summary ?? "Có một bài viết mới đang chờ bạn khám phá!";
            const type = "new_article";
            const payload = {
                id: articleId,
                title: article.title,
                headerImageUrl: article.imageUrl ?? "",
            };

            await sendDataOnlyNotification(recipients.map(r => r.token), {
                title,
                body,
                type,
                articleId,
                payload: JSON.stringify(payload),
            });

            // [MỚI] Lưu thông báo
            const savePromises = recipients.map(r =>
                saveNotificationToFirestore(r.id, title, body, type, { articleId })
            );
            await Promise.all(savePromises);
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
        // [SỬA ĐỔI]
        const recipients = usersSnapshot.docs
            .map((doc) => ({id: doc.id, token: doc.data().fcmToken as string}))
            .filter((r) => r.token);

        if (recipients.length === 0) {
            logger.warn("No active tokens found for the selected target.");
            return { success: true, message: "Không tìm thấy người dùng nào phù hợp để gửi." };
        }

        const type = "manual_promo";
        await sendDataOnlyNotification(recipients.map(r => r.token), {
            title,
            body,
            type,
            payload: JSON.stringify({ sentAt: new Date().toISOString() }),
        });

        // [MỚI] Lưu thông báo
        const savePromises = recipients.map(r =>
            saveNotificationToFirestore(r.id, title, body, type, {})
        );
        await Promise.all(savePromises);


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
            recipientCount: recipients.length,
        });

        logger.info(`Successfully sent manual notification to ${recipients.length} users.`);
        return { success: true, message: `Đã gửi thông báo thành công đến ${recipients.length} người dùng.` };
    }
);

// ===================================================================
// FUNCTION 9: NVKD DUYỆT ĐẠI LÝ (Không thay đổi)
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
// FUNCTION 10: TẠO MỘT CAM KẾT DOANH THU MỚI (Không thay đổi)
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

        await db.runTransaction(async (transaction) => {
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
    const setterId = request.auth.uid;
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

        const commitmentDoc = await commitmentRef.get();
        const agentId = commitmentDoc.data()?.userId;
        if(agentId) {
             const agentDoc = await db.collection("users").doc(agentId).get();
             if (agentDoc.exists && agentDoc.data()?.fcmToken) {
                 const title = "🎁 Cam kết của bạn đã được xác nhận!";
                 const body = `Công ty đã xác nhận phần thưởng cho cam kết doanh thu của bạn. Hãy xem ngay!`;
                 const type = "commitment_details_set";
                 await sendDataOnlyNotification(agentDoc.data()?.fcmToken, {
                     title, body, type, commitmentId,
                 });
                 // [MỚI] Lưu thông báo
                 await saveNotificationToFirestore(agentId, title, body, type, { commitmentId });
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
// FUNCTION 12: VÒNG QUAY MAY MẮN (Không thay đổi)
// ===================================================================
export const grantDailyLoginSpin = onCall({region: "asia-southeast1"}, async (request: CallableRequest) => {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "Yêu cầu xác thực.");
    }
    const userId = request.auth.uid;
    const userRef = db.collection("users").doc(userId);

    const todayInVietnam = new Date();
    const todayStr = format(todayInVietnam, "yyyy-MM-dd", { timeZone: "Asia/Ho_Chi_Minh" });

    try {
        const userDoc = await userRef.get();
        if (!userDoc.exists) {
            throw new HttpsError("not-found", "Không tìm thấy người dùng.");
        }
        const userData = userDoc.data()!;

        if (userData.lastDailySpin === todayStr) {
            return { success: false, message: "Hôm nay bạn đã nhận lượt quay rồi." };
        }

        // --- THAY ĐỔI: Lọc các chiến dịch trong code thay vì dùng array-contains ---
        const campaignQuery = db.collection("lucky_wheel_campaigns")
            .where("isActive", "==", true)
            .where("startDate", "<=", admin.firestore.Timestamp.now())
            .where("endDate", ">=", admin.firestore.Timestamp.now());

        const activeCampaignsSnapshot = await campaignQuery.get();

        const dailyLoginCampaignDoc = activeCampaignsSnapshot.docs.find(doc => {
            const campaign = doc.data();
            return Array.isArray(campaign.rules) && campaign.rules.some(rule => rule.type === "DAILY_LOGIN");
        });

        if (!dailyLoginCampaignDoc) {
            return { success: false, message: "Hiện không có chương trình tặng lượt quay hàng ngày." };
        }
        // --- KẾT THÚC THAY ĐỔI ---

        await userRef.update({
            spinCount: admin.firestore.FieldValue.increment(1),
            lastDailySpin: todayStr,
        });

        logger.info(`Granted daily spin for user ${userId} for date ${todayStr}`);
        return { success: true, message: "Bạn nhận được 1 lượt quay miễn phí!" };
    } catch (error) {
        logger.error("Error in grantDailyLoginSpin:", error);
        throw new HttpsError("internal", "Lỗi khi nhận lượt quay hàng ngày.", error);
    }
});

export const spinTheWheel = onCall({region: "asia-southeast1"}, async (request: CallableRequest) => {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "Yêu cầu xác thực.");
    }
    const userId = request.auth.uid;
    const userRef = db.collection("users").doc(userId);
    logger.info(`[spinTheWheel] User ${userId} started a spin.`);

    try {
        let winningReward: any;

        await db.runTransaction(async (transaction) => {
            logger.info(`[spinTheWheel] Starting transaction for user ${userId}.`);
            const userDoc = await transaction.get(userRef);
            if (!userDoc.exists) {
                throw new HttpsError("not-found", "Không tìm thấy người dùng.");
            }
            const userData = userDoc.data()!;

            // --- ĐÂY LÀ TRUY VẤN CẦN INDEX MỚI ---
            const campaignQuery = db.collection("lucky_wheel_campaigns")
                .where("isActive", "==", true)
                .where("wheelConfig.appliesToRole", "array-contains", userData.role)
                .where("startDate", "<=", admin.firestore.Timestamp.now())
                .limit(1);
            // ------------------------------------

            const campaignSnapshot = await transaction.get(campaignQuery);

            logger.info(`[spinTheWheel] Fetched user data, current spin count: ${userData.spinCount || 0}.`);
            if (!userData.spinCount || userData.spinCount <= 0) {
                throw new HttpsError("failed-precondition", "Bạn đã hết lượt quay.");
            }

            if (campaignSnapshot.empty) {
                // Thêm một kiểm tra endDate để có thông báo rõ ràng hơn
                const expiredCampaignQuery = db.collection("lucky_wheel_campaigns")
                    .where("isActive", "==", true)
                    .where("wheelConfig.appliesToRole", "array-contains", userData.role)
                    .where("endDate", "<", admin.firestore.Timestamp.now())
                    .limit(1);
                const expiredSnapshot = await transaction.get(expiredCampaignQuery);
                if (!expiredSnapshot.empty) {
                     throw new HttpsError("not-found", "Chương trình vòng quay đã kết thúc.");
                }
                throw new HttpsError("not-found", "Không có chương trình vòng quay nào dành cho bạn lúc này.");
            }
            const campaignDoc = campaignSnapshot.docs[0];
            const campaign = campaignDoc.data();
            const rewards = campaign.wheelConfig.rewards;
            logger.info(`[spinTheWheel] Found active campaign: ${campaign.name} (${campaignDoc.id}).`);

            if (!rewards || !Array.isArray(rewards) || rewards.length === 0) {
                throw new HttpsError("internal", "Cấu hình phần thưởng của chiến dịch bị lỗi.");
            }
            const totalProbability = rewards.reduce((sum: number, reward: any) => sum + (reward.probability || 0), 0);
            if (totalProbability === 0) {
                 throw new HttpsError("internal", "Tổng tỷ lệ phần thưởng bằng 0.");
            }
            let randomPoint = Math.random() * totalProbability;

            let chosenReward = null;
            for (const reward of rewards) {
                if (randomPoint < reward.probability) {
                    chosenReward = reward;
                    break;
                }
                randomPoint -= reward.probability;
            }
            if (!chosenReward) {
                chosenReward = rewards.find((r:any) => r.type === "NO_PRIZE") || rewards[rewards.length - 1];
            }

            winningReward = chosenReward;
            logger.info(`[spinTheWheel] User ${userId} won reward: "${winningReward.name}".`);

            transaction.update(userRef, {
                spinCount: admin.firestore.FieldValue.increment(-1),
            });
            logger.info(`[spinTheWheel] Decrementing spin count for user ${userId}.`);

            const historyRef = db.collection("spin_history").doc();
            transaction.set(historyRef, {
                userId: userId,
                userDisplayName: userData.displayName,
                campaignId: campaignDoc.id,
                campaignName: campaign.name,
                rewardName: winningReward.name,
                spunAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            logger.info(`[spinTheWheel] Logged spin history for user ${userId}.`);
        });

        return { success: true, reward: winningReward };

    } catch (error) {
        logger.error(`[spinTheWheel] CRITICAL ERROR for user ${userId}:`, error);
        if (error instanceof HttpsError) {
          throw error;
        }
        throw new HttpsError("internal", "Đã có lỗi xảy ra khi quay thưởng.", error);
    }
});

// ===================================================================
// FUNCTION 13: XÓA TÀI KHOẢN NGƯỜI DÙNG (PHIÊN BẢN HOÀN CHỈNH)
// ===================================================================
export const deleteUserAccount = onCall(
  {region: "asia-southeast1"},
  async (request: CallableRequest) => {
    // 1. Kiểm tra người dùng đã được xác thực.
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "Yêu cầu xác thực để thực hiện hành động này."
      );
    }

    const uid = request.auth.uid;
    const db = admin.firestore();
    const auth = admin.auth();

    logger.log(`Bắt đầu yêu cầu xóa tài khoản cho người dùng: ${uid}`);

    // 2. Lấy thông tin vai trò của người dùng trước khi xóa.
    const userDocRef = db.collection("users").doc(uid);
    const userDoc = await userDocRef.get();

    if (!userDoc.exists) {
      logger.warn(`Người dùng ${uid} yêu cầu xóa nhưng không tìm thấy document trong Firestore. Chỉ xóa trong Auth.`);
      await auth.deleteUser(uid);
      return { success: true, message: "Tài khoản không có dữ liệu, đã xóa thành công." };
    }

    const userData = userDoc.data()!;
    const userRole = userData.role;

    // 3. **KIỂM TRA QUYỀN:** Chỉ cho phép 'agent_1' và 'agent_2' tự xóa.
    if (userRole !== "agent_1" && userRole !== "agent_2") {
      logger.error(`Từ chối yêu cầu xóa: Người dùng ${uid} có vai trò là '${userRole}', không được phép tự xóa.`);
      throw new HttpsError(
        "permission-denied",
        "Tài khoản của bạn không thể tự xóa từ ứng dụng."
      );
    }

    // 4. Bắt đầu quá trình xóa dữ liệu.
    try {
      const batch = db.batch();

      // Xóa document chính của người dùng
      batch.delete(userDocRef);

      // Xóa giỏ hàng
      const cartDocRef = db.collection("carts").doc(uid);
      batch.delete(cartDocRef);

      // Xóa các đơn hàng
      const ordersQuery = db.collection("orders").where("userId", "==", uid);
      const ordersSnapshot = await ordersQuery.get();
      ordersSnapshot.forEach((doc) => batch.delete(doc.ref));
      logger.log(`Đã thêm ${ordersSnapshot.size} đơn hàng vào batch xóa.`);

      // Xóa các thông báo
      const notificationsQuery = db.collection("notifications").where("userId", "==", uid);
      const notificationsSnapshot = await notificationsQuery.get();
      notificationsSnapshot.forEach((doc) => batch.delete(doc.ref));
      logger.log(`Đã thêm ${notificationsSnapshot.size} thông báo vào batch xóa.`);

      // Xóa lịch sử vòng quay
      const spinHistoryQuery = db.collection("spin_history").where("userId", "==", uid);
      const spinHistorySnapshot = await spinHistoryQuery.get();
      spinHistorySnapshot.forEach((doc) => batch.delete(doc.ref));
      logger.log(`Đã thêm ${spinHistorySnapshot.size} lịch sử vòng quay vào batch xóa.`);

      // Xóa cam kết doanh thu
      const commitmentsQuery = db.collection("sales_commitments").where("userId", "==", uid);
      const commitmentsSnapshot = await commitmentsQuery.get();
      commitmentsSnapshot.forEach((doc) => batch.delete(doc.ref));
      logger.log(`Đã thêm ${commitmentsSnapshot.size} cam kết doanh thu vào batch xóa.`);

      // Thực thi xóa dữ liệu Firestore
      await batch.commit();
      logger.log(`Đã xóa thành công dữ liệu Firestore cho người dùng: ${uid}`);

      // 5. Xóa tài khoản khỏi Firebase Authentication
      await auth.deleteUser(uid);
      logger.log(`Đã xóa thành công tài khoản Auth cho người dùng: ${uid}`);

      return {success: true, message: "Tài khoản đã được xóa thành công."};
    } catch (error) {
      logger.error(`[CRITICAL] Lỗi khi xóa tài khoản ${uid}:`, error);
      throw new HttpsError(
        "internal",
        "Đã có lỗi xảy ra trong quá trình xóa tài khoản.",
        error
      );
    }
  }
);

// ===================================================================
// SECTION: PRIVATE HELPER FUNCTIONS (Không thay đổi)
// ===================================================================

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