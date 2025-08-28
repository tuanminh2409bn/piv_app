// lib/features/cart/data/repositories/cart_repository_impl.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:piv_app/core/error/failure.dart';
import 'package:piv_app/data/models/cart_item_model.dart';
import 'package:piv_app/features/cart/domain/repositories/cart_repository.dart';
import 'dart:developer' as developer;

class CartRepositoryImpl implements CartRepository {
  final FirebaseFirestore _firestore;

  CartRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _userCartRef(String userId) =>
      _firestore.collection('carts').doc(userId);

  @override
  Future<Either<Failure, Unit>> addProductToCart({
    required String userId,
    required CartItemModel item,
  }) async {
    try {
      final cartRef = _userCartRef(userId);
      await _firestore.runTransaction((transaction) async {
        final cartSnapshot = await transaction.get(cartRef);
        final newItemMap = item.toMap();

        if (!cartSnapshot.exists) {
          transaction.set(cartRef, {
            'items': [newItemMap],
            'lastUpdated': FieldValue.serverTimestamp(),
          });
          return;
        }

        final data = cartSnapshot.data() ?? {};
        final List<dynamic> items = List<dynamic>.from(data['items'] ?? []);
        final int itemIndex = items.indexWhere((i) =>
        i['productId'] == item.productId && i['caseUnitName'] == item.caseUnitName);

        if (itemIndex != -1) {
          final currentItem = items[itemIndex];
          currentItem['quantity'] += item.quantity;
          items[itemIndex] = currentItem;
        } else {
          items.add(newItemMap);
        }

        transaction.update(cartRef, {
          'items': items,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      });
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định khi thêm vào giỏ hàng: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<CartItemModel>>> getCart(String userId) async {
    try {
      final docSnapshot = await _userCartRef(userId).get();
      if (docSnapshot.exists && docSnapshot.data() != null) {
        final data = docSnapshot.data()!;
        final List<dynamic> items = data['items'] ?? [];
        return Right(items.map((item) => CartItemModel.fromMap(item as Map<String, dynamic>)).toList());
      }
      return const Right([]);
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định khi tải giỏ hàng: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateProductQuantity({
    required String userId,
    required String productId,
    required String caseUnitName,
    required int newQuantity,
  }) async {
    try {
      if (newQuantity <= 0) {
        return await removeProductFromCart(userId: userId, productId: productId, caseUnitName: caseUnitName);
      }
      final cartRef = _userCartRef(userId);
      await _firestore.runTransaction((transaction) async {
        final cartSnapshot = await transaction.get(cartRef);
        if (!cartSnapshot.exists) throw Exception("Giỏ hàng không tồn tại.");

        final List<dynamic> items = List.from(cartSnapshot.data()!['items'] ?? []);
        final int itemIndex = items.indexWhere((i) => i['productId'] == productId && i['caseUnitName'] == caseUnitName);

        if (itemIndex != -1) {
          items[itemIndex]['quantity'] = newQuantity;
          transaction.update(cartRef, {'items': items});
        }
      });
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định khi cập nhật số lượng: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Unit>> removeProductFromCart({
    required String userId,
    required String productId,
    required String caseUnitName,
  }) async {
    try {
      final cartRef = _userCartRef(userId);
      await _firestore.runTransaction((transaction) async {
        final cartSnapshot = await transaction.get(cartRef);
        if (!cartSnapshot.exists) return;

        final List<dynamic> items = List.from(cartSnapshot.data()!['items'] ?? []);
        final itemToRemove = items.firstWhere((i) => i['productId'] == productId && i['caseUnitName'] == caseUnitName, orElse: () => null);

        if (itemToRemove != null) {
          transaction.update(cartRef, {'items': FieldValue.arrayRemove([itemToRemove])});
        }
      });
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định khi xóa sản phẩm: ${e.toString()}'));
    }
  }

  // ======================== LOGIC ĐÃ SỬA LỖI ========================
  @override
  Future<Either<Failure, Unit>> clearCart(String userId) async {
    try {
      // SỬA: Dùng .delete() thay vì .update() để tránh lỗi khi document không tồn tại.
      await _userCartRef(userId).delete();
      return const Right(unit);
    } catch (e) {
      developer.log('Lỗi khi xóa giỏ hàng: ${e.toString()}', name: 'CartRepository');
      return Left(ServerFailure('Lỗi không xác định khi xóa giỏ hàng: ${e.toString()}'));
    }
  }
// ================================================================
}