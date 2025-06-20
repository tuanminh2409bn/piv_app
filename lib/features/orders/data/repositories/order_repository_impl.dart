import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:piv_app/core/error/failure.dart';
import 'package:piv_app/data/models/order_model.dart';
import 'package:piv_app/data/models/order_item_model.dart';
import 'package:piv_app/data/models/address_model.dart';
import 'package:piv_app/features/orders/domain/repositories/order_repository.dart';
import 'dart:developer' as developer;

class OrderRepositoryImpl implements OrderRepository {
  final FirebaseFirestore _firestore;

  OrderRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ... (các phương thức createOrder, getUserOrders, getOrderById không đổi) ...
  @override
  Future<Either<Failure, String>> createOrder(OrderModel order) async {
    try {
      final newOrderId = await _firestore.runTransaction((transaction) async {
        final newOrderRef = _firestore.collection('orders').doc();
        final cartRef = _firestore.collection('carts').doc(order.userId);
        transaction.set(newOrderRef, order.toMap());
        transaction.delete(cartRef);
        return newOrderRef.id;
      });
      return Right(newOrderId);
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định khi tạo đơn hàng: ${e.toString()}'));
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

  // ** IMPLEMENT PHƯƠNG THỨC MỚI CHO ADMIN **
  @override
  Future<Either<Failure, List<OrderModel>>> getAllOrders() async {
    try {
      final querySnapshot = await _firestore
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .get();

      // Logic map dữ liệu tương tự như getUserOrders
      final orders = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return OrderModel(
          id: doc.id,
          userId: data['userId'],
          items: (data['items'] as List<dynamic>)
              .map((item) => OrderItemModel.fromMap(item as Map<String, dynamic>))
              .toList(),
          shippingAddress: AddressModel.fromMap(data['shippingAddress'] as Map<String, dynamic>),
          subtotal: (data['subtotal'] as num).toDouble(),
          shippingFee: (data['shippingFee'] as num).toDouble(),
          discount: (data['discount'] as num).toDouble(),
          total: (data['total'] as num).toDouble(),
          paymentMethod: data['paymentMethod'],
          status: data['status'],
          createdAt: data['createdAt'],
        );
      }).toList();

      developer.log('Fetched all ${orders.length} orders.', name: 'OrderRepository');
      return Right(orders);
    } on FirebaseException catch (e) {
      developer.log('FirebaseException in getAllOrders: ${e.message}', name: 'OrderRepository');
      return Left(ServerFailure('Lỗi Firebase khi tải tất cả đơn hàng: ${e.message}'));
    } catch (e) {
      developer.log('Unknown error in getAllOrders: ${e.toString()}', name: 'OrderRepository');
      return Left(ServerFailure('Lỗi không xác định khi tải tất cả đơn hàng: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': newStatus,
      });
      developer.log('Updated status for order $orderId to $newStatus', name: 'OrderRepository');
      return const Right(unit);
    } on FirebaseException catch (e) {
      developer.log('FirebaseException in updateOrderStatus: ${e.message}', name: 'OrderRepository');
      return Left(ServerFailure('Lỗi Firebase khi cập nhật trạng thái đơn hàng: ${e.message}'));
    } catch (e) {
      developer.log('Unknown error in updateOrderStatus: ${e.toString()}', name: 'OrderRepository');
      return Left(ServerFailure('Lỗi không xác định khi cập nhật trạng thái đơn hàng: ${e.toString()}'));
    }
  }
}
