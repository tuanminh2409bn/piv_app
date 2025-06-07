import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:piv_app/core/error/failure.dart';
import 'package:piv_app/data/models/user_model.dart';
import 'package:piv_app/data/models/address_model.dart'; // Import AddressModel
import 'package:piv_app/features/profile/domain/repositories/user_profile_repository.dart';
import 'dart:developer' as developer;

class UserProfileRepositoryImpl implements UserProfileRepository {
  final FirebaseFirestore _firestore;

  UserProfileRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersCollection => _firestore.collection('users');

  @override
  // Thêm 'async'
  Future<Either<Failure, UserModel>> getUserProfile(String userId) async {
    try {
      // Thêm 'await'
      final docSnapshot = await _usersCollection.doc(userId).get();
      if (docSnapshot.exists && docSnapshot.data() != null) {
        final user = UserModel.fromJson(docSnapshot.data()!);
        return Right(user);
      } else {
        return Left(ServerFailure('Không tìm thấy hồ sơ người dùng.'));
      }
    } on FirebaseException catch (e) {
      return Left(ServerFailure('Lỗi Firebase: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định khi tải hồ sơ: ${e.toString()}'));
    }
  }

  @override
  // Thêm 'async'
  Future<Either<Failure, Unit>> updateUserProfile(UserModel user) async {
    try {
      // Thêm 'await'
      await _usersCollection.doc(user.id).update(user.toJson());
      return const Right(unit);
    } on FirebaseException catch (e) {
      return Left(ServerFailure('Lỗi Firebase khi cập nhật hồ sơ: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định khi cập nhật hồ sơ: ${e.toString()}'));
    }
  }

  // --- CÁC PHƯƠNG THỨC ĐỊA CHỈ (ĐÃ ĐÚNG TỪ TRƯỚC) ---

  @override
  Future<Either<Failure, Unit>> addAddress(String userId, AddressModel address) async {
    try {
      final userRef = _usersCollection.doc(userId);
      await userRef.update({
        'addresses': FieldValue.arrayUnion([address.toMap()])
      });
      developer.log('Added new address for user $userId', name: 'UserProfileRepo');
      return const Right(unit);
    } on FirebaseException catch (e) {
      return Left(ServerFailure('Lỗi Firebase khi thêm địa chỉ: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định khi thêm địa chỉ: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateAddress(String userId, AddressModel address) async {
    try {
      final userRef = _usersCollection.doc(userId);
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);
        if (!snapshot.exists) {
          throw Exception("User does not exist!");
        }
        final List<dynamic> addressesList = List<dynamic>.from(snapshot.data()?['addresses'] ?? []);
        final index = addressesList.indexWhere((a) => a['id'] == address.id);
        if (index != -1) {
          addressesList[index] = address.toMap();
          transaction.update(userRef, {'addresses': addressesList});
        }
      });
      developer.log('Updated address ${address.id} for user $userId', name: 'UserProfileRepo');
      return const Right(unit);
    } on FirebaseException catch (e) {
      return Left(ServerFailure('Lỗi Firebase khi cập nhật địa chỉ: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định khi cập nhật địa chỉ: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteAddress(String userId, String addressId) async {
    try {
      final userRef = _usersCollection.doc(userId);
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);
        if (!snapshot.exists) {
          throw Exception("User does not exist!");
        }
        final List<dynamic> addressesList = List<dynamic>.from(snapshot.data()?['addresses'] ?? []);
        final addressToRemove = addressesList.firstWhere((a) => a['id'] == addressId, orElse: () => null);
        if (addressToRemove != null) {
          transaction.update(userRef, {
            'addresses': FieldValue.arrayRemove([addressToRemove])
          });
        }
      });
      developer.log('Deleted address $addressId for user $userId', name: 'UserProfileRepo');
      return const Right(unit);
    } on FirebaseException catch (e) {
      return Left(ServerFailure('Lỗi Firebase khi xóa địa chỉ: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định khi xóa địa chỉ: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Unit>> setDefaultAddress(String userId, String addressId) async {
    try {
      final userRef = _usersCollection.doc(userId);
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);
        if (!snapshot.exists) {
          throw Exception("User does not exist!");
        }
        final List<dynamic> addressesList = List<dynamic>.from(snapshot.data()?['addresses'] ?? []);
        final updatedList = addressesList.map((addr) {
          final newAddr = Map<String, dynamic>.from(addr);
          newAddr['isDefault'] = (newAddr['id'] == addressId);
          return newAddr;
        }).toList();

        transaction.update(userRef, {'addresses': updatedList});
      });
      developer.log('Set default address $addressId for user $userId', name: 'UserProfileRepo');
      return const Right(unit);
    } on FirebaseException catch (e) {
      return Left(ServerFailure('Lỗi Firebase khi đặt địa chỉ mặc định: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định khi đặt địa chỉ mặc định: ${e.toString()}'));
    }
  }
}
