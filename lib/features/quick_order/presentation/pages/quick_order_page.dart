import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/data/models/packaging_option_model.dart';
import 'package:piv_app/features/cart/presentation/pages/cart_page.dart';
import 'package:piv_app/features/home/data/models/product_model.dart';
import 'package:piv_app/features/quick_order/data/models/order_line_model.dart';
import 'package:piv_app/features/quick_order/presentation/bloc/quick_order_cubit.dart';

class QuickOrderPage extends StatelessWidget {
  const QuickOrderPage({super.key});

  static PageRoute<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const QuickOrderPage());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<QuickOrderCubit>()..loadProducts(),
      child: const QuickOrderView(),
    );
  }
}

class QuickOrderView extends StatelessWidget {
  const QuickOrderView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đặt hàng nhanh'),
      ),
      body: BlocConsumer<QuickOrderCubit, QuickOrderState>(
        listener: (context, state) {
          if (state.status == QuickOrderStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          if (state.status == QuickOrderStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == QuickOrderStatus.error && state.allProducts.isEmpty) {
            return Center(child: Text(state.errorMessage ?? 'Không thể tải danh sách sản phẩm.'));
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: state.orderLines.length,
                  itemBuilder: (context, index) {
                    final line = state.orderLines[index];
                    return _buildOrderRow(context, line, state.allProducts, index);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm sản phẩm khác'),
                  onPressed: () => context.read<QuickOrderCubit>().addProductLine(),
                ),
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildOrderRow(BuildContext context, OrderLine line, List<ProductModel> allProducts, int index) {
    // Sử dụng key để giúp Flutter nhận diện đúng widget khi danh sách thay đổi
    return Card(
      key: ValueKey(line.id),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // --- Dòng chọn sản phẩm ---
            DropdownButtonFormField<ProductModel>(
              value: line.selectedProduct,
              isExpanded: true,
              hint: const Text('Chọn sản phẩm'),
              decoration: const InputDecoration(border: UnderlineInputBorder()),
              items: allProducts.map((product) {
                return DropdownMenuItem<ProductModel>(
                  value: product,
                  child: Text(product.name, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (product) {
                if (product != null) {
                  context.read<QuickOrderCubit>().updateProductForLine(line.id, product);
                }
              },
            ),
            const SizedBox(height: 12),
            // --- Dòng chọn quy cách và số lượng ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Quy cách
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<PackagingOptionModel>(
                    value: line.selectedPackaging,
                    isExpanded: true,
                    hint: const Text('Quy cách'),
                    decoration: const InputDecoration(border: UnderlineInputBorder()),
                    // Chỉ bật khi đã chọn sản phẩm
                    items: line.selectedProduct?.packingOptions.map((option) {
                      return DropdownMenuItem<PackagingOptionModel>(
                        value: option,
                        child: Text(option.name, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: line.selectedProduct == null ? null : (option) {
                      if (option != null) {
                        context.read<QuickOrderCubit>().updatePackagingForLine(line.id, option);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // Số lượng
                SizedBox(
                  width: 80,
                  child: TextFormField(
                    initialValue: line.quantity.toString(),
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: 'Số lượng'),
                    onChanged: (value) {
                      final quantity = int.tryParse(value) ?? 1;
                      context.read<QuickOrderCubit>().updateQuantityForLine(line.id, quantity);
                    },
                  ),
                ),
                // Nút xóa
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => context.read<QuickOrderCubit>().removeProductLine(line.id),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: BlocBuilder<QuickOrderCubit, QuickOrderState>(
        builder: (context, state) {
          return ElevatedButton(
            onPressed: (state.status == QuickOrderStatus.submitting) ? null : () async {
              await context.read<QuickOrderCubit>().addAllToCart();
              // Sau khi thêm, hiển thị thông báo và chuyển sang trang giỏ hàng
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã thêm các sản phẩm vào giỏ hàng!'), backgroundColor: Colors.green)
              );
              Navigator.of(context).pushReplacement(CartPage.route());
            },
            child: (state.status == QuickOrderStatus.submitting)
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white))
                : const Text('THÊM TẤT CẢ VÀO GIỎ HÀNG'),
          );
        },
      ),
    );
  }
}