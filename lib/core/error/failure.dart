import 'package:equatable/equatable.dart';

// Lớp cơ sở cho tất cả các lỗi trong ứng dụng
abstract class Failure extends Equatable {
  final String message;
  final int? statusCode; // Mã lỗi HTTP hoặc mã lỗi tùy chỉnh

  const Failure(this.message, {this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}

// Lỗi chung từ server hoặc một nguồn dữ liệu không xác định
class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.statusCode});
}

// Lỗi khi không có kết nối mạng
class NetworkFailure extends Failure {
  const NetworkFailure(super.message) : super(statusCode: null); // Mạng không có status code cụ thể
}

// Lỗi từ Firebase Authentication
class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.statusCode}) : super();
}

// Lỗi khi cache dữ liệu (nếu có)
class CacheFailure extends Failure {
  const CacheFailure(super.message) : super(statusCode: null);
}

// Bạn có thể thêm các loại Failure cụ thể khác nếu cần
