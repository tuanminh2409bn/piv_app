// functions/src/index.ts

import { onCall, HttpsError, CallableRequest } from "firebase-functions/v2/https";
import { onDocumentCreated, onDocumentUpdated, onDocumentDeleted, FirestoreEvent } from "firebase-functions/v2/firestore";
import { Change } from "firebase-functions";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import { QueryDocumentSnapshot } from "firebase-admin/firestore";
import { format } from "date-fns-tz";

admin.initializeApp();
const db = admin.firestore();
const VoucherStatus = {
  pendingApproval: 'pending_approval',
  active: 'active',
  rejected: 'rejected',
  pendingDeletion: 'pending_deletion',
  inactive: 'inactive',
};

// ===================================================================
// HÀM HỖ TRỢ (ĐÃ TỐI ƯU HÓA)
// ===================================================================

/**
 * Gửi thông báo đẩy đúng chuẩn, bao gồm cả phần `notification` để hiển thị
 * và `data` để xử lý logic trong app.
 * @param {string[]} tokens - Danh sách FCM token của người nhận.
 * @param {string} title - Tiêu đề của thông báo.
 * @param {string} body - Nội dung của thông báo.
 * @param {Record<string, string>} data - Dữ liệu payload cho ứng dụng (mọi giá trị phải là string).
 */
const sendPushNotification = async (
  tokens: (string | undefined)[],
  title: string,
  body: string,
  data: {[key: string]: string},
) => {
  const validTokens = tokens.filter((t): t is string => typeof t === "string" && t.length > 0);
  if (validTokens.length === 0) {
    logger.warn("Không có token hợp lệ để gửi thông báo.", {data});
    return;
  }

  const message: admin.messaging.MulticastMessage = {
    tokens: validTokens,
    notification: {
      title,
      body,
    },
    data,
    android: {
      priority: "high",
      notification: {
        channelId: "high_importance_channel",
        sound: "default",
      },
    },
    apns: {
      payload: {
        aps: {
          sound: "default",
          badge: 1,
        },
      },
    },
  };

  try {
    const response = await admin.messaging().sendEachForMulticast(message);
    logger.info(`Đã gửi ${response.successCount} thông báo thành công.`, {
      failureCount: response.failureCount,
    });
    if (response.failureCount > 0) {
        response.responses.forEach((resp, idx) => {
            if (!resp.success) {
                logger.error(`Lỗi gửi đến token: ${validTokens[idx]}`, resp.error);
            }
        });
    }
  } catch (error) {
    logger.error("Lỗi nghiêm trọng khi gửi thông báo:", error, {data});
  }
};


/**
 * Lưu thông báo vào sub-collection "notifications" của người dùng.
 */
