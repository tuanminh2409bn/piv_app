import 'package:dartz/dartz.dart';
import 'package:piv_app/core/error/failure.dart';
import 'package:piv_app/data/models/order_model.dart'; // Sử dụng OrderModel đã tạo

abstract class OrderRepository {
  /// Tạo một đơn hàng mới trên Firestore và xóa giỏ hàng.
  /// Trả về ID của đơn hàng mới được tạo nếu thành công.
  Future<Either<Failure, String>> createOrder(OrderModel order);
}
