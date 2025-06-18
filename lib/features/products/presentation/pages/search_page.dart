// lib/features/products/presentation/pages/search_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:piv_app/features/home/presentation/bloc/home_cubit.dart';
import 'package:piv_app/features/home/data/models/product_model.dart';
import 'package:piv_app/features/products/presentation/pages/product_detail_page.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  static PageRoute<void> route(HomeCubit homeCubit) {
    return MaterialPageRoute<void>(
      builder: (_) => BlocProvider.value(
        value: homeCubit,
        child: const SearchPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const SearchView();
  }
}

// --- SỬA: Chuyển thành StatefulWidget ---
class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Thêm listener để cập nhật UI khi người dùng gõ hoặc xóa chữ
    // Cụ thể là để ẩn/hiện icon "X"
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    // Khi trang này bị đóng, reset lại trạng thái tìm kiếm của trang chủ
    context.read<HomeCubit>().searchFeaturedProducts('');
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    String userRole = 'agent_2';
    if (authState is AuthAuthenticated) {
      userRole = authState.user.role;
    }

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Nhập tên hoặc mô tả sản phẩm...',
            border: InputBorder.none,
            hintStyle: TextStyle(fontWeight: FontWeight.normal, color: Colors.grey.shade600),
            // --- TÍNH NĂNG 1: Icon xóa chữ trong ô tìm kiếm ---
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
              icon: const Icon(Icons.clear, color: Colors.grey),
              onPressed: () {
                _searchController.clear();
                context.read<HomeCubit>().searchFeaturedProducts('');
              },
            )
                : null,
          ),
          onChanged: (query) {
            context.read<HomeCubit>().searchFeaturedProducts(query);
          },
        ),
        // --- TÍNH NĂNG 2: Nút Hủy để quay về trang chủ ---
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Hủy', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
      body: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          if (_searchController.text.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_rounded, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Tìm kiếm trong toàn bộ sản phẩm.'),
                ],
              ),
            );
          }

          if (state.filteredFeaturedProducts.isEmpty) {
            return const Center(child: Text('Không tìm thấy sản phẩm nào.'));
          }

          return _buildProductList(context, state.filteredFeaturedProducts, userRole);
        },
      ),
    );
  }

  Widget _buildProductList(BuildContext context, List<ProductModel> products, String userRole) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final product = products[index];
        final price = product.getPriceForRole(userRole);
        final unit = product.displayUnit;
        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: (product.imageUrl.isNotEmpty)
                ? Image.network(product.imageUrl, width: 70, height: 70, fit: BoxFit.cover, errorBuilder: (c,e,s) => Container(width: 70, height: 70, color: Colors.grey.shade200, child: const Icon(Icons.image, color: Colors.grey)))
                : Container(width: 70, height: 70, color: Colors.grey.shade200, child: const Icon(Icons.image, color: Colors.grey)),
          ),
          title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(
            '${currencyFormatter.format(price)} / $unit',
            style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w500),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => Navigator.of(context).push(ProductDetailPage.route(product.id)),
        );
      },
    );
  }
}