const saveNotificationToFirestore = async (
  recipientId: string,
  title: string,
  body: string,
  type: string,
  payload: { [key: string]: any } = {}
) => {
  if (!recipientId) {
    logger.warn("Không thể lưu thông báo nếu thiếu recipientId.");
    return;
  }
  try {
    await db.collection("users").doc(recipientId).collection("notifications").add({
      title: title,
      body: body,
      type: type,
      payload: payload,
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    logger.info(`Đã lưu thông báo vào Firestore cho user ${recipientId}.`);
  } catch (error) {
    logger.error(`Lỗi khi lưu thông báo cho user ${recipientId}:`, error);
  }
};

/**
 * Lấy danh sách người nhận (gồm token và ID) cho một nhóm vai trò.
 */
const getRecipientsByRoles = async (roles: string[]): Promise<{ id: string; token?: string }[]> => {
    const snapshot = await db.collection("users")
      .where("status", "==", "active")
      .where("role", "in", roles)
      .get();

    if (snapshot.empty) {
        return [];
    }
    return snapshot.docs.map((doc) => ({
        id: doc.id,
        token: doc.data().fcmToken as string | undefined,
    }));
};

// ===================================================================
// FUNCTION 1: TÍNH TOÁN CHIẾT KHẤU ĐẠI LÝ
// ===================================================================
export const calculateOrderDiscount = onCall({region: "asia-southeast1"}, async (request: CallableRequest) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Authentication required.");
    const callerId = request.auth.uid;
    const { items: orderItems, agentId } = request.data;

    if (!orderItems || !Array.isArray(orderItems)) {
        throw new HttpsError("invalid-argument", "Missing 'items' array.");
    }

    try {
        if (agentId && typeof agentId === "string") {
            const callerDoc = await db.collection("users").doc(callerId).get();
            const callerRole = callerDoc.data()?.role;
            if (!callerRole || !["admin", "sales_rep", "accountant"].includes(callerRole)) {
                throw new HttpsError("permission-denied", "You do not have permission to calculate discounts for other users.");
            }
        }
        const targetUserId = agentId || callerId;
        const userDoc = await db.collection("users").doc(targetUserId).get();
        if (!userDoc.exists) {
            throw new HttpsError("not-found", `User with ID ${targetUserId} not found.`);
        }
        const userData = userDoc.data()!;
        if (userData.activeRewardProgram === "sales_target") return {discount: 0};

        const productIds: string[] = orderItems.map((item: { productId: string }) => item.productId);
        if (productIds.length === 0) return {discount: 0};
        const productsSnapshot = await db.collection("products").where(admin.firestore.FieldPath.documentId(), "in", productIds).get();
        const productsMap = new Map<string, any>();
        productsSnapshot.forEach((doc) => productsMap.set(doc.id, doc.data()));
        let foliarTotalValue = 0;
        let rootTotalValue = 0;
        for (const item of orderItems) {
            const productInfo = productsMap.get(item.productId);
            if (productInfo) {
                const itemValue = item.subtotal;
                if (productInfo.productType === "foliar_fertilizer") foliarTotalValue += itemValue;
                else if (productInfo.productType === "root_fertilizer") rootTotalValue += itemValue;
            }
        }
        let totalDiscount = 0;
        const userRole = userData.role;
        if ((userRole === "agent_1" || userRole === "agent_2") && (foliarTotalValue > 0 || rootTotalValue > 0)) {
            totalDiscount += calculateDiscountForFoliar(foliarTotalValue, userRole);
            totalDiscount += calculateDiscountForRoot(rootTotalValue, userRole);
        }
        return {discount: totalDiscount};
    } catch (error) {
        logger.error("Error in calculateOrderDiscount:", error);
        if (error instanceof HttpsError) throw error;
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
        if (!product) return;

        const recipients = await getRecipientsByRoles(["agent_1", "agent_2", "admin"]);
        if (recipients.length === 0) return;

        const formattedPrice = new Intl.NumberFormat("vi-VN", {style: "currency", currency: "VND"}).format(product.price);
        const title = "🌟 Có sản phẩm mới!";
        const body = `Sản phẩm "${product.name}" giá ${formattedPrice} vừa được ra mắt. Xem ngay!`;
        const type = "new_product";
        const dataPayload = {
            type,
            productId,
            payload: JSON.stringify({id: productId, name: product.name}),
        };

        const tokens = recipients.map((r) => r.token);
        await sendPushNotification(tokens, title, body, dataPayload);

        const savePromises = recipients.map((r) => saveNotificationToFirestore(r.id, title, body, type, {productId}));
        await Promise.all(savePromises);
    });

// ===================================================================
// FUNCTION 3: XỬ LÝ KHI THÔNG TIN USER THAY ĐỔI
// ===================================================================
export const onUserUpdate = onDocumentUpdated(
    {document: "users/{userId}", region: "asia-southeast1"},
    async (event) => {
        const before = event.data?.before.data();
        const after = event.data?.after.data();
        if (!before || !after) return;

        const updatedUserId = event.params.userId;
        const updatedUserName = after.displayName ?? "Người dùng";

        if (before.status === "pending_approval" && after.status === "active") {
            const title1 = "✅ Tài khoản đã được duyệt!";
            const body1 = `Chúc mừng ${updatedUserName}! Tài khoản của bạn đã được kích hoạt.`;
            const type1 = "account_approved";
            if (after.fcmToken) {
                await sendPushNotification([after.fcmToken], title1, body1, {type: type1, userId: updatedUserId});
            }
            await saveNotificationToFirestore(updatedUserId, title1, body1, type1, {userId: updatedUserId});

            const admins = await getRecipientsByRoles(["admin"]);
            if (admins.length > 0) {
                const title2 = "👤 Tài khoản đã được duyệt";
                const body2 = `Tài khoản của "${updatedUserName}" đã được kích hoạt.`;
                const type2 = "account_management";
                const adminTokens = admins.map((r) => r.token);
                await sendPushNotification(adminTokens, title2, body2, {type: type2, userId: updatedUserId});
                const savePromises = admins.map((r) => saveNotificationToFirestore(r.id, title2, body2, type2, {userId: updatedUserId}));
                await Promise.all(savePromises);
            }

            if (after.salesRepId) {
                const salesRepDoc = await db.collection("users").doc(after.salesRepId).get();
                if (salesRepDoc.exists) {
                    const salesRepData = salesRepDoc.data()!;
                    const title3 = "🎉 Đại lý mới được duyệt!";
                    const body3 = `Tài khoản của đại lý "${updatedUserName}" mà bạn quản lý đã được kích hoạt.`;
                    const type3 = "agent_approved";
                    if (salesRepData.fcmToken) {
                        await sendPushNotification([salesRepData.fcmToken], title3, body3, {type: type3, agentId: updatedUserId});
                    }
                    await saveNotificationToFirestore(after.salesRepId, title3, body3, type3, {agentId: updatedUserId});
                }
            }
        }

        if (before.role !== after.role) {
            const wasAgent = before.role === "agent_1" || before.role === "agent_2";
            const isNowStaff = ["admin", "sales_rep", "accountant"].includes(after.role);
            const wasStaff = ["admin", "sales_rep", "accountant"].includes(before.role);
            const isNowAgent = after.role === "agent_1" || after.role === "agent_2";

            if (before.role === "sales_rep") {
                 const agentsSnapshot = await db.collection("users").where("salesRepId", "==", updatedUserId).get();
                 if (!agentsSnapshot.empty) {
                    const batch = db.batch();
                    agentsSnapshot.forEach((doc) => {
                        batch.update(doc.ref, {
                            salesRepId: admin.firestore.FieldValue.delete(),
                            referrerId: admin.firestore.FieldValue.delete(),
                        });
                    });
                    await batch.commit();
                 }
            }
            if (wasAgent && isNowStaff) {
                await db.collection("users").doc(updatedUserId).update({
                    salesRepId: admin.firestore.FieldValue.delete(),
                    referrerId: admin.firestore.FieldValue.delete(),
                });
            }
            if (wasStaff && isNowAgent) {
                await db.collection("users").doc(updatedUserId).update({
                    referralPromptPending: true,
                });
            }
        }

        if (before.status !== "suspended" && after.status === "suspended" && before.role === "sales_rep") {
             const agentsSnapshot = await db.collection("users").where("salesRepId", "==", updatedUserId).get();
             if (!agentsSnapshot.empty) {
                const batch = db.batch();
                agentsSnapshot.forEach((doc) => {
                    batch.update(doc.ref, {
                        salesRepId: admin.firestore.FieldValue.delete(),
                        referrerId: admin.firestore.FieldValue.delete(),
                    });
                });
                await batch.commit();
             }
        }
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
        if (!orderData) return;

        const {userId, salesRepId, shippingAddress, total, placedBy, status} = orderData;
        const userName = shippingAddress?.recipientName ?? "Quý khách";
        const orderIdShort = orderId.substring(0, 8).toUpperCase();
        const formattedTotal = new Intl.NumberFormat("vi-VN", {style: "currency", currency: "VND"}).format(total);

        if (status === "pending_approval" && placedBy) {
            const agentDoc = await db.collection("users").doc(userId).get();
            if (agentDoc.exists) {
                const placerName = (await db.collection("users").doc(placedBy.userId).get()).data()?.displayName ?? "Cấp trên";
                const title = "🔔 Bạn có đơn hàng mới cần phê duyệt";
                const body = `${placerName} vừa tạo một đơn hàng hộ cho bạn trị giá ${formattedTotal}. Vui lòng xác nhận.`;
                const type = "order_approval_request";
                const token = agentDoc.data()?.fcmToken;
                if (token) {
                    await sendPushNotification([token], title, body, {type, orderId});
                }
                await saveNotificationToFirestore(userId, title, body, type, {orderId});
            }
            return;
        }

        const recipients = new Map<string, { id: string; token?: string }>();
        const userDoc = await db.collection("users").doc(userId).get();
        if (userDoc.exists) recipients.set(userId, {id: userId, token: userDoc.data()?.fcmToken});
        if (salesRepId) {
            const salesRepDoc = await db.collection("users").doc(salesRepId).get();
            if (salesRepDoc.exists) recipients.set(salesRepId, {id: salesRepId, token: salesRepDoc.data()?.fcmToken});
        }
        const staff = await getRecipientsByRoles(["admin", "accountant"]);
        staff.forEach((s) => recipients.set(s.id, s));

        for (const recipient of recipients.values()) {
            let title = "";
            let body = "";
            let type = "";
            const role = (await db.collection("users").doc(recipient.id).get()).data()?.role;

            if (recipient.id === userId) {
                title = "🎉 Đặt hàng thành công!";
                body = `Đơn hàng #${orderIdShort} của bạn đã được tiếp nhận.`;
                type = "order_status";
            } else if (recipient.id === salesRepId) {
                title = "📈 Có đơn hàng mới!";
                body = `Đại lý "${userName}" của bạn vừa đặt đơn hàng #${orderIdShort}.`;
                type = "new_order_for_rep";
            } else if (role === "admin" || role === "accountant") {
                title = "🔔 Có đơn hàng mới";
                body = `Đại lý "${userName}" vừa tạo đơn hàng #${orderIdShort}.`;
                type = "new_order_for_admin";
            }
            if (title && body && type) {
                if (recipient.token) {
                    await sendPushNotification([recipient.token], title, body, {type, orderId});
                }
                await saveNotificationToFirestore(recipient.id, title, body, type, {orderId});
            }
        }
    });

// ===================================================================
// FUNCTION 6: KHI CẬP NHẬT TRẠNG THÁI ĐƠN HÀNG
// ===================================================================
export const onOrderStatusUpdate = onDocumentUpdated(
    {document: "orders/{orderId}", region: "asia-southeast1"},
    async (event) => {
        const beforeData = event.data?.before.data();
        const afterData = event.data?.after.data();
        if (!beforeData || !afterData || beforeData.status === afterData.status) return;

        const orderId = event.params.orderId;
        const {userId, total, status: newStatus, salesRepId, shippingAddress, placedBy, shippingDate} = afterData;
        const oldStatus = beforeData.status;

        if (newStatus === "completed" && oldStatus !== "completed") {
            try {
                const userRef = db.collection("users").doc(userId);
                const userDoc = await userRef.get();
                if (userDoc.exists) {
                    const userData = userDoc.data()!;
                    if (userData.activeRewardProgram === "sales_target") {
                        const now = new Date();
                        const activeCommitmentQuery = db.collection("sales_commitments")
                            .where("userId", "==", userId).where("status", "==", "active")
                            .where("startDate", "<=", admin.firestore.Timestamp.fromDate(now))
                            .where("endDate", ">=", admin.firestore.Timestamp.fromDate(now)).limit(1);
                        const commitmentSnapshot = await activeCommitmentQuery.get();
                        if (!commitmentSnapshot.empty) {
                            const commitmentDoc = commitmentSnapshot.docs[0];
                            const commitment = commitmentDoc.data();
                            const newAmount = (commitment.currentAmount || 0) + total;
                            await commitmentDoc.ref.update({currentAmount: newAmount});
                            if (newAmount >= commitment.targetAmount) {
                                await commitmentDoc.ref.update({status: "completed"});
                                await userRef.update({activeRewardProgram: "instant_discount"});
                                if (userData.fcmToken) {
                                    const title = "🎉 Chúc mừng! Bạn đã đạt mục tiêu!";
                                    const body = "Bạn đã hoàn thành cam kết doanh thu của mình. Liên hệ với công ty để nhận thưởng!";
                                    const type = "commitment_completed";

                                    // --- SỬA LỖI 1: Thay thế hàm cũ ---
                                    await sendPushNotification(
                                        [userData.fcmToken],
                                        title,
                                        body,
                                        { type, commitmentId: commitmentDoc.id }
                                    );
                                    await saveNotificationToFirestore(userId, title, body, type, {commitmentId: commitmentDoc.id});
                                }
                            }
                        }
                    }
                }
            } catch (error) {
                logger.error(`Failed to update sales commitment for order ${orderId}.`, error);
            }
            try {
                const userDoc = await db.collection("users").doc(userId).get();
                if (userDoc.exists) {
                    const campaignQuery = db.collection("lucky_wheel_campaigns").where("isActive", "==", true)
                        .where("startDate", "<=", admin.firestore.Timestamp.now())
                        .where("endDate", ">=", admin.firestore.Timestamp.now());
                    const campaignSnapshot = await campaignQuery.get();
                    if (!campaignSnapshot.empty) {
                        let spinsToGrant = 0;
                        campaignSnapshot.forEach((doc) => {
                            const campaign = doc.data();
                            const spendRule = campaign.rules.find((r: any) => r.type === "SPEND_THRESHOLD");
                            if (spendRule && total >= spendRule.amount) {
                                spinsToGrant += spendRule.spinsGranted;
                            }
                        });
                        if (spinsToGrant > 0) {
                            await db.collection("users").doc(userId).update({
                                spinCount: admin.firestore.FieldValue.increment(spinsToGrant),
                            });
                        }
                    }
                }
            } catch (error) {
                logger.error(`Failed to grant spins for order ${orderId}.`, error);
            }
        }

        const userName = shippingAddress?.recipientName ?? "Khách hàng";
        const orderIdShort = orderId.substring(0, 8).toUpperCase();
        const formattedTotal = new Intl.NumberFormat("vi-VN", {style: "currency", currency: "VND"}).format(total);

        if (oldStatus === "pending_approval" && placedBy?.userId) {
            const placerDoc = await db.collection("users").doc(placedBy.userId).get();
            if (placerDoc.exists) {
                const placerData = placerDoc.data()!;
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
                    if (placerData.fcmToken) {
                        await sendPushNotification([placerData.fcmToken], title, body, {type, orderId});
                    }
                    await saveNotificationToFirestore(placedBy.userId, title, body, type, {orderId});
                }
            }
        }

        let notificationTitle: string | null = null;
        let notificationBody: string | null = null;
        const type = "order_status_general";

        switch (newStatus) {
            case "processing":
                notificationTitle = "✅ Đơn hàng đã được xác nhận";
                notificationBody = `Đơn hàng #${orderIdShort} của bạn trị giá ${formattedTotal} đang được chuẩn bị.`;
                break;
            case "shipped":
                notificationTitle = "🚚 Đơn hàng đang được giao";
                const date = shippingDate?.toDate ? format(shippingDate.toDate(), "dd/MM/yyyy", {timeZone: "Asia/Ho_Chi_Minh"}) : null;
                notificationBody = `Đơn hàng #${orderIdShort} đang được vận chuyển` + (date ? `, dự kiến giao ngày ${date}.` : ".");
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
            const recipientIds = new Set<string>([userId, salesRepId].filter((id): id is string => !!id));
            const staff = await getRecipientsByRoles(["admin", "accountant"]);
            staff.forEach((s) => recipientIds.add(s.id));

            const usersSnapshot = await db.collection("users").where(admin.firestore.FieldPath.documentId(), "in", Array.from(recipientIds)).get();
            const tokensToSend = usersSnapshot.docs.map((doc) => doc.data().fcmToken as string).filter((token) => token);

            if (tokensToSend.length > 0) {
                await sendPushNotification(tokensToSend, notificationTitle, notificationBody, {type, orderId});
            }

            const savePromises = Array.from(recipientIds).map((id) =>
                saveNotificationToFirestore(id, notificationTitle!, notificationBody!, type, {orderId})
            );
            await Promise.all(savePromises);
        }
    });

// ===================================================================
// FUNCTION 7: GỬI THÔNG BÁO KHI CÓ BÀI VIẾT MỚI
// ===================================================================
export const onNewsArticleCreated = onDocumentCreated(
    {document: "newsArticles/{articleId}", region: "asia-southeast1"},
    async (event) => {
        const article = event.data?.data();
        const articleId = event.params.articleId;
        if (!article) return;
        const recipients = await getRecipientsByRoles(["agent_1", "agent_2", "admin"]);
        if (recipients.length === 0) return;

        const title = `📰 Tin Tức Mới: ${article.title}`;
        const body = article.summary ?? "Có một bài viết mới đang chờ bạn khám phá!";
        const type = "new_article";

        await sendPushNotification(recipients.map((r) => r.token), title, body, {
            type,
            articleId,
            payload: JSON.stringify({id: articleId}),
        });

        const savePromises = recipients.map((r) => saveNotificationToFirestore(r.id, title, body, type, {articleId}));
        await Promise.all(savePromises);
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
        if (adminDoc.data()?.role !== "admin") {
            throw new HttpsError("permission-denied", "Bạn không có quyền thực hiện hành động này.");
        }
        const {title, body, salesRepId} = request.data;
        let salesRepName: string | null = null; // Khai báo biến để lưu tên

        if (!title || !body) {
            throw new HttpsError("invalid-argument", "Vui lòng nhập đầy đủ tiêu đề và nội dung.");
        }

        let userQuery = db.collection("users").where("status", "==", "active").where("role", "in", ["agent_1", "agent_2", "sales_rep"]);
        if (salesRepId && typeof salesRepId === "string") {
            userQuery = userQuery.where("salesRepId", "==", salesRepId);
            const salesRepDoc = await db.collection("users").doc(salesRepId).get();
        if (salesRepDoc.exists) {
            salesRepName = salesRepDoc.data()?.displayName ?? null;
            }
        }
        const usersSnapshot = await userQuery.get();
        const recipients = usersSnapshot.docs.map((doc) => ({id: doc.id, token: doc.data().fcmToken as string | undefined}));

        if (recipients.length === 0) {
            return {success: true, message: "Không tìm thấy người dùng nào phù hợp để gửi."};
        }
        const type = "manual_promo";

        await sendPushNotification(recipients.map((r) => r.token), title, body, {
            type,
            payload: JSON.stringify({sentAt: new Date().toISOString()}),
        });

        const savePromises = recipients.map((r) => saveNotificationToFirestore(r.id, title, body, type, {}));
        await Promise.all(savePromises);

        await db.collection("manualNotifications").add({
            title, body, sentBy: adminId,
            target: {
                type: salesRepId ? "sales_rep_group" : "all",
                id: salesRepId ?? null,
                salesRepName: salesRepName,
                },
            recipientCount: recipients.length,
            sentAt: new Date(),
         });
        return {success: true, message: `Đã gửi thông báo thành công đến ${recipients.length} người dùng.`};
    }
);

// ===================================================================
// FUNCTION 9: NVKD DUYỆT ĐẠI LÝ (Không thay đổi)
// ===================================================================
export const approveAgentBySalesRep = onCall({region: "asia-southeast1"}, async (request: CallableRequest) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Yêu cầu xác thực.");
    const salesRepId = request.auth.uid;
    const salesRepDoc = await db.collection("users").doc(salesRepId).get();
    if (salesRepDoc.data()?.role !== 'sales_rep') {
        throw new HttpsError("permission-denied", "Chỉ Nhân viên kinh doanh mới có quyền thực hiện.");
    }
    const {agentId, roleToSet} = request.data;
    if (!agentId || !roleToSet || !['agent_1', 'agent_2'].includes(roleToSet)) {
        throw new HttpsError("invalid-argument", "Thiếu hoặc sai thông tin đại lý.");
    }
    const agentRef = db.collection("users").doc(agentId);
    const agentDoc = await agentRef.get();
    if (!agentDoc.exists || agentDoc.data()?.status !== 'pending_approval') {
         throw new HttpsError("not-found", "Không tìm thấy đại lý đang chờ duyệt hợp lệ.");
    }
    await agentRef.update({status: 'active', role: roleToSet, salesRepId: salesRepId});
    return { success: true, message: "Duyệt đại lý thành công!" };
});

