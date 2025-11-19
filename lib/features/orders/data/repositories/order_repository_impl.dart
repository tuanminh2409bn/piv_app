// lib/features/orders/data/repositories/order_repository_impl.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:piv_app/core/error/failure.dart';
import 'package:piv_app/data/models/commission_model.dart';
import 'package:piv_app/data/models/order_model.dart';
import 'package:piv_app/data/models/user_model.dart';
import 'package:piv_app/features/orders/domain/repositories/order_repository.dart';
import 'package:piv_app/data/models/payment_info_model.dart';
import 'dart:developer' as developer;

class OrderRepositoryImpl implements OrderRepository {
  final FirebaseFirestore _firestore;

  OrderRepositoryImpl({
    required FirebaseFirestore firestore,
  })  : _firestore = firestore;

  @override
  Future<Either<Failure, String>> createOrder(OrderModel order, {bool clearCart = true}) async {
    try {
      final newOrderId = await _firestore.runTransaction((transaction) async {
        final newOrderRef = _firestore.collection('orders').doc();
        final agentDoc = await _firestore.collection('users').doc(order.userId).get();
        String? salesRepId;
        if (agentDoc.exists) {
          final agent = UserModel.fromJson(agentDoc.data()!);
          salesRepId = agent.salesRepId;
        }

        var orderMap = order.toMap();
        if (salesRepId != null) {
          orderMap['salesRepId'] = salesRepId;
        }
        transaction.set(newOrderRef, orderMap);

        if (clearCart) {
          final cartRef = _firestore.collection('carts').doc(order.userId);
          transaction.delete(cartRef);
        }
        return newOrderRef.id;
      });
      return Right(newOrderId);
    } catch (e) {
      developer.log('Error creating order: $e', name: 'OrderRepositoryError');
      return Left(ServerFailure('Lỗi không xác định khi tạo đơn hàng: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateOrderStatus(String orderId, String newStatus) async {
    try {
      final orderRef = _firestore.collection('orders').doc(orderId);

      await _firestore.runTransaction((transaction) async {
        final orderSnapshot = await transaction.get(orderRef);
        if (!orderSnapshot.exists) {
          throw Exception("Đơn hàng không tồn tại!");
        }
        final order = OrderModel.fromSnapshot(orderSnapshot);

        transaction.update(orderRef, {'status': newStatus});
        developer.log('Updated status for order $orderId to $newStatus', name: 'OrderRepository');

        if (newStatus == 'completed') {
          final userRef = _firestore.collection('users').doc(order.userId);
          transaction.update(userRef, {'debtAmount': order.remainingDebt});
          developer.log(
              'Order completed. Updating debt for user ${order.userId} to ${order.remainingDebt}',
              name: 'OrderRepository'
          );
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

  @override
  Stream<OrderModel> getOrderStreamById(String orderId) {
    final docRef = _firestore.collection('orders').doc(orderId);
    return docRef.snapshots().map((snapshot) {
      if (!snapshot.exists) {
        throw Exception('Order with ID $orderId does not exist.');
      }
      return OrderModel.fromSnapshot(snapshot);
    });
  }

  @override
  Future<Either<Failure, List<OrderModel>>> getOrdersForSalesRepByAgent({
    required String salesRepId,
    required String agentId,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: agentId) // Điều kiện 1: Đúng đại lý
          .where('salesRepId', isEqualTo: salesRepId) // Điều kiện 2: Đúng NVKD quản lý
          .orderBy('createdAt', descending: true)
          .get();
      final orders = querySnapshot.docs.map((doc) => OrderModel.fromSnapshot(doc)).toList();
      return Right(orders);
    } catch (e) {
      // Lỗi này thường xảy ra nếu bạn chưa tạo Composite Index trên Firestore
      return Left(ServerFailure('Lỗi khi tải đơn hàng của đại lý: ${e.toString()}. Có thể bạn cần tạo chỉ mục (index) trên Firestore.'));
    }
  }

  @override
  Future<Either<Failure, Unit>> approveOrder(
      String orderId, {
        required double paidAmount,
        required double voucherDiscount,
        String? appliedVoucherCode,
      }) async {
    try {
      final orderRef = _firestore.collection('orders').doc(orderId);

      await _firestore.runTransaction((transaction) async {
        final orderSnapshot = await transaction.get(orderRef);
        if (!orderSnapshot.exists) {
          throw Exception("Đơn hàng không tồn tại!");
        }

        final orderData = orderSnapshot.data() as Map<String, dynamic>;
        final double orderFinalTotal = (orderData['finalTotal'] as num?)?.toDouble() ?? 0.0;
        final double orderDebtAmount = (orderData['debtAmount'] as num?)?.toDouble() ?? 0.0;
        final double newRemainingDebt = orderFinalTotal + orderDebtAmount - paidAmount - voucherDiscount;

        final Map<String, dynamic> dataToUpdate = {
          'status': 'pending',
          'approvedAt': FieldValue.serverTimestamp(),
          'paidAmount': paidAmount,
          'remainingDebt': newRemainingDebt.clamp(0, double.infinity),
          'discount': voucherDiscount,
          'appliedVoucherCode': appliedVoucherCode,
        };
        transaction.update(orderRef, dataToUpdate);
        developer.log('Approved order $orderId. Set paid: $paidAmount, discount: $voucherDiscount, code: $appliedVoucherCode, newRemainingDebt: $newRemainingDebt', name: 'OrderRepository');
      });

      return const Right(unit);
    } on FirebaseException catch (e) {
      developer.log('Firebase Error approving order: ${e.code} - ${e.message}', name: 'OrderRepositoryError');
      return Left(ServerFailure(e.message ?? 'Lỗi Firebase khi duyệt đơn hàng.'));
    } catch (e) {
      developer.log('Unknown Error approving order: $e', name: 'OrderRepositoryError');
      return Left(ServerFailure('Lỗi không xác định khi duyệt đơn hàng: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Unit>> rejectOrder({required String orderId, required String reason}) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': 'rejected',
        'rejectionReason': reason,
        'rejectedAt': FieldValue.serverTimestamp(),
      });
      return const Right(unit);
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.message ?? 'Lỗi khi từ chối đơn hàng.'));
    }
  }

  @override
  Future<Either<Failure, Unit>> confirmOrderPayment(String orderId) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'paymentStatus': 'paid',
      });
      developer.log('Confirmed payment for order: $orderId', name: 'OrderRepository');
      return const Right(unit);
    } on FirebaseException catch (e) {
      return Left(ServerFailure('Lỗi Firebase khi xác nhận thanh toán: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, PaymentInfoModel>> getPaymentInfo() async {
    try {
      final docSnapshot = await _firestore.collection('settings').doc('payment_info').get();
      if (docSnapshot.exists) {
        return Right(PaymentInfoModel.fromSnapshot(docSnapshot));
      } else {
        return Left(ServerFailure('Không tìm thấy thông tin thanh toán.'));
      }
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.message ?? 'Lỗi khi tải thông tin thanh toán.'));
    }
  }

// --- HÀM MỚI ---
  @override
  Future<Either<Failure, Unit>> notifyPaymentMade(String orderId) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'paymentStatus': 'verifying',
      });
      return const Right(unit);
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.message ?? 'Có lỗi xảy ra.'));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateOrderStatusToShipped(String orderId, DateTime shippingDate) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': 'shipped',
        'shippingDate': Timestamp.fromDate(shippingDate),
      });
      return const Right(unit);
    } on FirebaseException catch (e) {
      return Left(ServerFailure('Lỗi Firebase: ${e.message}'));
    }
  }

  @override
  Stream<List<OrderModel>> watchUserOrders(String userId) {
    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => OrderModel.fromSnapshot(doc)).toList());
  }
}