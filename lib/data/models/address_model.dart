import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart'; // Thêm package uuid để tạo ID duy nhất

class AddressModel extends Equatable {
  final String id; // ID duy nhất cho mỗi địa chỉ
  final String recipientName; // Tên người nhận
  final String phoneNumber;
  final String street; // Số nhà, tên đường
  final String ward; // Phường/Xã
  final String district; // Quận/Huyện
  final String city; // Tỉnh/Thành phố
  final bool isDefault;

  AddressModel({
    String? id,
    required this.recipientName,
    required this.phoneNumber,
    required this.street,
    required this.ward,
    required this.district,
    required this.city,
    this.isDefault = false,
  }) : id = id ?? const Uuid().v4(); // Tự động tạo ID nếu không được cung cấp

  @override
  List<Object?> get props => [id, recipientName, phoneNumber, street, ward, district, city, isDefault];

  // Tiện ích để hiển thị địa chỉ đầy đủ
  String get fullAddress => '$street, $ward, $district, $city';

  // copyWith để dễ dàng cập nhật
  AddressModel copyWith({
    String? id,
    String? recipientName,
    String? phoneNumber,
    String? street,
    String? ward,
    String? district,
    String? city,
    bool? isDefault,
  }) {
    return AddressModel(
      id: id ?? this.id,
      recipientName: recipientName ?? this.recipientName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      street: street ?? this.street,
      ward: ward ?? this.ward,
      district: district ?? this.district,
      city: city ?? this.city,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  // Chuyển đổi từ Map (dữ liệu đọc từ Firestore) thành AddressModel
  factory AddressModel.fromMap(Map<String, dynamic> map) {
    return AddressModel(
      id: map['id'] as String?,
      recipientName: map['recipientName'] as String? ?? '',
      phoneNumber: map['phoneNumber'] as String? ?? '',
      street: map['street'] as String? ?? '',
      ward: map['ward'] as String? ?? '',
      district: map['district'] as String? ?? '',
      city: map['city'] as String? ?? '',
      isDefault: map['isDefault'] as bool? ?? false,
    );
  }

  // Chuyển đổi AddressModel thành Map để lưu vào Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'recipientName': recipientName,
      'phoneNumber': phoneNumber,
      'street': street,
      'ward': ward,
      'district': district,
      'city': city,
      'isDefault': isDefault,
    };
  }
}

