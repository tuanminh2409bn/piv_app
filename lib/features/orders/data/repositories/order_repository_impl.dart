import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:piv_app/core/error/failure.dart';
import 'package:piv_app/data/models/commission_model.dart';
import 'package:piv_app/data/models/order_model.dart';
import 'package:piv_app/data/models/order_item_model.dart';
import 'package:piv_app/data/models/address_model.dart';
import 'package:piv_app/data/models/user_model.dart';
import 'package:piv_app/features/orders/domain/repositories/order_repository.dart';
import 'dart:developer' as developer;

class OrderRepositoryImpl implements OrderRepository {
  final FirebaseFirestore _firestore;

  OrderRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<Either<Failure, String>> createOrder(OrderModel order) async {
    try {
      final newOrderId = await _firestore.runTransaction((transaction) async {
        final newOrderRef = _firestore.collection('orders').doc();
        final cartRef = _firestore.collection('carts').doc(order.userId);

        // Lấy salesRepId từ user và gắn vào đơn hàng
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

      await _firestore.runTransaction((transaction) async {
        final orderSnapshot = await transaction.get(orderRef);
        if (!orderSnapshot.exists) {
          throw Exception("Đơn hàng không tồn tại!");
        }

        transaction.update(orderRef, {'status': newStatus});
        developer.log('Updated status for order $orderId to $newStatus', name: 'OrderRepository');

        // *** LOGIC TẠO HOA HỒNG TỰ ĐỘNG ***
        if (newStatus == 'completed') {
          final orderData = orderSnapshot.data()!;
          final salesRepId = orderData['salesRepId'] as String?;
          final agentId = orderData['userId'] as String;

          // Chỉ tạo hoa hồng nếu đơn hàng này có NVKD phụ trách
          if (salesRepId != null && salesRepId.isNotEmpty) {
            const commissionRate = 0.05; // Tạm thời hardcode 5%
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

  // --- Các hàm còn lại ---
  @override
  Future<Either<Failure, List<OrderModel>>> getUserOrders(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      final orders = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return OrderModel(id: doc.id,userId: data['userId'],items: (data['items'] as List<dynamic>).map((item) => OrderItemModel.fromMap(item as Map<String, dynamic>)).toList(),shippingAddress: AddressModel.fromMap(data['shippingAddress'] as Map<String, dynamic>),subtotal: (data['subtotal'] as num).toDouble(),shippingFee: (data['shippingFee'] as num).toDouble(),discount: (data['discount'] as num).toDouble(),total: (data['total'] as num).toDouble(),paymentMethod: data['paymentMethod'],status: data['status'],createdAt: data['createdAt'],);
      }).toList();
      return Right(orders);
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định khi tải lịch sử đơn hàng: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, OrderModel>> getOrderById(String orderId) async {
    try {
      final docSnapshot = await _firestore.collection('orders').doc(orderId).get();
      if (docSnapshot.exists && docSnapshot.data() != null) {
        final data = docSnapshot.data()!;
        final order = OrderModel(id: docSnapshot.id,userId: data['userId'],items: (data['items'] as List<dynamic>).map((item) => OrderItemModel.fromMap(item as Map<String, dynamic>)).toList(),shippingAddress: AddressModel.fromMap(data['shippingAddress'] as Map<String, dynamic>),subtotal: (data['subtotal'] as num).toDouble(),shippingFee: (data['shippingFee'] as num).toDouble(),discount: (data['discount'] as num).toDouble(),total: (data['total'] as num).toDouble(),paymentMethod: data['paymentMethod'],status: data['status'],createdAt: data['createdAt'],);
        return Right(order);
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
      final orders = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return OrderModel(id: doc.id, userId: data['userId'], items: (data['items'] as List<dynamic>).map((item) => OrderItemModel.fromMap(item as Map<String, dynamic>)).toList(), shippingAddress: AddressModel.fromMap(data['shippingAddress'] as Map<String, dynamic>), subtotal: (data['subtotal'] as num).toDouble(), shippingFee: (data['shippingFee'] as num).toDouble(), discount: (data['discount'] as num).toDouble(), total: (data['total'] as num).toDouble(), paymentMethod: data['paymentMethod'], status: data['status'], createdAt: data['createdAt']);
      }).toList();
      return Right(orders);
    } on FirebaseException catch (e) {
      return Left(ServerFailure('Lỗi Firebase khi tải tất cả đơn hàng: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định khi tải tất cả đơn hàng: ${e.toString()}'));
    }
  }

  // Các phương thức mới cho hoa hồng
  @override
  Future<Either<Failure, List<CommissionModel>>> getAllCommissions() async {
    try {
      final querySnapshot = await _firestore
          .collection('commissions')
          .orderBy('createdAt', descending: true)
          .get();
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
  Future<Either<Failure, List<CommissionModel>>> getCommissionsBySalesRepId(String salesRepId) async {
    try {
      final querySnapshot = await _firestore
          .collection('commissions')
          .where('salesRepId', isEqualTo: salesRepId)
          .orderBy('createdAt', descending: true)
          .get();
      final commissions = querySnapshot.docs
          .map((doc) => CommissionModel.fromSnapshot(doc))
          .toList();
      return Right(commissions);
    } catch (e) {
      return Left(ServerFailure('Lỗi khi tải danh sách hoa hồng của NVKD: ${e.toString()}'));
    }
  }
}