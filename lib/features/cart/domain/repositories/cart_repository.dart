import 'package:dartz/dartz.dart';
import 'package:piv_app/core/error/failure.dart';
import 'package:piv_app/data/models/cart_item_model.dart';
import 'package:piv_app/features/home/data/models/product_model.dart';

abstract class CartRepository {
  Future<Either<Failure, List<CartItemModel>>> getCart(String userId);

  // ** QUAY LẠI PHƯƠNG THỨC CŨ, KHÔNG CÓ variant **
  Future<Either<Failure, Unit>> addProductToCart({
    required String userId,
    required ProductModel product,
    required int quantity,
  });

  Future<Either<Failure, Unit>> removeProductFromCart({
    required String userId,
    required String productId,
  });

  Future<Either<Failure, Unit>> updateProductQuantity({
    required String userId,
    required String productId,
    required int newQuantity,
  });

  Future<Either<Failure, Unit>> clearCart(String userId);
}
