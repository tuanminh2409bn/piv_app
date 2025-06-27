part of 'checkout_cubit.dart';

enum CheckoutStatus {
  initial,
  loading,
  success,
  error,
  applyingVoucher, // Trạng thái mới khi đang kiểm tra voucher
  placingOrder,
  orderSuccess,
}

class CheckoutState extends Equatable {
  final CheckoutStatus status;
  final List<AddressModel> addresses;
  final AddressModel? selectedAddress;
  final String? errorMessage;

  // Thông tin về các sản phẩm đang được thanh toán
  final List<CartItemModel> checkoutItems;
  final double subtotal;
  final double shippingFee;

  // --- CÁC TRƯỜNG MỚI CHO VOUCHER ---
  final VoucherModel? appliedVoucher;
  final double discount;
  // ------------------------------------

  const CheckoutState({
    this.status = CheckoutStatus.initial,
    this.addresses = const [],
    this.selectedAddress,
    this.errorMessage,
    this.checkoutItems = const [],
    this.subtotal = 0.0,
    this.shippingFee = 0.0,
    // --- KHỞI TẠO GIÁ TRỊ MỚI ---
    this.appliedVoucher,
    this.discount = 0.0,
  });

  // --- TÍNH TOÁN LẠI TỔNG TIỀN ---
  // Tổng tiền cuối cùng = Tạm tính + Phí ship - Giảm giá
  // Dùng clamp để đảm bảo tổng tiền không bao giờ âm
  double get total => (subtotal + shippingFee - discount).clamp(0, double.infinity);

  @override
  List<Object?> get props => [
    status, addresses, selectedAddress, errorMessage,
    checkoutItems, subtotal, shippingFee, discount, appliedVoucher
  ];

  CheckoutState copyWith({
    CheckoutStatus? status,
    List<AddressModel>? addresses,
    bool forceSelectedAddressToNull = false,
    AddressModel? selectedAddress,
    String? errorMessage,
    List<CartItemModel>? checkoutItems,
    double? subtotal,
    double? shippingFee,
    // --- THÊM CÁC TRƯỜNG MỚI VÀO COPYWITH ---
    VoucherModel? appliedVoucher,
    bool forceVoucherToNull = false, // Cờ để xóa voucher khi cần
    double? discount,
  }) {
    return CheckoutState(
      status: status ?? this.status,
      addresses: addresses ?? this.addresses,
      selectedAddress: forceSelectedAddressToNull ? null : (selectedAddress ?? this.selectedAddress),
      errorMessage: errorMessage ?? this.errorMessage,
      checkoutItems: checkoutItems ?? this.checkoutItems,
      subtotal: subtotal ?? this.subtotal,
      shippingFee: shippingFee ?? this.shippingFee,
      // Nếu forceVoucherToNull là true, đặt voucher thành null, ngược lại thì cập nhật
      appliedVoucher: forceVoucherToNull ? null : (appliedVoucher ?? this.appliedVoucher),
      discount: discount ?? this.discount,
    );
  }
}