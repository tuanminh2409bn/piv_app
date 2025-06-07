import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:piv_app/core/error/failure.dart';
import 'package:piv_app/data/models/cart_item_model.dart';
import 'package:piv_app/features/home/data/models/product_model.dart';
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
    required ProductModel product,
    required int quantity,
  }) async {
    try {
      final cartRef = _userCartRef(userId);

      // Sử dụng transaction để đảm bảo an toàn khi đọc và ghi
      await _firestore.runTransaction((transaction) async {
        final cartSnapshot = await transaction.get(cartRef);

        if (!cartSnapshot.exists) {
          // Nếu giỏ hàng chưa tồn tại, tạo mới
          final newItem = CartItemModel(
            productId: product.id,
            productName: product.name,
            imageUrl: product.imageUrls.isNotEmpty ? product.imageUrls.first : '',
            price: product.displayPrice,
            unit: product.unit,
            quantity: quantity,
          );
          transaction.set(cartRef, {
            'items': [newItem.toMap()],
            'lastUpdated': FieldValue.serverTimestamp(),
          });
          return;
        }

        // Nếu giỏ hàng đã tồn tại
        final data = cartSnapshot.data() ?? {};
        final List<dynamic> items = List<dynamic>.from(data['items'] ?? []);

        // Tìm xem sản phẩm đã có trong giỏ chưa
        final int itemIndex = items.indexWhere((item) => item['productId'] == product.id);

        if (itemIndex != -1) {
          // Nếu đã có, cập nhật số lượng
          final currentItem = items[itemIndex];
          currentItem['quantity'] += quantity;
          items[itemIndex] = currentItem;
        } else {
          // Nếu chưa có, thêm sản phẩm mới
          final newItem = CartItemModel(
            productId: product.id,
            productName: product.name,
            imageUrl: product.imageUrls.isNotEmpty ? product.imageUrls.first : '',
            price: product.displayPrice,
            unit: product.unit,
            quantity: quantity,
          );
          items.add(newItem.toMap());
        }

        // Cập nhật lại toàn bộ giỏ hàng
        transaction.update(cartRef, {
          'items': items,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      });

      developer.log('Added/Updated product ${product.id} for user $userId', name: 'CartRepository');
      return const Right(unit);

    } on FirebaseException catch (e) {
      developer.log('FirebaseException in addProductToCart: ${e.message}', name: 'CartRepository');
      return Left(ServerFailure('Lỗi Firebase: ${e.message}'));
    } catch (e) {
      developer.log('Unknown error in addProductToCart: ${e.toString()}', name: 'CartRepository');
      return Left(ServerFailure('Lỗi không xác định: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<CartItemModel>>> getCart(String userId) async {
    try {
      final docSnapshot = await _userCartRef(userId).get();
      if (docSnapshot.exists && docSnapshot.data() != null) {
        final data = docSnapshot.data()!;
        final List<dynamic> items = data['items'] ?? [];
        final cartItems = items
            .map((item) => CartItemModel.fromMap(item as Map<String, dynamic>))
            .toList();
        return Right(cartItems);
      } else {
        // Nếu giỏ hàng không tồn tại, trả về danh sách rỗng
        return const Right([]);
      }
    } on FirebaseException catch (e) {
      return Left(ServerFailure('Lỗi Firebase: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateProductQuantity({
    required String userId,
    required String productId,
    required int newQuantity,
  }) async {
    try {
      if (newQuantity <= 0) {
        // Nếu số lượng mới <= 0, xóa sản phẩm khỏi giỏ hàng
        return await removeProductFromCart(userId: userId, productId: productId);
      }

      final cartRef = _userCartRef(userId);
      await _firestore.runTransaction((transaction) async {
        final cartSnapshot = await transaction.get(cartRef);
        if (!cartSnapshot.exists) {
          throw Exception("Giỏ hàng không tồn tại để cập nhật.");
        }

        final List<dynamic> items = List<dynamic>.from(cartSnapshot.data()!['items'] ?? []);
        final int itemIndex = items.indexWhere((item) => item['productId'] == productId);

        if (itemIndex != -1) {
          items[itemIndex]['quantity'] = newQuantity;
          transaction.update(cartRef, {
            'items': items,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        } else {
          throw Exception("Sản phẩm không có trong giỏ hàng.");
        }
      });
      return const Right(unit);
    } on FirebaseException catch (e) {
      return Left(ServerFailure('Lỗi Firebase: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định: ${e.toString()}'));
    }
  }


  @override
  Future<Either<Failure, Unit>> removeProductFromCart({
    required String userId,
    required String productId,
  }) async {
    try {
      final cartRef = _userCartRef(userId);
      await _firestore.runTransaction((transaction) async {
        final cartSnapshot = await transaction.get(cartRef);
        if (!cartSnapshot.exists) {
          return; // Không có gì để xóa
        }

        final List<dynamic> items = List<dynamic>.from(cartSnapshot.data()!['items'] ?? []);
        items.removeWhere((item) => item['productId'] == productId);

        transaction.update(cartRef, {
          'items': items,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      });
      return const Right(unit);
    } on FirebaseException catch (e) {
      return Left(ServerFailure('Lỗi Firebase: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Unit>> clearCart(String userId) async {
    try {
      await _userCartRef(userId).update({
        'items': [],
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      return const Right(unit);
    } on FirebaseException catch (e) {
      return Left(ServerFailure('Lỗi Firebase: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định: ${e.toString()}'));
    }
  }
}
