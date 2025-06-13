import 'package:dartz/dartz.dart';
import 'package:piv_app/core/error/failure.dart';
import 'package:piv_app/data/models/user_model.dart';

abstract class AuthRepository {
  /// Stream để theo dõi trạng thái xác thực của người dùng.
  Stream<UserModel> get user;

  /// Lấy thông tin người dùng hiện tại (nếu có).
  Future<Either<Failure, UserModel>> getCurrentUser();

  /// Đăng ký bằng email và mật khẩu.
  Future<Either<Failure, Unit>> signUp({
    required String email,
    required String password,
    String? displayName,
  });

  /// Đăng nhập bằng email và mật khẩu.
  Future<Either<Failure, Unit>> logInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Đăng xuất.
  Future<Either<Failure, Unit>> logOut();

  /// Gửi email xác thực.
  Future<Either<Failure, Unit>> sendEmailVerification();

  /// Gửi email đặt lại mật khẩu.
  Future<Either<Failure, Unit>> sendPasswordResetEmail({required String email});

  /// Đăng nhập bằng tài khoản Google.
  Future<Either<Failure, Unit>> signInWithGoogle();

  /// Đăng nhập bằng tài khoản Facebook.
  Future<Either<Failure, Unit>> signInWithFacebook();
}
