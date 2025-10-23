//lib/features/orders/domain/repositories/order_repository.dart

import 'package:dartz/dartz.dart';
import 'package:piv_app/core/error/failure.dart';
import 'package:piv_app/data/models/commission_model.dart';
import 'package:piv_app/data/models/order_model.dart';
import 'package:piv_app/data/models/payment_info_model.dart';


abstract class OrderRepository {
  Future<Either<Failure, List<OrderModel>>> getUserOrders(String userId);
  Future<Either<Failure, OrderModel>> getOrderById(String orderId);
  Stream<OrderModel> getOrderStreamById(String orderId);
  Future<Either<Failure, List<OrderModel>>> getAllOrders();
  Future<Either<Failure, Unit>> updateOrderStatus(String orderId, String newStatus);
  Future<Either<Failure, Unit>> createCommission(CommissionModel commission);
  Future<Either<Failure, List<CommissionModel>>> getAllCommissions({DateTime? startDate, DateTime? endDate});
  Future<Either<Failure, Unit>> updateCommissionStatus(String commissionId, String newStatus, String confirmedById);
  Future<Either<Failure, List<CommissionModel>>> getCommissionsBySalesRepId(String salesRepId, {DateTime? startDate, DateTime? endDate});
  Future<Either<Failure, List<OrderModel>>> getOrdersForSalesRepByAgent({required String salesRepId, required String agentId});
  Future<Either<Failure, Unit>> approveOrder(String orderId, {required double paidAmount, required double voucherDiscount, String? appliedVoucherCode});
  Future<Either<Failure, Unit>> rejectOrder({required String orderId, required String reason});
  Future<Either<Failure, Unit>> confirmOrderPayment(String orderId);
  Future<Either<Failure, PaymentInfoModel>> getPaymentInfo();
  Future<Either<Failure, Unit>> notifyPaymentMade(String orderId);
  Future<Either<Failure, Unit>> updateOrderStatusToShipped(String orderId, DateTime shippingDate);
  Future<Either<Failure, String>> createOrder(OrderModel order, {bool clearCart = true});
  Stream<List<OrderModel>> watchUserOrders(String userId);
}