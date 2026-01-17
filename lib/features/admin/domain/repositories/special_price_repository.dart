import 'package:piv_app/data/models/special_price_model.dart';

abstract class SpecialPriceRepository {
  Future<List<SpecialPriceModel>> getSpecialPrices(String userId);
  Future<void> setSpecialPrice(String userId, String productId, double price, String adminId);
  Future<void> removeSpecialPrice(String userId, String productId);
  Future<void> toggleUseGeneralPrice(String userId, bool useGeneralPrice);
  Stream<bool> watchUseGeneralPrice(String userId);
}
