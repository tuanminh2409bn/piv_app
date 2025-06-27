import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:piv_app/core/error/failure.dart';
import 'package:piv_app/data/models/address_model.dart';
import 'package:piv_app/data/models/commission_model.dart';
import 'package:piv_app/data/models/order_item_model.dart';
import 'package:piv_app/data/models/order_model.dart';
import 'package:piv_app/data/models/user_model.dart';
import 'package:piv_app/features/admin/domain/repositories/settings_repository.dart';
import 'package:piv_app/features/orders/domain/repositories/order_repository.dart';
import 'dart:developer' as developer;

class OrderRepositoryImpl implements OrderRepository {
  final FirebaseFirestore _firestore;
  final SettingsRepository _settingsRepository;

  OrderRepositoryImpl({
    required FirebaseFirestore firestore,
    required SettingsRepository settingsRepository,
  })  : _firestore = firestore,
        _settingsRepository = settingsRepository;

  @override
  Future<Either<Failure, String>> createOrder(OrderModel order) async {
    try {
      final newOrderId = await _firestore.runTransaction((transaction) async {
        final newOrderRef = _firestore.collection('orders').doc();
        final cartRef = _firestore.collection('carts').doc(order.userId);

        final agentDoc = await _firestore.collection('users').doc(order.userId).get();
        String? salesRepId;
        if(agentDoc.exists) {
          final agent = UserModel.fromJson(agentDoc.data()!);
          salesRepId = agent.salesRepId;
        }

        var orderMap = order.toMap();
        if(salesRepId != null) {
          orderMap['salesRepId'] = salesRepId;
        }

        transaction.set(newOrderRef, orderMap);
        transaction.delete(cartRef);
        return newOrderRef.id;
      });
      return Right(newOrderId);
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định khi tạo đơn hàng: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateOrderStatus(String orderId, String newStatus) async {
    try {
      final orderRef = _firestore.collection('orders').doc(orderId);

      final commissionRateResult = await _settingsRepository.getCommissionRate();
      final commissionRate = commissionRateResult.getOrElse(() => 0.05);

      await _firestore.runTransaction((transaction) async {
        final orderSnapshot = await transaction.get(orderRef);
        if (!orderSnapshot.exists) {
          throw Exception("Đơn hàng không tồn tại!");
        }

        transaction.update(orderRef, {'status': newStatus});
        developer.log('Updated status for order $orderId to $newStatus', name: 'OrderRepository');

        if (newStatus == 'completed') {
          final orderData = orderSnapshot.data()!;
          final salesRepId = orderData['salesRepId'] as String?;
          final agentId = orderData['userId'] as String;

          if (salesRepId != null && salesRepId.isNotEmpty) {
            final commissionAmount = (orderData['total'] as num) * commissionRate;
            final newCommissionRef = _firestore.collection('commissions').doc();
            final agentName = (orderData['shippingAddress'] as Map<String, dynamic>)['recipientName'] ?? 'N/A';

            final commission = CommissionModel(
              id: newCommissionRef.id,
              orderId: orderId,
              orderTotal: (orderData['total'] as num).toDouble(),
              commissionRate: commissionRate,
              commissionAmount: commissionAmount,
              salesRepId: salesRepId,
              agentId: agentId,
              agentName: agentName,
              createdAt: Timestamp.now(),
            );

            transaction.set(newCommissionRef, commission.toMap());
            developer.log('Created commission for order $orderId for Sales Rep $salesRepId', name: 'OrderRepository');
          }
        }
      });

      return const Right(unit);
    } on FirebaseException catch (e) {
      return Left(ServerFailure('Lỗi Firebase khi cập nhật trạng thái đơn hàng: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định khi cập nhật trạng thái đơn hàng: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<OrderModel>>> getUserOrders(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      final orders = querySnapshot.docs.map((doc) => OrderModel.fromSnapshot(doc)).toList();
      return Right(orders);
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định khi tải lịch sử đơn hàng: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, OrderModel>> getOrderById(String orderId) async {
    try {
      final docSnapshot = await _firestore.collection('orders').doc(orderId).get();
      if (docSnapshot.exists) {
        return Right(OrderModel.fromSnapshot(docSnapshot));
      } else {
        return Left(ServerFailure('Không tìm thấy đơn hàng.'));
      }
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định khi tải chi tiết đơn hàng: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<OrderModel>>> getAllOrders() async {
    try {
      final querySnapshot = await _firestore
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .get();
      final orders = querySnapshot.docs.map((doc) => OrderModel.fromSnapshot(doc)).toList();
      return Right(orders);
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định khi tải tất cả đơn hàng: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<CommissionModel>>> getAllCommissions({DateTime? startDate, DateTime? endDate}) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('commissions')
          .orderBy('createdAt', descending: true);
      if (startDate != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate.add(const Duration(days: 1))));
      }
      final querySnapshot = await query.get();
      final commissions = querySnapshot.docs
          .map((doc) => CommissionModel.fromSnapshot(doc))
          .toList();
      return Right(commissions);
    } catch (e) {
      return Left(ServerFailure('Lỗi khi tải danh sách hoa hồng: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateCommissionStatus(String commissionId, String newStatus, String accountantId) async {
    try {
      await _firestore.collection('commissions').doc(commissionId).update({
        'status': newStatus,
        'paidAt': FieldValue.serverTimestamp(),
        'accountantId': accountantId,
      });
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure('Lỗi khi cập nhật trạng thái hoa hồng: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<CommissionModel>>> getCommissionsBySalesRepId(String salesRepId, {DateTime? startDate, DateTime? endDate}) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('commissions')
          .where('salesRepId', isEqualTo: salesRepId)
          .orderBy('createdAt', descending: true);

      // Thêm bộ lọc ngày
      if (startDate != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate.add(const Duration(days: 1))));
      }

      final querySnapshot = await query.get();
      final commissions = querySnapshot.docs.map((doc) => CommissionModel.fromSnapshot(doc)).toList();
      return Right(commissions);
    } catch (e) {
      // Lỗi này có thể xảy ra nếu bạn chưa tạo chỉ mục trên Firestore
      return Left(ServerFailure('Lỗi khi tải hoa hồng của NVKD: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Unit>> createCommission(CommissionModel commission) async {
    try {
      await _firestore.collection('commissions').doc(commission.id).set(commission.toMap());
      return const Right(unit);
    } on FirebaseException catch (e) {
      return Left(ServerFailure('Lỗi Firebase khi tạo hoa hồng: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định khi tạo hoa hồng: ${e.toString()}'));
    }
  }
}