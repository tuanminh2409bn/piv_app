// lib/features/checkout/presentation/bloc/checkout_state.dart

part of 'checkout_cubit.dart';

enum CheckoutStatus {
  initial,
  loading,
  success,
  error,
  placingOrder,
  orderSuccess,
}

class CheckoutState extends Equatable {
  final CheckoutStatus status;
  final List<AddressModel> addresses;
  final AddressModel? selectedAddress;
  final String? errorMessage;

  // --- THÊM MỚI CÁC TRƯỜNG ĐỂ HỖ TRỢ "MUA NGAY" ---
  final List<CartItemModel> checkoutItems;
  final double subtotal;
  final double shippingFee;
  final double total;
  // ----------------------------------------------------

  const CheckoutState({
    this.status = CheckoutStatus.initial,
    this.addresses = const [],
    this.selectedAddress,
    this.errorMessage,
    // --- KHỞI TẠO CÁC GIÁ TRỊ MỚI ---
    this.checkoutItems = const [],
    this.subtotal = 0.0,
    this.shippingFee = 0.0,
    this.total = 0.0,
  });

  @override
  List<Object?> get props => [
    status, addresses, selectedAddress, errorMessage,
    checkoutItems, subtotal, shippingFee, total
  ];

  CheckoutState copyWith({
    CheckoutStatus? status,
    List<AddressModel>? addresses,
    bool forceSelectedAddressToNull = false,
    AddressModel? selectedAddress,
    String? errorMessage,
    // --- THÊM VÀO COPYWITH ---
    List<CartItemModel>? checkoutItems,
    double? subtotal,
    double? shippingFee,
    double? total,
  }) {
    return CheckoutState(
      status: status ?? this.status,
      addresses: addresses ?? this.addresses,
      selectedAddress: forceSelectedAddressToNull ? null : (selectedAddress ?? this.selectedAddress),
      errorMessage: errorMessage ?? this.errorMessage,
      checkoutItems: checkoutItems ?? this.checkoutItems,
      subtotal: subtotal ?? this.subtotal,
      shippingFee: shippingFee ?? this.shippingFee,
      total: total ?? this.total,
    );
  }
}