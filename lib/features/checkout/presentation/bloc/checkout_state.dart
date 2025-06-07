part of 'checkout_cubit.dart'; // Sẽ tạo file checkout_cubit.dart sau

enum CheckoutStatus {
  initial,    // Trạng thái ban đầu
  loading,    // Đang tải dữ liệu (ví dụ: địa chỉ)
  success,    // Tải thành công, sẵn sàng để thanh toán
  error,      // Có lỗi xảy ra
  placingOrder, // Đang trong quá trình đặt hàng
  orderSuccess, // Đặt hàng thành công
}

class CheckoutState extends Equatable {
  final CheckoutStatus status;
  // Danh sách tất cả địa chỉ của người dùng để họ lựa chọn
  final List<AddressModel> addresses;
  // Địa chỉ đang được chọn để giao hàng
  final AddressModel? selectedAddress;
  final String? errorMessage;

  const CheckoutState({
    this.status = CheckoutStatus.initial,
    this.addresses = const [],
    this.selectedAddress,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [status, addresses, selectedAddress, errorMessage];

  CheckoutState copyWith({
    CheckoutStatus? status,
    List<AddressModel>? addresses,
    // Dùng một trick nhỏ để có thể set selectedAddress về null
    bool forceSelectedAddressToNull = false,
    AddressModel? selectedAddress,
    String? errorMessage,
  }) {
    return CheckoutState(
      status: status ?? this.status,
      addresses: addresses ?? this.addresses,
      selectedAddress: forceSelectedAddressToNull
          ? null
          : (selectedAddress ?? this.selectedAddress),
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
