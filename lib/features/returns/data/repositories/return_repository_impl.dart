// lib/features/returns/data/repositories/return_repository_impl.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:piv_app/core/error/failure.dart';
import 'package:piv_app/data/models/order_model.dart';
import 'package:piv_app/features/returns/domain/entities/return_request_item.dart';
import 'package:piv_app/features/returns/domain/repositories/return_repository.dart';
import 'package:piv_app/features/returns/data/models/return_request_model.dart';
import 'package:uuid/uuid.dart';

class ReturnRepositoryImpl implements ReturnRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;

  ReturnRepositoryImpl({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _storage = storage,
        _auth = auth;

  @override
  Future<Either<Failure, void>> createReturnRequest({
    required OrderModel order,
    required List<ReturnRequestItem> items,
    required List<XFile> images,
    required String userNotes,
    required double penaltyFee,
    required double refundAmount,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Left(ServerFailure('Bạn cần đăng nhập để thực hiện chức năng này.'));
      }

      // 1. Tải hình ảnh lên Storage
      final imageUrls = await _uploadImages(order.id!, images);

      // 2. Tạo đối tượng yêu cầu đổi trả
      final requestId = const Uuid().v4();
      final requestData = {
        'id': requestId,
        'userId': user.uid,
        'userDisplayName': user.displayName ?? 'Không rõ',
        'orderId': order.id,
        'items': items.map((item) => item.toMap()).toList(),
        'imageUrls': imageUrls,
        'penaltyFee': penaltyFee,
        'refundAmount': refundAmount,
        'userNotes': userNotes,
        'status': 'pending_approval',
        'adminNotes': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // 3. Lưu vào Firestore
      await _firestore.collection('returnRequests').doc(requestId).set(requestData);

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Tạo yêu cầu thất bại: ${e.toString()}'));
    }
  }

  Future<List<String>> _uploadImages(String orderId, List<XFile> images) async {
    final List<String> downloadUrls = [];
    for (final image in images) {
      final fileName = const Uuid().v4();
      final ref = _storage.ref('return_requests/$orderId/$fileName.jpg');
      
      final bytes = await image.readAsBytes();
      final metadata = SettableMetadata(contentType: 'image/jpeg');
      
      final uploadTask = ref.putData(bytes, metadata);
      final snapshot = await uploadTask.whenComplete(() => null);
      final downloadUrl = await snapshot.ref.getDownloadURL();
      downloadUrls.add(downloadUrl);
    }
    return downloadUrls;
  }

  @override
  Stream<List<ReturnRequestModel>> watchAllReturnRequests() {
    return _firestore
        .collection('returnRequests')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ReturnRequestModel.fromSnapshot(doc)).toList();
    });
  }

  @override
  Future<Either<Failure, void>> updateReturnRequestStatus({
    required String requestId,
    required String newStatus,
    String? adminNotes,
    String? rejectionReason,
  }) async {
    try {
      final dataToUpdate = {
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (adminNotes != null) {
        dataToUpdate['adminNotes'] = adminNotes;
      }
      if (rejectionReason != null) {
        dataToUpdate['rejectionReason'] = rejectionReason;
      }

      await _firestore.collection('returnRequests').doc(requestId).update(dataToUpdate);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Cập nhật trạng thái thất bại: ${e.toString()}'));
    }
  }

  @override
  Stream<ReturnRequestModel> watchReturnRequestById(String requestId) {
    return _firestore
        .collection('returnRequests')
        .doc(requestId)
        .snapshots()
        .map((doc) => ReturnRequestModel.fromSnapshot(doc));
  }
}
