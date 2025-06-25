import 'package:dartz/dartz.dart';
import 'package:piv_app/core/error/failure.dart';
import 'package:piv_app/data/models/order_model.dart';
import 'package:piv_app/data/models/commission_model.dart';

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

  // --- THÊM PHƯƠNG THỨC MỚI ---
  /// Lấy tất cả các bản ghi hoa hồng.
  Future<Either<Failure, List<CommissionModel>>> getAllCommissions();

  /// Cập nhật trạng thái của một bản ghi hoa hồng.
  Future<Either<Failure, Unit>> updateCommissionStatus(String commissionId, String newStatus, String accountantId);

  /// Lấy tất cả hoa hồng của một NVKD cụ thể.
  Future<Either<Failure, List<CommissionModel>>> getCommissionsBySalesRepId(String salesRepId);
}
