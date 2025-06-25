import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/data/models/packaging_option_model.dart';
import 'package:piv_app/features/cart/presentation/bloc/cart_cubit.dart';
import 'package:piv_app/features/home/data/models/product_model.dart';
import 'package:piv_app/features/home/domain/repositories/home_repository.dart';
import 'package:piv_app/features/quick_order/data/models/order_line_model.dart';
import 'package:uuid/uuid.dart';

part 'quick_order_state.dart';

class QuickOrderCubit extends Cubit<QuickOrderState> {
  final HomeRepository _homeRepository;
  final CartCubit _cartCubit;

  QuickOrderCubit({required HomeRepository homeRepository, required CartCubit cartCubit})
      : _homeRepository = homeRepository,
        _cartCubit = cartCubit,
        super(const QuickOrderState());

  // Tải tất cả sản phẩm để người dùng có thể tìm kiếm và chọn
  Future<void> loadProducts() async {
    emit(state.copyWith(status: QuickOrderStatus.loading));
    final result = await _homeRepository.getAllProducts();
    result.fold(
          (failure) => emit(state.copyWith(status: QuickOrderStatus.error, errorMessage: failure.message)),
          (products) => emit(state.copyWith(
        status: QuickOrderStatus.success,
        allProducts: products,
        // Bắt đầu với một dòng trống
        orderLines: [OrderLine(id: const Uuid().v4())],
      )),
    );
  }

  // Thêm một dòng mới vào form
  void addProductLine() {
    final newLines = List<OrderLine>.from(state.orderLines)
      ..add(OrderLine(id: const Uuid().v4()));
    emit(state.copyWith(orderLines: newLines));
  }

  // Xóa một dòng khỏi form
  void removeProductLine(String lineId) {
    final newLines = List<OrderLine>.from(state.orderLines)
      ..removeWhere((line) => line.id == lineId);
    emit(state.copyWith(orderLines: newLines));
  }

  // Cập nhật khi người dùng chọn một sản phẩm cho một dòng
  void updateProductForLine(String lineId, ProductModel newProduct) {
    final newLines = state.orderLines.map((line) {
      if (line.id == lineId) {
        // Tự động chọn quy cách đầu tiên của sản phẩm
        final firstPackaging = newProduct.packingOptions.isNotEmpty ? newProduct.packingOptions.first : null;
        return line.copyWith(selectedProduct: newProduct, selectedPackaging: firstPackaging);
      }
      return line;
    }).toList();
    emit(state.copyWith(orderLines: newLines));
  }

  // Cập nhật khi người dùng chọn một quy cách khác
  void updatePackagingForLine(String lineId, PackagingOptionModel newPackaging) {
    final newLines = state.orderLines.map((line) {
      if (line.id == lineId) {
        return line.copyWith(selectedPackaging: newPackaging);
      }
      return line;
    }).toList();
    emit(state.copyWith(orderLines: newLines));
  }

  // Cập nhật số lượng
  void updateQuantityForLine(String lineId, int newQuantity) {
    final newLines = state.orderLines.map((line) {
      if (line.id == lineId) {
        return line.copyWith(quantity: newQuantity > 0 ? newQuantity : 1);
      }
      return line;
    }).toList();
    emit(state.copyWith(orderLines: newLines));
  }

  // Xử lý cuối cùng: thêm tất cả vào giỏ hàng
  Future<void> addAllToCart() async {
    emit(state.copyWith(status: QuickOrderStatus.submitting));

    final validLines = state.orderLines.where((line) => line.selectedProduct != null && line.selectedPackaging != null).toList();

    if (validLines.isEmpty) {
      emit(state.copyWith(status: QuickOrderStatus.error, errorMessage: 'Vui lòng chọn ít nhất một sản phẩm.'));
      // Quay lại trạng thái success sau khi báo lỗi
      emit(state.copyWith(status: QuickOrderStatus.success));
      return;
    }

    for (final line in validLines) {
      await _cartCubit.addProduct(
        product: line.selectedProduct!,
        selectedOption: line.selectedPackaging!,
        quantity: line.quantity,
      );
    }

    // Sau khi thêm xong, quay về trạng thái thành công với form rỗng
    emit(state.copyWith(
      status: QuickOrderStatus.success,
      orderLines: [OrderLine(id: const Uuid().v4())], // Reset lại form
    ));
  }
}