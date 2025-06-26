import 'package:dartz/dartz.dart';
import 'package:piv_app/core/error/failure.dart';
import 'package:piv_app/data/models/commission_model.dart';
import 'package:piv_app/data/models/order_model.dart';

abstract class OrderRepository {
  Future<Either<Failure, List<OrderModel>>> getUserOrders(String userId);
  Future<Either<Failure, String>> createOrder(OrderModel order);
  Future<Either<Failure, OrderModel>> getOrderById(String orderId);
  Future<Either<Failure, List<OrderModel>>> getAllOrders();
  Future<Either<Failure, Unit>> updateOrderStatus(String orderId, String newStatus);
  Future<Either<Failure, Unit>> createCommission(CommissionModel commission);
  Future<Either<Failure, List<CommissionModel>>> getAllCommissions();
  Future<Either<Failure, Unit>> updateCommissionStatus(String commissionId, String newStatus, String confirmedById);
  Future<Either<Failure, List<CommissionModel>>> getCommissionsBySalesRepId(String salesRepId);
}
