// lib/data/models/user_model.dart

import 'package:equatable/equatable.dart';
import 'package:piv_app/data/models/address_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel extends Equatable {
  final String id;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final List<AddressModel> addresses;
  final String role;
  final String status;
  final String? referrerId;
  final bool referralPromptPending;

  // --- TÍNH NĂNG MỚI: Thêm trường wishlist ---
  final List<String> wishlist; // Danh sách các ID sản phẩm yêu thích

  String get referralCode => id;

  const UserModel({
    required this.id,
    this.email,
    this.displayName,
    this.photoUrl,
    this.addresses = const [],
    this.role = 'agent_2',
    this.status = 'pending_approval',
    this.referrerId,
    this.referralPromptPending = false,
    this.wishlist = const [], // Khởi tạo danh sách rỗng
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
    bool? referralPromptPending,
    List<String>? wishlist, // Thêm vào copyWith
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
      referralPromptPending: referralPromptPending ?? this.referralPromptPending,
      wishlist: wishlist ?? this.wishlist,
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
      'referralPromptPending': referralPromptPending,
      'wishlist': wishlist, // Thêm vào JSON
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final List<AddressModel> addressesList = (json['addresses'] as List<dynamic>?)
        ?.map((addressMap) => AddressModel.fromMap(addressMap as Map<String, dynamic>))
        .toList() ?? [];

    // Đọc danh sách wishlist từ firestore
    final List<String> wishlistList = (json['wishlist'] as List<dynamic>?)
        ?.map((productId) => productId as String)
        .toList() ?? [];

    return UserModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      addresses: addressesList,
      role: json['role'] as String? ?? 'agent_2',
      status: json['status'] as String? ?? 'pending_approval',
      referrerId: json['referrerId'] as String?,
      referralPromptPending: json['referralPromptPending'] as bool? ?? false,
      wishlist: wishlistList,
    );
  }

  @override
  List<Object?> get props => [
    id, email, displayName, photoUrl, addresses, role, status,
    referrerId, referralPromptPending, wishlist
  ];
}