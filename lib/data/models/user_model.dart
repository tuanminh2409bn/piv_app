import 'package:equatable/equatable.dart';
import 'package:piv_app/data/models/address_model.dart'; // Import AddressModel

class UserModel extends Equatable {
  final String id;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final List<AddressModel> addresses; // << THÊM TRƯỜNG NÀY

  const UserModel({
    required this.id,
    this.email,
    this.displayName,
    this.photoUrl,
    this.addresses = const [], // << GIÁ TRỊ MẶC ĐỊNH LÀ DANH SÁCH RỖNG
  });

  static const empty = UserModel(id: '');
  bool get isEmpty => this == UserModel.empty;
  bool get isNotEmpty => this != UserModel.empty;

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    List<AddressModel>? addresses, // << THÊM VÀO COPYWITH
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      addresses: addresses ?? this.addresses, // << GÁN GIÁ TRỊ
    );
  }

  // Chuyển đổi UserModel thành một Map để lưu vào Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      // Chuyển đổi List<AddressModel> thành List<Map>
      'addresses': addresses.map((address) => address.toMap()).toList(),
    };
  }

  // Factory constructor để tạo UserModel từ một Map (dữ liệu từ Firestore)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Xử lý đọc danh sách địa chỉ từ Firestore
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
      addresses: addressesList, // << GÁN GIÁ TRỊ
    );
  }

  @override
  List<Object?> get props => [id, email, displayName, photoUrl, addresses]; // << THÊM VÀO PROPS
}
