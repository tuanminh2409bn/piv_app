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

class SearchPage extends StatelessWidget {
  final bool isSelectionMode;
  final String? targetUserRole; // Vẫn giữ để hiển thị giá
  final String? targetAgentId;  // ID của đại lý

  const SearchPage({
    super.key,
    this.isSelectionMode = false,
    this.targetUserRole,
    this.targetAgentId,
  });

  static PageRoute<ProductModel?> route({
    bool isSelectionMode = false,
    String? targetUserRole,
    String? targetAgentId,
  }) {
    return MaterialPageRoute<ProductModel?>(
      builder: (_) => BlocProvider(
        create: (_) => sl<SearchCubit>()..searchProducts('', targetAgentId: targetAgentId),
        child: SearchPage(
          isSelectionMode: isSelectionMode,
          targetUserRole: targetUserRole,
          targetAgentId: targetAgentId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SearchView(
      isSelectionMode: isSelectionMode,
      targetUserRole: targetUserRole,
      targetAgentId: targetAgentId,
    );
  }
}

class SearchView extends StatefulWidget {
  final bool isSelectionMode;
  final String? targetUserRole;
  final String? targetAgentId;

  const SearchView({
    super.key,
    required this.isSelectionMode,
    this.targetUserRole,
    this.targetAgentId,
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
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 400), () {
        if (mounted) {
          context.read<SearchCubit>().searchProducts(
            _searchController.text,
            targetAgentId: widget.targetAgentId,
          );
        }
      });
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
      context.read<SearchCubit>().searchProducts(
        query.trim(),
        targetAgentId: widget.targetAgentId,
      );
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

  Widget _buildSearchResultsList(
      BuildContext context,
      List<ProductModel> products,
      bool isSelectionMode,
      String? targetUserRole,
      ) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    String userRole;
    if (isSelectionMode && targetUserRole != null) {
      userRole = targetUserRole;
    } else {
      final authState = context.read<AuthBloc>().state;
      userRole = (authState is AuthAuthenticated) ? authState.user.role : 'agent_2';
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16.0),
      itemCount: products.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final product = products[index];
        final price = product.getPriceForRole(userRole);
        final unit = product.displayUnit;
        return ListTile(
          // --- SỬA ĐỔI: Cập nhật hiển thị nhãn SẢN PHẨM ĐỘC QUYỀN ---
          leading: Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                  borderRadius: BorderRadius.circular(8), // Bo góc ảnh là 8
                  child: Image.network(product.imageUrl,
                      width: 70, height: 70, fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                          width: 70, height: 70,
                          color: Colors.grey.shade200, child: const Icon(Icons.image)))),

              // Nhãn Sản Phẩm Độc Quyền
              if (product.isPrivate)
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    // Padding nhỏ hơn một chút so với trang chủ để vừa với ảnh 70x70
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(8), // Khớp với bo góc của ảnh
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                            'SẢN PHẨM ĐỘC QUYỀN',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 4, // Font nhỏ hơn (7-8) để không bị tràn quá nhiều
                                fontWeight: FontWeight.bold
                            )
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          // --- KẾT THÚC SỬA ĐỔI ---

          title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(
              price > 0 ? '${currencyFormatter.format(price)} / $unit' : 'Chưa có giá',
              style: TextStyle(
                  color: price > 0 ? Theme.of(context).colorScheme.primary : Colors.grey,
                  fontWeight: FontWeight.w500)),
          trailing: Icon(isSelectionMode ? Icons.add_shopping_cart : Icons.arrow_forward_ios, size: 16),
          onTap: () {
            if (isSelectionMode) {
              if (product.packingOptions.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Sản phẩm này chưa có quy cách đóng gói.'),
                    backgroundColor: Colors.orange));
                return;
              }
              Navigator.of(context).pop(product);
            } else {
              Navigator.of(context).push(ProductDetailPage.route(product.id));
            }
          },
        );
      },
    );
  }
}