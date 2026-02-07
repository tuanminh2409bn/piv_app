import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:piv_app/features/admin/data/models/discount_policy_model.dart';
import 'package:piv_app/features/admin/data/models/discount_request_model.dart';
import 'package:piv_app/features/admin/domain/repositories/discount_repository.dart';

class DiscountRepositoryImpl implements DiscountRepository {
  final FirebaseFirestore firestore;

  DiscountRepositoryImpl(this.firestore);

  @override
  Future<void> updateDirectly({
    required String userId,
    required bool enabled,
    required AgentPolicy policy,
  }) async {
    await firestore.collection('users').doc(userId).update({
      'customDiscount': {
        'enabled': enabled,
        'policy': policy.toJson(),
      },
    });
  }

  @override
  Future<void> createRequest(DiscountRequestModel request) async {
    await firestore.collection('discount_requests').add(request.toMap());
  }

  @override
  Stream<List<DiscountRequestModel>> watchPendingRequests() {
    return firestore
        .collection('discount_requests')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DiscountRequestModel.fromSnapshot(doc))
            .toList());
  }

  @override
  Stream<DiscountRequestModel?> watchPendingRequestForAgent(String agentId) {
    return firestore
        .collection('discount_requests')
        .where('agentId', isEqualTo: agentId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        return DiscountRequestModel.fromSnapshot(snapshot.docs.first);
      }
      return null;
    });
  }

  @override
  Future<void> approveRequest(DiscountRequestModel request, String adminId, {Map<String, dynamic>? modifiedDiscountConfig}) async {
    final batch = firestore.batch();
    final requestRef = firestore.collection('discount_requests').doc(request.id);
    final userRef = firestore.collection('users').doc(request.agentId);

    // 1. Cập nhật trạng thái Request
    batch.update(requestRef, {
      'status': 'approved',
      'approvedBy': adminId,
      'approvedAt': FieldValue.serverTimestamp(),
      // Lưu lại cấu hình thực tế đã duyệt nếu có thay đổi
      if (modifiedDiscountConfig != null) 'approvedConfig': modifiedDiscountConfig, 
    });

    // 2. Áp dụng cấu hình vào User (Dùng cấu hình sửa đổi nếu có)
    batch.update(userRef, {
      'customDiscount': modifiedDiscountConfig ?? request.customDiscount,
    });

    await batch.commit();
  }

  @override
  Future<void> rejectRequest(String requestId, String reason) async {
    await firestore.collection('discount_requests').doc(requestId).update({
      'status': 'rejected',
      'rejectionReason': reason,
      'rejectedAt': FieldValue.serverTimestamp(),
    });
  }
}
