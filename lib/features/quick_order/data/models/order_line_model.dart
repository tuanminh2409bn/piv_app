import 'package:piv_app/features/home/data/models/product_model.dart';
import 'package:piv_app/data/models/packaging_option_model.dart';

// Model này chỉ dùng để quản lý trạng thái trên giao diện của form
class OrderLine {
  final String id; // ID duy nhất cho mỗi dòng để xóa/sửa
  ProductModel? selectedProduct;
  PackagingOptionModel? selectedPackaging;
  int quantity;

  OrderLine({
    required this.id,
    this.selectedProduct,
    this.selectedPackaging,
    this.quantity = 1,
  });

  OrderLine copyWith({
    ProductModel? selectedProduct,
    PackagingOptionModel? selectedPackaging,
    int? quantity,
  }) {
    return OrderLine(
      id: id,
      selectedProduct: selectedProduct ?? this.selectedProduct,
      selectedPackaging: selectedPackaging ?? this.selectedPackaging,
      quantity: quantity ?? this.quantity,
    );
  }
}