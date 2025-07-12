// lib/features/profile/data/repositories/user_profile_repository_impl.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:piv_app/core/error/failure.dart';
import 'package:piv_app/data/models/user_model.dart';
import 'package:piv_app/data/models/address_model.dart';
import 'package:piv_app/features/profile/domain/repositories/user_profile_repository.dart';
import 'dart:developer' as developer;

class UserProfileRepositoryImpl implements UserProfileRepository {
  final FirebaseFirestore _firestore;

  UserProfileRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersCollection => _firestore.collection('users');

  // ... các hàm getUserProfile, updateUserProfile, và các hàm address giữ nguyên ...

  // --- HÀM NÀY SẼ ĐƯỢC CẬP NHẬT HOÀN TOÀN ---
  @override
  Future<Either<Failure, Unit>> submitReferralCode(String userId, String referralCode) async {
    try {
      final referrerDoc = await _usersCollection.doc(referralCode).get();
      if (!referrerDoc.exists) {
        return Left(ServerFailure('Mã giới thiệu không hợp lệ.'));
      }

      // --- LOGIC MỚI QUAN TRỌNG ---
      final referrerData = UserModel.fromJson(referrerDoc.data()!);
      final Map<String, dynamic> dataToUpdate = {
        'referrerId': referralCode,
        'referralPromptPending': false,
      };

      // Chỉ cập nhật salesRepId nếu người giới thiệu là NVKD
      if (referrerData.isSalesRep) {
        dataToUpdate['salesRepId'] = referralCode;
      }
      // -----------------------------

      await _usersCollection.doc(userId).update(dataToUpdate);

      developer.log('User $userId submitted referral code. Data updated: $dataToUpdate', name: 'UserProfileRepo');

      return const Right(unit);
    } on FirebaseException catch (e) {
      return Left(ServerFailure('Lỗi Firebase: ${e.message}'));
    }
    catch (e) {
      return Left(ServerFailure('Lỗi không xác định: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Unit>> dismissReferralPrompt(String userId) async {
    try {
      await _usersCollection.doc(userId).update({'referralPromptPending': false});
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định: ${e.toString()}'));
    }
  }

  // --- CÁC HÀM CÒN LẠI GIỮ NGUYÊN ---
  @override
  Future<Either<Failure, UserModel>> getUserProfile(String userId) async {
    try {
      final docSnapshot = await _usersCollection.doc(userId).get();
      if (docSnapshot.exists && docSnapshot.data() != null) {
        final user = UserModel.fromJson(docSnapshot.data()!);
        developer.log('Fetched profile for user: ${user.id}', name: 'UserProfileRepo');
        return Right(user);
      } else {
        return Left(ServerFailure('Không tìm thấy hồ sơ người dùng.'));
      }
    } on FirebaseException catch (e) {
      return Left(ServerFailure('Lỗi Firebase khi tải hồ sơ: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định khi tải hồ sơ: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateUserProfile(UserModel user) async {
    try {
      await _usersCollection.doc(user.id).update(user.toJson());
      developer.log('Updated profile for user: ${user.id}', name: 'UserProfileRepo');
      return const Right(unit);
    } on FirebaseException catch (e) {
      return Left(ServerFailure('Lỗi Firebase khi cập nhật hồ sơ: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định khi cập nhật hồ sơ: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Unit>> addAddress(String userId, AddressModel address) async {
    try {
      await _usersCollection.doc(userId).update({
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

  @override
  Future<Either<Failure, Unit>> addToWishlist(String userId, String productId) async {
    try {
      await _usersCollection.doc(userId).update({
        'wishlist': FieldValue.arrayUnion([productId])
      });
      developer.log('Added product $productId to wishlist for user $userId', name: 'UserProfileRepo');
      return const Right(unit);
    } on FirebaseException catch (e) {
      return Left(ServerFailure('Lỗi khi thêm vào danh sách yêu thích: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Unit>> removeFromWishlist(String userId, String productId) async {
    try {
      await _usersCollection.doc(userId).update({
        'wishlist': FieldValue.arrayRemove([productId])
      });
      developer.log('Removed product $productId from wishlist for user $userId', name: 'UserProfileRepo');
      return const Right(unit);
    } on FirebaseException catch (e) {
      return Left(ServerFailure('Lỗi khi xóa khỏi danh sách yêu thích: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<UserModel>>> getUnassignedAgents() async {
    try {
      // SỬA LẠI TRUY VẤN: Lấy các đại lý có trạng thái chờ duyệt
      final querySnapshot = await _usersCollection
          .where('status', isEqualTo: 'pending_approval')
          .get();

      final users = querySnapshot.docs
          .map((doc) => UserModel.fromJson(doc.data()! as Map<String, dynamic>)) // Chắc chắn rằng doc.data() không null
          .toList();

      developer.log('Fetched ${users.length} unassigned agents.', name: 'UserProfileRepo');
      return Right(users);

    } on FirebaseException catch (e) {
      return Left(ServerFailure('Lỗi Firebase khi tải danh sách đại lý: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định khi tải danh sách đại lý: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Unit>> assignAgentToSalesRep({required String agentId, required String salesRepId}) async {
    try {
      // SỬA LẠI CẬP NHẬT: Gán salesRepId, referrerId, đổi status và tắt cờ mời nhập mã
      await _usersCollection.doc(agentId).update({
        'salesRepId': salesRepId,
        'referrerId': salesRepId,
        'status': 'active',
        'referralPromptPending': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      developer.log('Assigned, referred, and set referral prompt to false for agent $agentId by sales rep $salesRepId', name: 'UserProfileRepo');
      return const Right(unit);
    } on FirebaseException catch (e) {
      return Left(ServerFailure('Lỗi Firebase khi duyệt đại lý: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định khi duyệt đại lý: ${e.toString()}'));
    }
  }
}