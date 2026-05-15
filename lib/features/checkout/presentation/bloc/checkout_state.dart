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
  final List<VoucherModel> availableVouchers; // <<< THÊM MỚI

  // --- THÊM CÁC TRƯỜNG MỚI CHO CÔNG NỢ ---
  final double currentDebt;
  final double amountToPay;
  // ------------------------------------
  
  final double vatPercentage;
  final bool isStackingAllowed; // Cờ cho phép cộng dồn chiết khấu

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
    this.availableVouchers = const [], // <<< THÊM MỚI
    // --- KHỞI TẠO GIÁ TRỊ MẶC ĐỊNH ---
    this.currentDebt = 0.0,
    this.amountToPay = 0.0,
    // ----------------------------------
    this.vatPercentage = 10.0,
    this.isStackingAllowed = false,
  });

  // --- SỬA ĐỔI GETTERS ĐỂ TÍNH TOÁN CÔNG NỢ ---
  // Tổng tiền hàng (sau chiết khấu, voucher)
  double get finalTotalBeforeVat => (subtotal + shippingFee - discount - commissionDiscount).clamp(0, double.infinity);
  double get vatAmount => finalTotalBeforeVat * (vatPercentage / 100);
  double get finalTotal => finalTotalBeforeVat + vatAmount;

  // Tổng tiền cần thanh toán (bao gồm cả công nợ)
  double get totalWithDebt => finalTotal + currentDebt;
  // ------------------------------------------

  @override
  List<Object?> get props => [
    status, addresses, selectedAddress, errorMessage,
    checkoutItems, subtotal, shippingFee, discount, appliedVoucher,
    commissionDiscount, paymentMethod, newOrderId, placeOrderForUserId, placeOrderForAgent,
    availableVouchers, // <<< THÊM MỚI
    // --- THÊM PROPS MỚI ---
    currentDebt, amountToPay,
    // --------------------
    vatPercentage,
    isStackingAllowed,
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
    List<VoucherModel>? availableVouchers, // <<< THÊM MỚI
    // --- THÊM CÁC THAM SỐ MỚI ---
    double? currentDebt,
    double? amountToPay,
    // ----------------------------
    double? vatPercentage,
    bool? isStackingAllowed,
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
      availableVouchers: availableVouchers ?? this.availableVouchers, // <<< THÊM MỚI
      // --- CẬP NHẬT CÁC TRƯỜNG MỚI ---
      currentDebt: currentDebt ?? this.currentDebt,
      amountToPay: amountToPay ?? this.amountToPay,
      // -------------------------------
      vatPercentage: vatPercentage ?? this.vatPercentage,
      isStackingAllowed: isStackingAllowed ?? this.isStackingAllowed,
    );
  }
}