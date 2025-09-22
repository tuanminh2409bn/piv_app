// lib/data/models/address_model.dart

import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

class AddressModel extends Equatable {
  final String id; // ID duy nhất cho mỗi địa chỉ
  final String recipientName; // Tên người nhận
  final String phoneNumber;
  final String street; // Số nhà, tên đường
  final String ward; // Phường/Xã
  // --- THAY ĐỔI ---: Đã xóa trường district
  // final String district;
  final String city; // Tỉnh/Thành phố
  final bool isDefault;

  AddressModel({
    String? id,
    required this.recipientName,
    required this.phoneNumber,
    required this.street,
    required this.ward,
    // --- THAY ĐỔI ---: Đã xóa trường district khỏi hàm khởi tạo
    // required this.district,
    required this.city,
    this.isDefault = false,
  }) : id = id ?? const Uuid().v4();

  @override
  // --- THAY ĐỔI ---: Đã xóa district khỏi props
  List<Object?> get props => [id, recipientName, phoneNumber, street, ward, city, isDefault];

  // Tiện ích để hiển thị địa chỉ đầy đủ
  // --- THAY ĐỔI ---: Đã xóa district khỏi chuỗi hiển thị
  String get fullAddress => '$street, $ward, $city';

  // copyWith để dễ dàng cập nhật
  AddressModel copyWith({
    String? id,
    String? recipientName,
    String? phoneNumber,
    String? street,
    String? ward,
    // --- THAY ĐỔI ---: Đã xóa trường district
    // String? district,
    String? city,
    bool? isDefault,
  }) {
    return AddressModel(
      id: id ?? this.id,
      recipientName: recipientName ?? this.recipientName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      street: street ?? this.street,
      ward: ward ?? this.ward,
      // --- THAY ĐỔI ---: Đã xóa trường district
      // district: district ?? this.district,
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
      // --- THAY ĐỔI ---: Đã xóa trường district. Ứng dụng sẽ bỏ qua trường này nếu có trong DB.
      // district: map['district'] as String? ?? '',
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
      // --- THAY ĐỔI ---: Đã xóa trường district. Sẽ không ghi trường này vào DB nữa.
      // 'district': district,
      'city': city,
      'isDefault': isDefault,
    };
  }
}