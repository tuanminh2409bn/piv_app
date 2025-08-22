// lib/features/products/presentation/pages/search_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:piv_app/features/home/data/models/product_model.dart';
import 'package:piv_app/features/products/presentation/pages/product_detail_page.dart';
import 'package:piv_app/features/search/bloc/search_cubit.dart';
import 'package:piv_app/data/models/cart_item_model.dart';

class SearchPage extends StatelessWidget {
  // --- THÊM MỚI: Các tham số để xác định chế độ hoạt động ---
  final bool isSelectionMode;
  final String? targetUserRole;

  const SearchPage({
    super.key,
    this.isSelectionMode = false,
    this.targetUserRole,
  });

  // --- NÂNG CẤP ROUTE: Nhận tham số và trả về CartItemModel ---
  static PageRoute<CartItemModel?> route({
    bool isSelectionMode = false,
    String? targetUserRole,
  }) {
    return MaterialPageRoute<CartItemModel?>(
      builder: (_) => BlocProvider(
        // --- THAY ĐỔI: Gọi tìm kiếm với chuỗi rỗng để tải tất cả sản phẩm ---
        create: (_) => sl<SearchCubit>()..searchProducts(''),
        child: SearchPage(
          isSelectionMode: isSelectionMode,
          targetUserRole: targetUserRole,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SearchView(
      isSelectionMode: isSelectionMode,
      targetUserRole: targetUserRole,
    );
  }
}

class SearchView extends StatefulWidget {
  // --- THÊM MỚI ---
  final bool isSelectionMode;
  final String? targetUserRole;

  const SearchView({
    super.key,
    required this.isSelectionMode,
    this.targetUserRole,
  });

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      // --- THÊM MỚI: Debouncer để tìm kiếm mượt mà hơn ---
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 400), () {
        if (mounted) {
          context.read<SearchCubit>().searchProducts(_searchController.text);
        }
      });
      // Cập nhật UI để hiển thị/ẩn nút clear
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSubmitted(String query) {
    if (query.trim().isNotEmpty) {
      context.read<SearchCubit>().searchProducts(query.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Tìm kiếm sản phẩm...',
            border: InputBorder.none,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
              icon: const Icon(Icons.clear, color: Colors.grey),
              onPressed: () => _searchController.clear(),
            )
                : null,
          ),
          onSubmitted: _onSubmitted,
        ),
      ),
      body: BlocBuilder<SearchCubit, SearchState>(
        builder: (context, state) {
          // --- THAY ĐỔI: Luôn hiển thị danh sách sản phẩm, không còn lịch sử tìm kiếm ---
          if (state.status == SearchStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.searchResults.isEmpty) {
            return const Center(child: Text('Không tìm thấy sản phẩm nào.'));
          }
          return _buildSearchResultsList(
            context,
            state.searchResults,
            widget.isSelectionMode,
            widget.targetUserRole,
          );
        },
      ),
    );
  }

  // Widget _buildSearchHistory đã bị xóa vì không còn dùng đến

  Widget _buildSearchResultsList(
      BuildContext context,
      List<ProductModel> products,
      bool isSelectionMode,
      String? targetUserRole,
      ) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    // --- LOGIC QUAN TRỌNG NHẤT VỀ GIÁ ---
    String userRole;
    if (isSelectionMode && targetUserRole != null) {
      // Nếu ở chế độ chọn (đặt hàng hộ), ưu tiên vai trò của Đại lý được truyền vào
      userRole = targetUserRole;
    } else {
      // Nếu không, lấy vai trò của người dùng đang đăng nhập
      final authState = context.read<AuthBloc>().state;
      userRole = (authState is AuthAuthenticated) ? authState.user.role : 'agent_2';
    }
    // ------------------------------------------

    return ListView.separated(
      padding: const EdgeInsets.all(16.0),
      itemCount: products.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final product = products[index];
        final price = product.getPriceForRole(userRole);
        final unit = product.displayUnit;
        return ListTile(
          leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(product.imageUrl,
                  width: 70, height: 70, fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(
                      color: Colors.grey.shade200, child: const Icon(Icons.image)))),
          title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(
              price > 0 ? '${currencyFormatter.format(price)} / $unit' : 'Chưa có giá',
              style: TextStyle(
                  color: price > 0 ? Theme.of(context).colorScheme.primary : Colors.grey,
                  fontWeight: FontWeight.w500)),
          trailing: Icon(isSelectionMode ? Icons.add_shopping_cart : Icons.arrow_forward_ios, size: 16),
          onTap: () {
            if (isSelectionMode) {
              // Logic trả về sản phẩm để thêm vào giỏ hàng hộ
              if (price <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Sản phẩm này chưa có giá, không thể thêm vào đơn.'),
                    backgroundColor: Colors.orange));
                return;
              }

              // TODO: Hiển thị dialog để người dùng nhập số lượng.
              // Tạm thời, chúng ta sẽ mặc định số lượng là 1.
              final cartItem = CartItemModel(
                productId: product.id,
                productName: product.name,
                imageUrl: product.imageUrl,
                price: price,
                itemUnitName: product.displayUnit,
                quantity: 1, // Mặc định là 1
                quantityPerPackage: 1, // Cần lấy từ product model nếu có
                caseUnitName: 'Thùng', // Cần lấy từ product model nếu có
                categoryId: product.categoryId,
              );
              Navigator.of(context).pop(cartItem);
            } else {
              // Logic cũ: Đi đến trang chi tiết sản phẩm
              Navigator.of(context).push(ProductDetailPage.route(product.id));
            }
          },
        );
      },
    );
  }
}