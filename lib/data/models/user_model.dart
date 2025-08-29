// lib/data/models/user_model.dart

import 'package:equatable/equatable.dart';
import 'package:piv_app/data/models/address_model.dart';

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
  final List<String> wishlist;
  final String? salesRepId;
  final List<String>? assignedAgentIds;

  // ====================== THÊM TRƯỜNG MỚI ======================
  final String activeRewardProgram;
  // =============================================================

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
    this.wishlist = const [],
    this.salesRepId,
    this.assignedAgentIds,
    // ====================== THÊM VÀO CONSTRUCTOR ======================
    this.activeRewardProgram = 'instant_discount',
    // =================================================================
  });

  bool get isAdmin => role == 'admin';
  bool get isSalesRep => role == 'sales_rep';
  bool get isAccountant => role == 'accountant';

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
    List<String>? wishlist,
    String? salesRepId,
    List<String>? assignedAgentIds,
    String? activeRewardProgram, // <<< Thêm vào đây
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
      salesRepId: salesRepId ?? this.salesRepId,
      assignedAgentIds: assignedAgentIds ?? this.assignedAgentIds,
      activeRewardProgram: activeRewardProgram ?? this.activeRewardProgram, // <<< Thêm vào đây
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
      'wishlist': wishlist,
      'salesRepId': salesRepId,
      'assignedAgentIds': assignedAgentIds,
      'activeRewardProgram': activeRewardProgram, // <<< Thêm vào đây
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      addresses: (json['addresses'] as List<dynamic>?)
          ?.map((a) => AddressModel.fromMap(a as Map<String, dynamic>))
          .toList() ?? [],
      role: json['role'] as String? ?? 'agent_2',
      status: json['status'] as String? ?? 'pending_approval',
      referrerId: json['referrerId'] as String?,
      referralPromptPending: json['referralPromptPending'] as bool? ?? false,
      wishlist: List<String>.from(json['wishlist'] ?? []),
      salesRepId: json['salesRepId'] as String?,
      assignedAgentIds: List<String>.from(json['assignedAgentIds'] ?? []),
      // ====================== THÊM LOGIC ĐỌC DỮ LIỆU ======================
      activeRewardProgram: json['activeRewardProgram'] as String? ?? 'instant_discount',
      // =================================================================
    );
  }

  // Lưu ý: factory `fromSnap` không có trong file gốc của bạn, nên tôi sẽ không thêm vào đây
  // để đảm bảo tính nhất quán. Nếu bạn dùng cả `fromSnap` ở nơi khác, hãy cập nhật nó tương tự.

  @override
  List<Object?> get props => [
    id, email, displayName, photoUrl, addresses, role, status,
    referrerId, referralPromptPending, wishlist, salesRepId, assignedAgentIds,
    activeRewardProgram // <<< Thêm vào đây
  ];
}