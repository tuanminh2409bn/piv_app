import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/data/models/user_model.dart';
import 'package:piv_app/features/admin/domain/repositories/admin_repository.dart';
import 'package:piv_app/features/admin/presentation/bloc/manage_quick_list_cubit.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:piv_app/features/home/data/models/product_model.dart';
import 'package:piv_app/features/products/presentation/pages/search_page.dart';

class ManageQuickOrderListPage extends StatelessWidget {
  final UserModel agent;

  const ManageQuickOrderListPage({super.key, required this.agent});

  static Route<void> route(UserModel agent) {
    return MaterialPageRoute<void>(
      builder: (_) => BlocProvider(
        create: (context) => ManageQuickListCubit(
          adminRepository: sl<AdminRepository>(),
          agentId: agent.id,
        ),
        child: ManageQuickOrderListPage(agent: agent),
      ),
    );
  }

  // --- SỬA ĐỔI HÀM NÀY ---
  void _onAddProduct(BuildContext context) async {
    final currentUser = (context.read<AuthBloc>().state as AuthAuthenticated).user;
    final cubit = context.read<ManageQuickListCubit>();

    // Điều hướng đến trang tìm kiếm để chọn sản phẩm
    final selectedProduct = await Navigator.of(context).push<ProductModel?>(
      SearchPage.route(
        isSelectionMode: true,
        targetUserRole: agent.role,
        targetAgentId: agent.id, // <-- THÊM ID CỦA ĐẠI LÝ ĐANG QUẢN LÝ
      ),
    );
    // --- KẾT THÚC SỬA ĐỔI ---

    if (selectedProduct != null && context.mounted) {
      // Gọi hàm addProduct từ Cubit
      await cubit.addProduct(selectedProduct.id, currentUser.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sản phẩm đặt nhanh của ${agent.displayName ?? 'N/A'}'),
      ),
      body: BlocConsumer<ManageQuickListCubit, ManageQuickListState>(
        listener: (context, state) {
          // Lắng nghe và hiển thị lỗi nếu có
          if (state.status == ManageQuickListStatus.error && state.errorMessage != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: Colors.red,
                ),
              );
          }
        },
        builder: (context, state) {
          // Hiển thị vòng xoay khi đang tải
          if (state.status == ManageQuickListStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Hiển thị thông báo khi danh sách rỗng
          if (state.products.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Đại lý này chưa có sản phẩm nào trong danh sách đặt nhanh.\nNhấn nút (+) để bắt đầu thêm.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            );
          }

          // Hiển thị danh sách sản phẩm
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80), // Thêm khoảng đệm để không bị FAB che
            itemCount: state.products.length,
            itemBuilder: (context, index) {
              final product = state.products[index];
              return _ProductListItem(product: product);
            },
          );
        },
      ),
      // Nút để thêm sản phẩm mới
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _onAddProduct(context),
        label: const Text('Thêm sản phẩm'),
        icon: const Icon(Icons.add),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

// Widget con để hiển thị một sản phẩm trong danh sách
class _ProductListItem extends StatelessWidget {
  final ProductModel product;
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  _ProductListItem({required this.product});

  @override
  Widget build(BuildContext context) {
    // Lấy giá mặc định từ quy cách đầu tiên để hiển thị.
    final displayPrice = product.packingOptions.isNotEmpty
        ? product.getPriceForRole('agent_2') // Giả sử lấy giá đại lý cấp 2 để hiển thị
        : 0.0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        // --- SỬA ĐỔI: Thêm Stack để hiển thị icon private ---
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.network(
                product.imageUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image_not_supported, color: Colors.grey),
                    ),
              ),
            ),
            if (product.isPrivate) // <-- Kiểm tra
              Positioned(
                top: -4,
                left: -4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.lock, color: Colors.white, size: 12),
                ),
              ),
          ],
        ),
        // --- KẾT THÚC SỬA ĐỔI ---
        title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          currencyFormatter.format(displayPrice),
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          tooltip: 'Xóa',
          onPressed: () {
            // Dialog xác nhận (giữ nguyên)
            showDialog(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: const Text('Xác nhận xóa'),
                content: Text('Bạn có chắc muốn xóa "${product.name}" khỏi danh sách đặt nhanh?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Hủy'),
                  ),
                  TextButton(
                    onPressed: () {
                      context.read<ManageQuickListCubit>().removeProduct(product.id);
                      Navigator.of(dialogContext).pop();
                    },
                    child: const Text('Xóa', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}