// ===================================================================
// FUNCTION 10: TẠO MỘT CAM KẾT DOANH THU MỚI (Không thay đổi)
// ===================================================================
export const createSalesCommitment = onCall({region: "asia-southeast1"}, async (request: CallableRequest) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Authentication required.");
    const userId = request.auth.uid;
    const {targetAmount, startDate, endDate} = request.data;
    if (!targetAmount || !startDate || !endDate) {
        throw new HttpsError("invalid-argument", "Missing required fields.");
    }
    try {
        const userRef = db.collection("users").doc(userId);
        const userDoc = await userRef.get();
        if (!userDoc.exists) throw new HttpsError("not-found", "User not found.");
        const userData = userDoc.data()!;
        if (!["agent_1", "agent_2"].includes(userData.role)) {
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
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            transaction.update(userRef, {activeRewardProgram: "sales_target"});
        });
        return { success: true, message: "Đăng ký cam kết doanh thu thành công!" };
    } catch (error) {
        if (error instanceof HttpsError) throw error;
        throw new HttpsError("internal", "Failed to create sales commitment.", error);
    }
});

// ===================================================================
// FUNCTION 11: THIẾT LẬP CHI TIẾT CAM KẾT (BỞI ADMIN/NVKD)
// ===================================================================
export const setSalesCommitmentDetails = onCall({region: "asia-southeast1"}, async (request: CallableRequest) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Authentication required.");
    const setterId = request.auth.uid;
    const {commitmentId, detailsText} = request.data;
    if (!commitmentId || !detailsText) throw new HttpsError("invalid-argument", "Missing required fields.");
    try {
        const setterDoc = await db.collection("users").doc(setterId).get();
        const setterData = setterDoc.data();
        if (!setterDoc.exists || !setterData || !["admin", "sales_rep", "accountant"].includes(setterData.role)) {
            throw new HttpsError("permission-denied", "You do not have permission.");
        }
        const commitmentRef = db.collection("sales_commitments").doc(commitmentId);
        await commitmentRef.update({
            "commitmentDetails": {
                text: detailsText,
                setByUserId: setterId,
                setByUserName: setterData.displayName ?? "Không rõ",
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            },
        });
        const agentId = (await commitmentRef.get()).data()?.userId;
        if (agentId) {
             const agentDoc = await db.collection("users").doc(agentId).get();
             if (agentDoc.exists) {
                 const title = "🎁 Cam kết của bạn đã được xác nhận!";
                 const body = "Công ty đã xác nhận phần thưởng cho cam kết doanh thu của bạn. Hãy xem ngay!";
                 const type = "commitment_details_set";
                 const token = agentDoc.data()?.fcmToken;
                 if (token) {
                    // --- SỬA LỖI 2: Thay thế hàm cũ ---
                    await sendPushNotification([token], title, body, {type, commitmentId});
                 }
                 await saveNotificationToFirestore(agentId, title, body, type, {commitmentId});
             }
        }
        return { success: true, message: "Thiết lập cam kết thành công." };
    } catch (error) {
        if (error instanceof HttpsError) throw error;
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
// --- THAY ĐỔI: FUNCTION 14: KHI YÊU CẦU ĐỔI TRẢ MỚI ĐƯỢC TẠO ---
// ===================================================================
export const onReturnRequestCreated = onDocumentCreated(
    {document: "returnRequests/{requestId}", region: "asia-southeast1"},
    async (event) => {
        const requestData = event.data?.data();
        const requestId = event.params.requestId;
        if (!requestData) return;
        await db.collection("orders").doc(requestData.orderId).update({
            returnInfo: {returnRequestId: requestId, returnStatus: "pending_approval"},
        });
        const staff = await getRecipientsByRoles(["admin", "accountant"]);
        if (staff.length === 0) return;

        const title = "📬 Có yêu cầu đổi/trả mới";
        const body = `Đại lý "${requestData.userDisplayName}" vừa gửi yêu cầu đổi/trả cho đơn #${requestData.orderId.substring(0, 8).toUpperCase()}.`;
        const type = "new_return_request";
        const dataPayload = { type, returnRequestId: requestId, orderId: requestData.orderId };

        const tokens = staff.map((r) => r.token).filter((t): t is string => !!t);
        if (tokens.length > 0) {
            await sendPushNotification(tokens, title, body, dataPayload);
        }

        const savePromises = staff.map((r) => saveNotificationToFirestore(r.id, title, body, type, dataPayload));
        await Promise.all(savePromises);
    }
);

// ===================================================================
// --- THAY ĐỔI: FUNCTION 15: KHI YÊU CẦU ĐỔI TRẢ ĐƯỢC CẬP NHẬT ---
// ===================================================================
export const onReturnRequestUpdated = onDocumentUpdated(
    {document: "returnRequests/{requestId}", region: "asia-southeast1"},
    async (event) => {
        const afterData = event.data?.after.data();
        if (!afterData) return;

        const {userId, orderId, status: newStatus, adminNotes} = afterData;
        const requestId = event.params.requestId;
        await db.collection("orders").doc(orderId).update({
            returnInfo: {returnRequestId: requestId, returnStatus: newStatus},
        });
        const userDoc = await db.collection("users").doc(userId).get();
        if (!userDoc.exists) return;

        let title = "";
        let body = "";
        const type = "return_request_status_update";
        const shortOrderId = orderId.substring(0, 8).toUpperCase();
        switch (newStatus) {
            case "approved":
                title = "✅ Yêu cầu đổi/trả đã được duyệt";
                body = `Yêu cầu đổi/trả cho đơn hàng #${shortOrderId} của bạn đã được duyệt. Công ty sẽ liên hệ để xử lý.`;
                break;
            case "rejected":
                title = "❌ Yêu cầu đổi/trả bị từ chối";
                body = `Yêu cầu đổi/trả cho đơn hàng #${shortOrderId} đã bị từ chối. Lý do: ${adminNotes ?? "Không có"}`;
                break;
            case "completed":
                title = "✨ Yêu cầu đổi/trả đã hoàn thành";
                body = `Quá trình đổi/trả cho đơn hàng #${shortOrderId} của bạn đã được xử lý xong.`;
                break;
            default: return;
        }

        const token = userDoc.data()?.fcmToken;
        const dataPayload = {type, returnRequestId: requestId, orderId};
        if (token) {
            await sendPushNotification([token], title, body, dataPayload);
        }
        await saveNotificationToFirestore(userId, title, body, type, dataPayload);
    }
);

// ===================================================================
// --- FUNCTION 16: TỰ ĐỘNG TRỪ CÔNG NỢ KHI ĐƠN ĐỔI TRẢ HOÀN THÀNH ---
// ===================================================================
export const onReturnRequestCompleted = onDocumentUpdated(
  {document: "returnRequests/{requestId}", region: "asia-southeast1"},
  async (event: FirestoreEvent<Change<QueryDocumentSnapshot> | undefined>) => {
    // Kiểm tra xem event.data có tồn tại không
    if (!event.data) {
      logger.warn("Event data is missing for onReturnRequestCompleted.");
      return;
    }

    const change: Change<QueryDocumentSnapshot> | undefined = event.data;
        if (!change) {
          logger.warn("Event data (change object) is missing for onReturnRequestCompleted.");
          return;
        }
    const beforeData = change.before.data();
    const afterData = change.after.data();

    // Kiểm tra xem beforeData và afterData có tồn tại không
    if (!beforeData || !afterData) {
      logger.warn("Before or after data is missing in the change object.");
      return;
    }

    // Chỉ thực thi khi trạng thái chuyển thành 'completed'
    if (beforeData.status !== "completed" && afterData.status === "completed") {
      const penaltyFee = afterData.penaltyFee as number;
      const userId = afterData.userId as string;
      const orderId = afterData.orderId as string;
      const requestId = event.params.requestId; // Lấy requestId từ event.params

      // Nếu không có phí phạt, không làm gì cả
      if (!userId || penaltyFee <= 0) {
        logger.log( // Sử dụng logger đã import
          `No penalty fee for return request ${requestId}. Skipping.`
        );
        return; // Dùng return thay vì return null
      }

      // const db = admin.firestore(); // db đã được khởi tạo ở đầu file
      const userRef = db.collection("users").doc(userId);

      try {
        // Sử dụng transaction để đảm bảo tính toàn vẹn dữ liệu
        await db.runTransaction(async (transaction) => {
          const userDoc = await transaction.get(userRef);
          if (!userDoc.exists) {
            throw new Error(`User ${userId} not found!`);
          }

          const currentDebt = (userDoc.data()?.debtAmount as number) || 0;
          const newDebt = currentDebt + penaltyFee;

          // 1. Cập nhật công nợ của user
          transaction.update(userRef, {debtAmount: newDebt});

          // 2. Ghi lại một giao dịch công nợ để đối soát
          const debtTransactionRef = db.collection("debtTransactions").doc();
          transaction.set(debtTransactionRef, {
            userId: userId,
            amount: penaltyFee,
            type: "return_penalty",
            description: `Phí phạt đổi trả cho đơn hàng #${orderId.substring(0, 8).toUpperCase()}`,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            orderId: orderId,
            returnRequestId: requestId,
          });
        });

        logger.log( // Sử dụng logger đã import
          `Successfully applied penalty of ${penaltyFee} to user ${userId} for return request ${requestId}.`
        );
      } catch (error) {
        logger.error( // Sử dụng logger đã import
          `Failed to apply penalty for return request ${requestId}:`,
          error
        );
        // Có thể thêm throw error ở đây nếu muốn Cloud Functions báo lỗi
      }
    }
    return; // Dùng return thay vì return null
  });

// ===================================================================
// --- FUNCTION 17: KHI VOUCHER ĐƯỢC TẠO ---
// ===================================================================
export const onVoucherCreated = onDocumentCreated(
    { document: "vouchers/{voucherId}", region: "asia-southeast1" },
    async (event) => {
        const voucherData = event.data?.data();
        const voucherId = event.params.voucherId;
        // Chỉ thông báo nếu voucher mới tạo cần duyệt
        if (!voucherData || voucherData.status !== VoucherStatus.pendingApproval) {
            logger.info(`Voucher ${voucherId} created with status ${voucherData?.status}, no notification needed.`);
            return;
        }

        const { createdBy } = voucherData;
        if (!createdBy) {
            logger.warn(`Voucher ${voucherId} is missing 'createdBy' field.`);
            return;
        }

        try {
            // Lấy tên NVKD
            const creatorDoc = await db.collection("users").doc(createdBy).get();
            const creatorName = creatorDoc.data()?.displayName ?? createdBy;

            // Lấy danh sách Admin
            const admins = await getRecipientsByRoles(["admin"]);
            if (admins.length === 0) {
                logger.info("No admins found to notify about new voucher.");
                return;
            }

            // Chuẩn bị thông báo
            const title = "🔔 Yêu cầu duyệt voucher mới";
            const body = `NVKD "${creatorName}" vừa tạo voucher "${voucherId}" và đang chờ bạn duyệt.`;
            const type = "voucher_approval_request"; // Loại thông báo mới
            const dataPayload = { type, voucherId };

            // Gửi và lưu thông báo cho từng Admin
            const tokens = admins.map((r) => r.token);
            await sendPushNotification(tokens, title, body, dataPayload);

            const savePromises = admins.map((admin) =>
                saveNotificationToFirestore(admin.id, title, body, type, dataPayload)
            );
            await Promise.all(savePromises);

            logger.info(`Sent voucher creation notification for ${voucherId} to ${admins.length} admins.`);

        } catch (error) {
            logger.error(`Error processing voucher creation notification for ${voucherId}:`, error);
        }
    }
);

// ===================================================================
// --- FUNCTION 18: KHI VOUCHER ĐƯỢC CẬP NHẬT ---
// ===================================================================
export const onVoucherUpdated = onDocumentUpdated(
    { document: "vouchers/{voucherId}", region: "asia-southeast1" },
    async (event) => {
        // Kiểm tra xem event.data có tồn tại không
        if (!event.data) {
          logger.warn(`Event data is missing for onVoucherUpdated, voucherId: ${event.params.voucherId}.`);
          return;
        }
        const beforeData = event.data?.before.data();
        const afterData = event.data?.after.data();
        const voucherId = event.params.voucherId;

        // Bỏ qua nếu không có dữ liệu hoặc status không đổi
        if (!beforeData || !afterData || beforeData.status === afterData.status) {
            logger.info(`Voucher ${voucherId} status unchanged (${afterData?.status}), skipping notification.`);
            return;
        }

        const oldStatus = beforeData.status;
        const newStatus = afterData.status;
        const createdBy = afterData.createdBy; // ID của NVKD

        // Lấy lý do từ chối từ history entry gần nhất có action phù hợp
        const rejectionEntry = (afterData.history as any[])
                                 ?.slice().reverse() // Đảo ngược để tìm từ cuối lên
                                 .find(h => h.action === 'rejected' || h.action === 'deletion_rejected');
        const rejectionNotes = rejectionEntry?.notes ?? ""; // Lấy trường 'notes' (ĐÃ SỬA)

        if (!createdBy) {
            logger.warn(`Voucher ${voucherId} is missing 'createdBy' field during update.`);
            return;
        }

        try {
            // --- Trường hợp 1: NVKD gửi yêu cầu (Sửa hoặc Yêu cầu Xóa) -> Thông báo Admin ---
            if ( (newStatus === VoucherStatus.pendingApproval && oldStatus !== VoucherStatus.pendingApproval) ||
                 (newStatus === VoucherStatus.pendingDeletion && oldStatus !== VoucherStatus.pendingDeletion) )
            {
                const creatorDoc = await db.collection("users").doc(createdBy).get();
                const creatorName = creatorDoc.data()?.displayName ?? createdBy;
                const admins = await getRecipientsByRoles(["admin"]);
                if (admins.length === 0) {
                     logger.info(`No admins found to notify about voucher update request for ${voucherId}.`);
                     return;
                }

                const actionText = newStatus === VoucherStatus.pendingApproval ? "sửa" : "xóa";
                const title = `🔔 Yêu cầu duyệt ${actionText} voucher`;
                const body = `NVKD "${creatorName}" vừa yêu cầu ${actionText} voucher "${voucherId}" và đang chờ bạn duyệt.`;
                const type = "voucher_approval_request"; // Dùng chung type cho dễ
                const dataPayload = { type, voucherId };

                const tokens = admins.map((r) => r.token);
                await sendPushNotification(tokens, title, body, dataPayload);

                const savePromises = admins.map((admin) =>
                    saveNotificationToFirestore(admin.id, title, body, type, dataPayload)
                );
                await Promise.all(savePromises);
                logger.info(`Sent voucher ${actionText} request notification for ${voucherId} to ${admins.length} admins.`);
                return; // Kết thúc xử lý cho trường hợp này
            }

            // --- Trường hợp 2: Admin phản hồi (Duyệt/Từ chối Tạo/Sửa, Từ chối Xóa) -> Thông báo NVKD ---
            let title = "";
            let body = "";
            let type = "voucher_status_update"; // Loại thông báo chung

            // Admin duyệt tạo/sửa
            if (oldStatus === VoucherStatus.pendingApproval && newStatus === VoucherStatus.active) {
                title = `✅ Voucher "${voucherId}" đã được duyệt`;
                body = `Voucher "${voucherId}" bạn tạo/sửa đã được phê duyệt và đang hoạt động.`;
            }
            // Admin từ chối tạo/sửa
            else if (oldStatus === VoucherStatus.pendingApproval && newStatus === VoucherStatus.rejected) {
                title = `❌ Voucher "${voucherId}" bị từ chối`;
                body = `Yêu cầu tạo/sửa voucher "${voucherId}" đã bị từ chối.` + (rejectionNotes ? ` Lý do: ${rejectionNotes}` : "");
                type = "voucher_rejected";
            }
            // Admin từ chối xóa (voucher quay lại trạng thái cũ)
            else if (oldStatus === VoucherStatus.pendingDeletion && newStatus !== VoucherStatus.pendingDeletion) { // newStatus có thể là active, pending_approval, rejected...
                 title = `↩️ Yêu cầu xóa voucher "${voucherId}" bị từ chối`;
                 body = `Admin đã từ chối yêu cầu xóa voucher "${voucherId}".` + (rejectionNotes ? ` Lý do: ${rejectionNotes}` : "");
                 type = "voucher_deletion_rejected";
            }

            // Gửi thông báo nếu có nội dung
            if (title && body) {
                const creatorDoc = await db.collection("users").doc(createdBy).get();
                 if (!creatorDoc.exists) {
                     logger.warn(`Creator NVKD ${createdBy} not found for voucher ${voucherId}. Cannot send notification.`);
                     return;
                 }
                const creatorToken = creatorDoc.data()?.fcmToken as string | undefined;
                const dataPayload = { type, voucherId };

                if (creatorToken) {
                    await sendPushNotification([creatorToken], title, body, dataPayload);
                }
                await saveNotificationToFirestore(createdBy, title, body, type, dataPayload);
                logger.info(`Sent voucher status update notification ('${type}') for ${voucherId} to NVKD ${createdBy}.`);
            } else {
                 logger.info(`No specific Admin->NVKD notification triggered for voucher ${voucherId} status change from ${oldStatus} to ${newStatus}.`);
            }

        } catch (error) {
            logger.error(`Error processing voucher update notification for ${voucherId}:`, error);
        }
    }
);

// ===================================================================
// --- FUNCTION 19: KHI VOUCHER BỊ XÓA (THÔNG BÁO CHO NVKD) ---
// ===================================================================
export const onVoucherDeleted = onDocumentDeleted(
    { document: "vouchers/{voucherId}", region: "asia-southeast1" },
    async (event: FirestoreEvent<QueryDocumentSnapshot | undefined>) => {
        const deletedData = event.data?.data(); // Dữ liệu của voucher *trước khi* bị xóa
        const voucherId = event.params.voucherId;

        // Bỏ qua nếu không lấy được dữ liệu cũ (hiếm khi xảy ra)
        if (!deletedData) {
             logger.warn(`Could not get data for deleted voucher ${voucherId}. Skipping notification.`);
             return;
        }

        const createdBy = deletedData.createdBy; // ID của NVKD đã tạo voucher
        const lastHistoryEntry = (deletedData.history as any[])?.slice(-1)[0]; // Lấy entry cuối cùng trong lịch sử

        // Kiểm tra xem voucher có đang ở trạng thái chờ xóa không
        // VÀ hành động cuối cùng có phải là 'approved_deletion' không (hành động ta sẽ thêm ở client)
        if ( createdBy &&
             deletedData.status === VoucherStatus.pendingDeletion && // Phải đang chờ xóa
             lastHistoryEntry?.action === 'approved_deletion' // Hành động cuối phải là admin duyệt xóa
            )
        {
             try {
                // Lấy thông tin NVKD để gửi thông báo
                const creatorDoc = await db.collection("users").doc(createdBy).get();
                 if (!creatorDoc.exists) {
                     logger.warn(`Creator NVKD ${createdBy} not found for deleted voucher ${voucherId}. Cannot send notification.`);
                     return;
                 }
                const creatorToken = creatorDoc.data()?.fcmToken as string | undefined;

                // Chuẩn bị thông báo
                const title = `🗑️ Voucher "${voucherId}" đã được xóa`;
                const body = `Yêu cầu xóa voucher "${voucherId}" của bạn đã được Admin phê duyệt thành công.`;
                const type = "voucher_deleted"; // Type mới
                const dataPayload = { type, voucherId };

                // Gửi thông báo đẩy nếu có token
                if (creatorToken) {
                    await sendPushNotification([creatorToken], title, body, dataPayload);
                }
                // Luôn lưu thông báo vào Firestore
                await saveNotificationToFirestore(createdBy, title, body, type, dataPayload);
                logger.info(`Sent voucher deletion notification for ${voucherId} to NVKD ${createdBy}.`);

             } catch (error) {
                 logger.error(`Error sending voucher deletion notification for ${voucherId}:`, error);
             }
        } else {
             logger.info(`Voucher ${voucherId} deleted, but conditions for notification not met (status: ${deletedData.status}, last action: ${lastHistoryEntry?.action}).`);
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