import 'package:dartz/dartz.dart';
import 'package:piv_app/core/error/failure.dart';
import 'package:piv_app/data/models/user_model.dart';
import 'package:piv_app/data/models/address_model.dart';

abstract class UserProfileRepository {
  /// Lấy thông tin hồ sơ của người dùng dựa trên userId từ Firestore.
  Future<Either<Failure, UserModel>> getUserProfile(String userId);

  /// Cập nhật thông tin hồ sơ người dùng trên Firestore.
  Future<Either<Failure, Unit>> updateUserProfile(UserModel user);

  /// Thêm một địa chỉ mới cho người dùng.
  Future<Either<Failure, Unit>> addAddress(String userId, AddressModel address);

  /// Cập nhật một địa chỉ đã có.
  Future<Either<Failure, Unit>> updateAddress(String userId, AddressModel address);

  /// Xóa một địa chỉ.
  Future<Either<Failure, Unit>> deleteAddress(String userId, String addressId);

  /// Đặt một địa chỉ làm địa chỉ mặc định.
  Future<Either<Failure, Unit>> setDefaultAddress(String userId, String addressId);

  // ** PHƯƠNG THỨC MỚI **
  /// Gửi mã giới thiệu, kiểm tra và cập nhật thông tin người dùng.
  Future<Either<Failure, Unit>> submitReferralCode(String userId, String referralCode);

  // ** PHƯƠNG THỨC MỚI **
  /// Bỏ qua lời nhắc nhập mã giới thiệu.
  Future<Either<Failure, Unit>> dismissReferralPrompt(String userId);

  // --- TÍNH NĂNG MỚI: Các hàm cho Wishlist ---
  /// Thêm một productId vào danh sách yêu thích của người dùng.
  Future<Either<Failure, Unit>> addToWishlist(String userId, String productId);

  /// Xóa một productId khỏi danh sách yêu thích của người dùng.
  Future<Either<Failure, Unit>> removeFromWishlist(String userId, String productId);
}
