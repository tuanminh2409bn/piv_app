part of 'checkout_cubit.dart';

enum CheckoutStatus {
  initial,
  loading,
  success,
  error,
  applyingVoucher,
  placingOrder,
  orderSuccess,
  calculatingDiscount,
}

class CheckoutState extends Equatable {
  final CheckoutStatus status;
  final List<AddressModel> addresses;
  final AddressModel? selectedAddress;
  final String? errorMessage;
  final List<CartItemModel> checkoutItems;
  final double subtotal;
  final double shippingFee;
  final VoucherModel? appliedVoucher;
  final double discount;
  final double commissionDiscount;
  final String paymentMethod;
  final String? newOrderId;
  final String? placeOrderForUserId;
  final UserModel? placeOrderForAgent;

  const CheckoutState({
    this.status = CheckoutStatus.initial,
    this.addresses = const [],
    this.selectedAddress,
    this.errorMessage,
    this.checkoutItems = const [],
    this.subtotal = 0.0,
    this.shippingFee = 0.0,
    this.appliedVoucher,
    this.discount = 0.0,
    this.commissionDiscount = 0.0,
    this.paymentMethod = 'COD',
    this.newOrderId,
    this.placeOrderForUserId,
    this.placeOrderForAgent,
  });

  double get total => (subtotal + shippingFee - discount).clamp(0, double.infinity);
  double get finalTotal => (total - commissionDiscount).clamp(0, double.infinity);

  @override
  List<Object?> get props => [
    status, addresses, selectedAddress, errorMessage,
    checkoutItems, subtotal, shippingFee, discount, appliedVoucher,
    commissionDiscount, paymentMethod, newOrderId, placeOrderForUserId, placeOrderForAgent,
  ];

  CheckoutState copyWith({
    CheckoutStatus? status,
    List<AddressModel>? addresses,
    bool forceSelectedAddressToNull = false,
    AddressModel? selectedAddress,
    String? errorMessage,
    bool clearErrorMessage = false,
    List<CartItemModel>? checkoutItems,
    double? subtotal,
    double? shippingFee,
    VoucherModel? appliedVoucher,
    bool forceVoucherToNull = false,
    double? discount,
    double? commissionDiscount,
    String? paymentMethod,
    String? newOrderId,
    String? placeOrderForUserId,
    UserModel? placeOrderForAgent,
    bool clearPlaceOrderForAgent = false,
  }) {
    return CheckoutState(
      status: status ?? this.status,
      addresses: addresses ?? this.addresses,
      selectedAddress: forceSelectedAddressToNull ? null : (selectedAddress ?? this.selectedAddress),
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      checkoutItems: checkoutItems ?? this.checkoutItems,
      subtotal: subtotal ?? this.subtotal,
      shippingFee: shippingFee ?? this.shippingFee,
      appliedVoucher: forceVoucherToNull ? null : (appliedVoucher ?? this.appliedVoucher),
      discount: discount ?? this.discount,
      commissionDiscount: commissionDiscount ?? this.commissionDiscount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      newOrderId: newOrderId ?? this.newOrderId,
      placeOrderForUserId: placeOrderForUserId ?? this.placeOrderForUserId,
      placeOrderForAgent: clearPlaceOrderForAgent ? null : placeOrderForAgent ?? this.placeOrderForAgent,
    );
  }
}