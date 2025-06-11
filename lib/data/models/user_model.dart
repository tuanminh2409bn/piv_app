import 'package:equatable/equatable.dart';
import 'package:piv_app/data/models/address_model.dart';

class UserModel extends Equatable {
  final String id;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final List<AddressModel> addresses;
  final String role; // << THÊM TRƯỜNG NÀY

  const UserModel({
    required this.id,
    this.email,
    this.displayName,
    this.photoUrl,
    this.addresses = const [],
    this.role = 'customer', // << GIÁ TRỊ MẶC ĐỊNH LÀ 'customer'
  });

  bool get isAdmin => role == 'admin'; // << Getter tiện ích để kiểm tra vai trò

  static const empty = UserModel(id: '');
  bool get isEmpty => this == UserModel.empty;
  bool get isNotEmpty => this != UserModel.empty;

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    List<AddressModel>? addresses,
    String? role, // << THÊM VÀO COPYWITH
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      addresses: addresses ?? this.addresses,
      role: role ?? this.role, // << GÁN GIÁ TRỊ
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
      id: json['id'] as String,
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      addresses: addressesList,
      role: json['role'] as String? ?? 'customer', // << ĐỌC VÀ ĐẶT GIÁ TRỊ MẶC ĐỊNH
    );
  }

  @override
  List<Object?> get props => [id, email, displayName, photoUrl, addresses, role]; // << THÊM VÀO PROPS
}
