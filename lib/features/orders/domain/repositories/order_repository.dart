import 'package:dartz/dartz.dart';
import 'package:piv_app/core/error/failure.dart';
import 'package:piv_app/data/models/commission_model.dart';
import 'package:piv_app/data/models/order_model.dart';

abstract class OrderRepository {
  Future<Either<Failure, List<OrderModel>>> getUserOrders(String userId);
  Future<Either<Failure, String>> createOrder(OrderModel order);
  Future<Either<Failure, OrderModel>> getOrderById(String orderId);
  Stream<OrderModel> getOrderStreamById(String orderId); // Giữ nguyên từ lần sửa trước
  Future<Either<Failure, List<OrderModel>>> getAllOrders();
  Future<Either<Failure, Unit>> updateOrderStatus(String orderId, String newStatus);
  Future<Either<Failure, Unit>> createCommission(CommissionModel commission);
  Future<Either<Failure, List<CommissionModel>>> getAllCommissions({DateTime? startDate, DateTime? endDate});
  Future<Either<Failure, Unit>> updateCommissionStatus(String commissionId, String newStatus, String confirmedById);
  Future<Either<Failure, List<CommissionModel>>> getCommissionsBySalesRepId(String salesRepId, {DateTime? startDate, DateTime? endDate});

  // <<< THÊM HÀM MỚI NÀY >>>
  Future<Either<Failure, List<OrderModel>>> getOrdersForSalesRepByAgent({
    required String salesRepId,
    required String agentId,
  });
}