import 'package:piv_app/data/models/price_request_model.dart';
import 'package:piv_app/data/models/special_price_model.dart';

abstract class SpecialPriceRepository {
  Future<List<SpecialPriceModel>> getSpecialPrices(String userId);
  Future<void> setSpecialPrice(String userId, String productId, double price, String adminId);
  Future<void> removeSpecialPrice(String userId, String productId);
  Future<void> toggleUseGeneralPrice(String userId, bool useGeneralPrice);
  Stream<bool> watchUseGeneralPrice(String userId);

  // --- Price Approval Flow ---
  Future<void> createPriceRequest(PriceRequestModel request);
  Stream<List<PriceRequestModel>> watchPendingRequests();
  Stream<PriceRequestModel?> watchPendingRequestForAgent(String agentId); // Mới
  Future<void> approveRequest(PriceRequestModel request, String adminId);
  Future<void> rejectRequest(String requestId, String reason);
  Future<void> cancelRequest(String requestId); // Mới
}
