// lib/features/profile/data/repositories/user_profile_repository_impl.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:piv_app/core/error/failure.dart';
import 'package:piv_app/data/models/user_model.dart';
import 'package:piv_app/data/models/address_model.dart';
import 'package:piv_app/features/profile/domain/repositories/user_profile_repository.dart';
import 'dart:developer' as developer;
import 'package:cloud_functions/cloud_functions.dart';

class UserProfileRepositoryImpl implements UserProfileRepository {
  final FirebaseFirestore _firestore;

  UserProfileRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersCollection => _firestore.collection('users');

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

  @override
  Future<Either<Failure, Unit>> updateUserProfilePartial(String userId, Map<String, dynamic> data) async {
    try {
      // Thêm trường updatedAt để luôn ghi lại thời gian cập nhật
      final dataToUpdate = {...data, 'updatedAt': FieldValue.serverTimestamp()};
      await _usersCollection.doc(userId).update(dataToUpdate);
      developer.log('Partially updated profile for user $userId with data: $dataToUpdate', name: 'UserProfileRepo');
      return const Right(unit);
    } on FirebaseException catch (e) {
      return Left(ServerFailure('Lỗi Firebase khi cập nhật một phần hồ sơ: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định khi cập nhật một phần hồ sơ: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> approveAgentWithRole({
    required String agentId,
    required String roleToSet,
  }) async {
    try {
      final functions = FirebaseFunctions.instanceFor(region: 'asia-southeast1');
      final callable = functions.httpsCallable('approveAgentBySalesRep');

      await callable.call<Map<String, dynamic>>({
        'agentId': agentId,
        'roleToSet': roleToSet,
      });
      return const Right(null);
    } on FirebaseFunctionsException catch (e) {
      return Left(ServerFailure(e.message ?? 'Lỗi từ server.'));
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<UserModel>>> getUsersByIds(List<String> userIds) async {
    if (userIds.isEmpty) {
      return const Right([]);
    }
    try {
      final List<UserModel> result = [];
      for (var i = 0; i < userIds.length; i += 30) {
        final sublist = userIds.sublist(i, i + 30 > userIds.length ? userIds.length : i + 30);
        final querySnapshot = await _usersCollection.where('id', whereIn: sublist).get();
        final users = querySnapshot.docs.map((doc) => UserModel.fromJson(doc.data())).toList();
        result.addAll(users);
      }

      developer.log('Fetched details for ${result.length} users.', name: 'UserProfileRepo');
      return Right(result);
    } on FirebaseException catch (e) {
      return Left(ServerFailure('Lỗi Firebase khi tải danh sách người dùng: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định khi tải danh sách người dùng: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<UserModel>>> getAllAgents() async {
    try {
      final querySnapshot = await _usersCollection
          .where('role', whereIn: ['agent_1', 'agent_2'])
          .where('status', isEqualTo: 'active')
          .get();
      final users = querySnapshot.docs.map((doc) => UserModel.fromJson(doc.data())).toList();
      return Right(users);
    } on FirebaseException catch (e) {
      return Left(ServerFailure('Lỗi Firebase: ${e.message}'));
    }
  }

  @override
  Stream<int> watchSpinCount(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) {
        return 0;
      }
      // Trích xuất và trả về chỉ số spinCount
      return (snap.data()!['spinCount'] as int?) ?? 0;
    });
  }

  @override
  Future<Either<Failure, Unit>> deleteAccount() async {
    try {
      // Khởi tạo Cloud Functions và trỏ đến đúng region của bạn
      final functions = FirebaseFunctions.instanceFor(region: 'asia-southeast1');
      // Lấy function có tên 'deleteUserAccount'
      final callable = functions.httpsCallable('deleteUserAccount');

      // Gọi function. Không cần truyền tham số vì UID được lấy từ context ở backend.
      await callable.call();

      // Thành công! Stream trong AuthBloc sẽ tự động phát hiện người dùng bị xóa
      // và cập nhật trạng thái ứng dụng về Unauthenticated.
      developer.log('Successfully triggered deleteUserAccount cloud function.', name: 'UserProfileRepo');
      return const Right(unit);

    } on FirebaseFunctionsException catch (e) {
      // Xử lý các lỗi trả về từ Cloud Function
      developer.log('Cloud Function error on deleteAccount: ${e.code} - ${e.message}', name: 'UserProfileRepo');
      // Trả về thông báo lỗi thân thiện cho người dùng
      return Left(ServerFailure(e.message ?? 'Không thể xóa tài khoản. Vui lòng thử lại sau.'));
    } catch (e) {
      // Xử lý các lỗi khác (ví dụ: mất kết nối mạng)
      developer.log('Unknown error on deleteAccount: $e', name: 'UserProfileRepo');
      return Left(ServerFailure('Đã có lỗi không xác định xảy ra. Vui lòng kiểm tra kết nối mạng.'));
    }
  }
}