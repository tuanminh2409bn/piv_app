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
  final String role; // Giữ nguyên là String: 'admin', 'accountant', 'sales_rep', 'agent_1', 'agent_2'
  final String status; // Giữ nguyên là String
  final String? referrerId;
  final bool referralPromptPending;
  final List<String> wishlist;
  final String? salesRepId;

  // --- TRƯỜNG MỚI ---
  // Dành cho Sales Rep & Kế toán: Danh sách ID của các đại lý được giao
  final List<String>? assignedAgentIds;
  // ------------------

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
    this.assignedAgentIds, // Thêm vào constructor
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
      'assignedAgentIds': assignedAgentIds, // Thêm trường mới
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
    );
  }

  @override
  List<Object?> get props => [
    id, email, displayName, photoUrl, addresses, role, status,
    referrerId, referralPromptPending, wishlist, salesRepId, assignedAgentIds
  ];
}