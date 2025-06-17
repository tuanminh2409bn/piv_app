// lib/features/cart/domain/repositories/cart_repository.dart

import 'package:dartz/dartz.dart';
import 'package:piv_app/core/error/failure.dart';
import 'package:piv_app/data/models/cart_item_model.dart';

abstract class CartRepository {
  /// Lấy các sản phẩm trong giỏ hàng của người dùng
  Future<Either<Failure, List<CartItemModel>>> getCart(String userId);

  /// Thêm một sản phẩm vào giỏ hàng.
  /// Nếu sản phẩm với cùng quy cách đã tồn tại, cập nhật số lượng.
  Future<Either<Failure, Unit>> addProductToCart({
    required String userId,
    required CartItemModel item, // Sửa: Chỉ nhận vào một CartItemModel hoàn chỉnh
  });

  /// Xóa một sản phẩm khỏi giỏ hàng
  Future<Either<Failure, Unit>> removeProductFromCart({
    required String userId,
    required String productId,
    required String caseUnitName, // Cần caseUnitName để xóa đúng quy cách
  });

  /// Cập nhật số lượng của một sản phẩm trong giỏ hàng
  Future<Either<Failure, Unit>> updateProductQuantity({
    required String userId,
    required String productId,
    required String caseUnitName, // Cần caseUnitName để cập nhật đúng quy cách
    required int newQuantity,
  });

  /// Xóa toàn bộ giỏ hàng
  Future<Either<Failure, Unit>> clearCart(String userId);
}