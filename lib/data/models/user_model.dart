import 'package:equatable/equatable.dart';

// Lớp UserModel đại diện cho thông tin người dùng trong ứng dụng
class UserModel extends Equatable {
  final String id; // Sẽ là UID từ Firebase Auth
  final String? email;
  final String? displayName;
  final String? photoUrl;
  // Thêm các trường khác bạn cần cho người dùng ở đây, ví dụ:
  // final String? phoneNumber;
  // final List<String>? roles; // Ví dụ: ['customer', 'agent_level_1']
  // final DateTime? createdAt;

  // Constructor
  const UserModel({
    required this.id,
    this.email,
    this.displayName,
    this.photoUrl,
    // this.phoneNumber,
    // this.roles,
    // this.createdAt,
  });

  // Một factory constructor để tạo UserModel rỗng (ví dụ: khi chưa đăng nhập)
  static const empty = UserModel(id: '');

  // Kiểm tra xem UserModel có rỗng không
  bool get isEmpty => this == UserModel.empty;
  // Kiểm tra xem UserModel có khác rỗng không
  bool get isNotEmpty => this != UserModel.empty;

  // Phương thức copyWith để tạo một bản sao của UserModel với một vài trường được cập nhật
  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    // String? phoneNumber,
    // List<String>? roles,
    // DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      // phoneNumber: phoneNumber ?? this.phoneNumber,
      // roles: roles ?? this.roles,
      // createdAt: createdAt ?? this.createdAt,
    );
  }

  // Chuyển đổi UserModel thành một Map<String, dynamic> để lưu vào Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      // 'phoneNumber': phoneNumber,
      // 'roles': roles,
      // 'createdAt': createdAt?.toIso8601String(),
    };
  }

  // Factory constructor để tạo UserModel từ một Map<String, dynamic> (dữ liệu từ Firestore)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      // phoneNumber: json['phoneNumber'] as String?,
      // roles: (json['roles'] as List<dynamic>?)?.map((e) => e as String).toList(),
      // createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
    );
  }

  // Cần thiết cho Equatable để so sánh các đối tượng
  @override
  List<Object?> get props => [id, email, displayName, photoUrl /*, phoneNumber, roles, createdAt*/];
}
