import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:piv_app/core/error/failure.dart';
import 'package:piv_app/data/models/order_model.dart';
import 'package:piv_app/features/orders/domain/repositories/order_repository.dart';
import 'dart:developer' as developer;

class OrderRepositoryImpl implements OrderRepository {
  final FirebaseFirestore _firestore;

  OrderRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<Either<Failure, String>> createOrder(OrderModel order) async {
    try {
      // Sử dụng transaction để đảm bảo cả hai thao tác (tạo đơn hàng và xóa giỏ hàng)
      // đều thành công hoặc thất bại cùng nhau.
      final newOrderId = await _firestore.runTransaction((transaction) async {
        // 1. Tạo một tham chiếu cho document đơn hàng mới để lấy ID của nó trước
        final newOrderRef = _firestore.collection('orders').doc();

        // 2. Tham chiếu đến giỏ hàng của người dùng
        final cartRef = _firestore.collection('carts').doc(order.userId);

        // 3. Ghi dữ liệu đơn hàng mới vào Firestore
        transaction.set(newOrderRef, order.toMap());

        // 4. Xóa giỏ hàng của người dùng
        transaction.delete(cartRef);

        // Trả về ID của đơn hàng mới được tạo
        return newOrderRef.id;
      });

      developer.log('Order created successfully with ID: $newOrderId', name: 'OrderRepository');
      return Right(newOrderId);

    } on FirebaseException catch (e) {
      developer.log('FirebaseException in createOrder: ${e.message}', name: 'OrderRepository');
      return Left(ServerFailure('Lỗi Firebase khi tạo đơn hàng: ${e.message}'));
    } catch (e) {
      developer.log('Unknown error in createOrder: ${e.toString()}', name: 'OrderRepository');
      return Left(ServerFailure('Lỗi không xác định khi tạo đơn hàng: ${e.toString()}'));
    }
  }
}
