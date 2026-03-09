// lib/data/models/user_model.dart

import 'package:equatable/equatable.dart';
import 'package:piv_app/data/models/address_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel extends Equatable {
  final String id;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final String? phoneNumber;
  final String? idCardOrTaxId;
  final String? dob;
  final String? currentAddress;
  final List<AddressModel> addresses;
  final String role;
  final String status;
  final String? referrerId;
  final bool referralPromptPending;
  final List<String> wishlist;
  final List<String> hiddenProductIds; // MỚI: Danh sách sản phẩm bị ẩn với User này
  final String? salesRepId;
  final List<String>? assignedAgentIds;
  final String activeRewardProgram;
  final int spinCount;
  final double debtAmount;
  final Map<String, dynamic>? customDiscount;
  final bool useGeneralPrice;

  String get referralCode => id;

  const UserModel({
    required this.id,
    this.email,
    this.displayName,
    this.photoUrl,
    this.phoneNumber,
    this.idCardOrTaxId,
    this.dob,
    this.currentAddress,
    this.addresses = const [],
    this.role = 'agent_2',
    this.status = 'pending_approval',
    this.referrerId,
    this.referralPromptPending = false,
    this.wishlist = const [],
    this.hiddenProductIds = const [],
    this.salesRepId,
    this.assignedAgentIds,
    this.activeRewardProgram = 'instant_discount',
    this.spinCount = 0,
    this.debtAmount = 0.0,
    this.customDiscount,
    this.useGeneralPrice = true,
  });

  bool get isGuest => role == 'guest';
  bool get isAdmin => role == 'admin';
  bool get isSalesRep => role == 'sales_rep';
  bool get isAccountant => role == 'accountant';

  bool get isProfileComplete =>
      displayName != null && displayName!.isNotEmpty &&
      phoneNumber != null && phoneNumber!.isNotEmpty &&
      idCardOrTaxId != null && idCardOrTaxId!.isNotEmpty &&
      dob != null && dob!.isNotEmpty &&
      currentAddress != null && currentAddress!.isNotEmpty;
  
  bool get customDiscountEnabled => customDiscount?['enabled'] == true;
  double get customFoliarRate => (customDiscount?['foliarRate'] as num?)?.toDouble() ?? 0.0;
  double get customRootRate => (customDiscount?['rootRate'] as num?)?.toDouble() ?? 0.0;

  static const empty = UserModel(id: '');
  bool get isEmpty => this == UserModel.empty;
  bool get isNotEmpty => this != UserModel.empty;

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
    String? idCardOrTaxId,
    String? dob,
    String? currentAddress,
    List<AddressModel>? addresses,
    String? role,
    String? status,
    String? referrerId,
    bool? referralPromptPending,
    List<String>? wishlist,
    List<String>? hiddenProductIds,
    String? salesRepId,
    List<String>? assignedAgentIds,
    String? activeRewardProgram,
    int? spinCount,
    double? debtAmount,
    Map<String, dynamic>? customDiscount,
    bool? useGeneralPrice,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      idCardOrTaxId: idCardOrTaxId ?? this.idCardOrTaxId,
      dob: dob ?? this.dob,
      currentAddress: currentAddress ?? this.currentAddress,
      addresses: addresses ?? this.addresses,
      role: role ?? this.role,
      status: status ?? this.status,
      referrerId: referrerId ?? this.referrerId,
      referralPromptPending: referralPromptPending ?? this.referralPromptPending,
      wishlist: wishlist ?? this.wishlist,
      hiddenProductIds: hiddenProductIds ?? this.hiddenProductIds,
      salesRepId: salesRepId ?? this.salesRepId,
      assignedAgentIds: assignedAgentIds ?? this.assignedAgentIds,
      activeRewardProgram: activeRewardProgram ?? this.activeRewardProgram,
      spinCount: spinCount ?? this.spinCount,
      debtAmount: debtAmount ?? this.debtAmount,
      customDiscount: customDiscount ?? this.customDiscount,
      useGeneralPrice: useGeneralPrice ?? this.useGeneralPrice,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'phoneNumber': phoneNumber,
      'idCardOrTaxId': idCardOrTaxId,
      'dob': dob,
      'currentAddress': currentAddress,
      'addresses': addresses.map((address) => address.toMap()).toList(),
      'role': role,
      'status': status,
      'referrerId': referrerId,
      'referralPromptPending': referralPromptPending,
      'wishlist': wishlist,
      'hiddenProductIds': hiddenProductIds,
      'salesRepId': salesRepId,
      'assignedAgentIds': assignedAgentIds,
      'activeRewardProgram': activeRewardProgram,
      'spinCount': spinCount,
      'debtAmount': debtAmount,
      'customDiscount': customDiscount,
      'useGeneralPrice': useGeneralPrice,
    };
  }

  factory UserModel.fromSnap(DocumentSnapshot snap) {
    final data = snap.data() as Map<String, dynamic>? ?? {};
    var addressesData = data['addresses'] as List<dynamic>? ?? [];
    List<AddressModel> addressesList =
    addressesData.map((a) => AddressModel.fromMap(a)).toList();

    return UserModel(
      id: snap.id,
      email: data['email'] as String?,
      displayName: data['displayName'] as String?,
      photoUrl: data['photoUrl'] as String?,
      phoneNumber: data['phoneNumber'] as String?,
      idCardOrTaxId: data['idCardOrTaxId'] as String?,
      dob: data['dob'] as String?,
      currentAddress: data['currentAddress'] as String?,
      addresses: addressesList,
      role: data['role'] as String? ?? 'agent_2',
      status: data['status'] as String? ?? 'pending_approval',
      referrerId: data['referrerId'] as String?,
      referralPromptPending: data['referralPromptPending'] as bool? ?? false,
      wishlist: List<String>.from(data['wishlist'] ?? []),
      hiddenProductIds: List<String>.from(data['hiddenProductIds'] ?? []),
      salesRepId: data['salesRepId'] as String?,
      assignedAgentIds: List<String>.from(data['assignedAgentIds'] ?? []),
      activeRewardProgram: data['activeRewardProgram'] as String? ?? 'instant_discount',
      spinCount: data['spinCount'] as int? ?? 0,
      debtAmount: (data['debtAmount'] as num?)?.toDouble() ?? 0.0,
      customDiscount: data['customDiscount'] as Map<String, dynamic>?,
      useGeneralPrice: data['useGeneralPrice'] as bool? ?? true,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      idCardOrTaxId: json['idCardOrTaxId'] as String?,
      dob: json['dob'] as String?,
      currentAddress: json['currentAddress'] as String?,
      addresses: (json['addresses'] as List<dynamic>?)
          ?.map((a) => AddressModel.fromMap(a as Map<String, dynamic>))
          .toList() ?? [],
      role: json['role'] as String? ?? 'agent_2',
      status: json['status'] as String? ?? 'pending_approval',
      referrerId: json['referrerId'] as String?,
      referralPromptPending: json['referralPromptPending'] as bool? ?? false,
      wishlist: List<String>.from(json['wishlist'] ?? []),
      hiddenProductIds: List<String>.from(json['hiddenProductIds'] ?? []),
      salesRepId: json['salesRepId'] as String?,
      assignedAgentIds: List<String>.from(json['assignedAgentIds'] ?? []),
      activeRewardProgram: json['activeRewardProgram'] as String? ?? 'instant_discount',
      spinCount: json['spinCount'] as int? ?? 0,
      debtAmount: (json['debtAmount'] as num?)?.toDouble() ?? 0.0,
      customDiscount: json['customDiscount'] as Map<String, dynamic>?,
      useGeneralPrice: json['useGeneralPrice'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [
    id,
    email,
    displayName,
    photoUrl,
    phoneNumber,
    idCardOrTaxId,
    dob,
    currentAddress,
    addresses,
    role,
    status,
    referrerId,
    referralPromptPending,
    wishlist,
    hiddenProductIds,
    salesRepId,
    assignedAgentIds,
    activeRewardProgram,
    spinCount,
    debtAmount,
    customDiscount,
    useGeneralPrice,
  ];
}