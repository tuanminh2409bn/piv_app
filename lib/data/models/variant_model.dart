import 'package:equatable/equatable.dart';

class VariantModel extends Equatable {
  final String name;      // Ví dụ: "Chai 1 lít", "Can 5 lít"
  final double price;     // Giá của mẫu mã này
  final int stock;      // Số lượng tồn kho của mẫu mã này

  const VariantModel({
    required this.name,
    required this.price,
    this.stock = 0,
  });

  @override
  List<Object?> get props => [name, price, stock];

  // Chuyển đổi từ Map (dữ liệu đọc từ Firestore)
  factory VariantModel.fromMap(Map<String, dynamic> map) {
    return VariantModel(
      name: map['name'] as String? ?? 'N/A',
      price: (map['price'] as num? ?? 0).toDouble(),
      stock: (map['stock'] as num? ?? 0).toInt(),
    );
  }

  // Chuyển đổi thành Map để lưu vào Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'stock': stock,
    };
  }
}
