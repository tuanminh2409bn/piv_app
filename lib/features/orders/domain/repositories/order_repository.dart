import 'package:dartz/dartz.dart';
import 'package:piv_app/core/error/failure.dart';
import 'package:piv_app/data/models/order_model.dart';

abstract class OrderRepository {
  /// Tạo một đơn hàng mới trên Firestore và xóa giỏ hàng.
  Future<Either<Failure, String>> createOrder(OrderModel order);

  /// Lấy danh sách tất cả các đơn hàng của một người dùng cụ thể.
  Future<Either<Failure, List<OrderModel>>> getUserOrders(String userId);

  /// Lấy chi tiết một đơn hàng dựa trên ID của nó.
  Future<Either<Failure, OrderModel>> getOrderById(String orderId);

  /// **PHƯƠNG THỨC MỚI CHO ADMIN**
  /// Lấy tất cả các đơn hàng trong hệ thống.
  Future<Either<Failure, List<OrderModel>>> getAllOrders();

  /// **PHƯƠNG THỨC MỚI CHO ADMIN**
  /// Cập nhật trạng thái của một đơn hàng.
  Future<Either<Failure, Unit>> updateOrderStatus(String orderId, String newStatus);
}
