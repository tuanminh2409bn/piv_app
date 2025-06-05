import 'package:firebase_auth/firebase_auth.dart' as firebase_auth; // Alias để tránh trùng tên
import 'package:piv_app/data/models/user_model.dart'; // Đường dẫn tới UserModel
import 'package:dartz/dartz.dart'; // Cho Either
import 'package:piv_app/core/error/failure.dart'; // Sẽ tạo file này sau

// Định nghĩa các phương thức mà AuthRepository phải implement
abstract class AuthRepository {
  // Theo dõi trạng thái đăng nhập của người dùng
  // Trả về một Stream của UserModel. Khi người dùng đăng nhập, stream sẽ phát ra UserModel.
  // Khi đăng xuất, stream sẽ phát ra UserModel.empty.
  Stream<UserModel> get user;

  // Lấy UserModel hiện tại (nếu có)
  // Có thể hữu ích trong một số trường hợp không muốn lắng nghe stream
  Future<Either<Failure, UserModel>> getCurrentUser();

  // Đăng ký bằng email và mật khẩu
  // Trả về Right(Unit) nếu thành công, Left(Failure) nếu thất bại
  // Unit là một kiểu từ dartz, biểu thị một hàm không trả về giá trị gì (void) nhưng thành công
  Future<Either<Failure, Unit>> signUp({
    required String email,
    required String password,
    String? displayName, // Tùy chọn: tên hiển thị khi đăng ký
  });

  // Đăng nhập bằng email và mật khẩu
  Future<Either<Failure, Unit>> logInWithEmailAndPassword({
    required String email,
    required String password,
  });

  // Đăng xuất
  Future<Either<Failure, Unit>> logOut();

  // (Tùy chọn) Gửi email xác thực
  Future<Either<Failure, Unit>> sendEmailVerification();

  // (Tùy chọn) Đặt lại mật khẩu
  Future<Either<Failure, Unit>> sendPasswordResetEmail({required String email});
}
