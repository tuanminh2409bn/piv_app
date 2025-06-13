import 'package:equatable/equatable.dart';
import 'package:piv_app/data/models/address_model.dart';

class UserModel extends Equatable {
  final String id;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final List<AddressModel> addresses;

  // ** CÁC TRƯỜNG ĐÃ CẬP NHẬT **
  /// Vai trò của người dùng, ví dụ: 'agent_1', 'agent_2', 'admin'
  final String role;
  /// Trạng thái tài khoản: 'pending_approval', 'active', 'suspended'
  final String status;

  final String? referrerId;
  String get referralCode => id;

  const UserModel({
    required this.id,
    this.email,
    this.displayName,
    this.photoUrl,
    this.addresses = const [],
    this.role = 'agent_2', // Mặc định là đại lý cấp thấp nhất khi mới đăng ký
    this.status = 'pending_approval', // Mặc định là đang chờ duyệt
    this.referrerId,
  });

  bool get isAdmin => role == 'admin';

  static const empty = UserModel(id: '');
  bool get isEmpty => this == UserModel.empty;
  bool get isNotEmpty => this != UserModel.empty;

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    List<AddressModel>? addresses,
    String? role,
    String? status,
    String? referrerId,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      addresses: addresses ?? this.addresses,
      role: role ?? this.role,
      status: status ?? this.status,
      referrerId: referrerId ?? this.referrerId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'addresses': addresses.map((address) => address.toMap()).toList(),
      'role': role,
      'status': status,
      'referrerId': referrerId,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final List<AddressModel> addressesList;
    if (json['addresses'] != null && json['addresses'] is List) {
      addressesList = (json['addresses'] as List)
          .map((addressMap) => AddressModel.fromMap(addressMap as Map<String, dynamic>))
          .toList();
    } else {
      addressesList = [];
    }

    return UserModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      addresses: addressesList,
      role: json['role'] as String? ?? 'agent_2',
      status: json['status'] as String? ?? 'pending_approval',
      referrerId: json['referrerId'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, email, displayName, photoUrl, addresses, role, status, referrerId];
}
