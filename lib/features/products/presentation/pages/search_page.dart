// lib/features/products/presentation/pages/search_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/core/theme/app_theme.dart'; // Đảm bảo AppTheme có sẵn hoặc dùng màu cứng nếu cần
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:piv_app/features/home/data/models/product_model.dart';
import 'package:piv_app/features/products/presentation/pages/product_detail_page.dart';
import 'package:piv_app/features/search/bloc/search_cubit.dart';

class SearchPage extends StatelessWidget {
  final bool isSelectionMode;
  final String? targetUserRole;
  final String? targetAgentId;

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
        create: (_) => sl<SearchCubit>()
          ..loadSearchHistory()
          ..searchProducts('', targetAgentId: targetAgentId),
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
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounce;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _isSearching = _searchController.text.isNotEmpty;
    });

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        context.read<SearchCubit>().searchProducts(
              _searchController.text,
              targetAgentId: widget.targetAgentId,
              saveToHistory: false, // KHÔNG lưu lịch sử khi đang gõ
            );
      }
    });
  }

  void _onSubmitted(String query) {
    if (query.trim().isNotEmpty) {
      context.read<SearchCubit>().searchProducts(
            query.trim(),
            targetAgentId: widget.targetAgentId,
            saveToHistory: true, // LƯU lịch sử khi nhấn Enter/Submit
          );
      _searchFocusNode.unfocus();
    }
  }

  void _onHistoryTap(String term) {
    _searchController.text = term;
    _searchController.selection = TextSelection.fromPosition(TextPosition(offset: term.length));
    _onSubmitted(term);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchHeader(context),
            Expanded(
              child: BlocBuilder<SearchCubit, SearchState>(
                builder: (context, state) {
                  if (state.status == SearchStatus.loading) {
                    return _buildLoadingShimmer();
                  }

                  // Hiển thị lịch sử nếu chưa nhập gì
                  if (_searchController.text.isEmpty && state.searchHistory.isNotEmpty) {
                    return _buildSearchHistory(state.searchHistory);
                  }

                  if (state.searchResults.isEmpty) {
                    // Nếu đang nhập mà không thấy
                    if (_searchController.text.isNotEmpty) {
                      return _buildEmptyState();
                    }
                    // Trường hợp mới vào chưa có lịch sử và chưa search (thường load all thì sẽ có data, nhưng nếu backend rỗng)
                    return const SizedBox(); 
                  }

                  return _buildSearchResultsGrid(
                    context,
                    state.searchResults,
                    widget.isSelectionMode,
                    widget.targetUserRole,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          BackButton(onPressed: () => Navigator.of(context).pop()),
          Expanded(
            child: Hero(
              tag: 'search_bar',
              child: Material(
                type: MaterialType.transparency,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    autofocus: true,
                    textInputAction: TextInputAction.search,
                    onSubmitted: _onSubmitted,
                    style: const TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm sản phẩm...',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                      suffixIcon: _isSearching
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.clear, size: 20),
                                  color: Colors.grey,
                                  onPressed: () {
                                    _searchController.clear();
                                    context.read<SearchCubit>().loadSearchHistory();
                                  },
                                ),
                                Container(
                                  width: 1,
                                  height: 20,
                                  color: Colors.grey[300],
                                ),
                                IconButton(
                                  icon: const Icon(Icons.arrow_forward, size: 20),
                                  color: AppTheme.primaryGreen,
                                  tooltip: 'Tìm kiếm',
                                  onPressed: () => _onSubmitted(_searchController.text),
                                ),
                              ],
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Có thể thêm nút Filter ở đây trong tương lai
        ],
      ),
    );
  }

  Widget _buildSearchHistory(List<String> history) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Lịch sử tìm kiếm',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              TextButton(
                onPressed: () => context.read<SearchCubit>().clearHistory(),
                child: const Text('Xóa tất cả', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: history.map((term) {
              return InkWell(
                onTap: () => _onHistoryTap(term),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Text(term, style: const TextStyle(color: Colors.black87)),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () => context.read<SearchCubit>().removeSearchTerm(term),
                        child: Icon(Icons.close, size: 14, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn().slideX(begin: 0.1, end: 0);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultsGrid(
    BuildContext context,
    List<ProductModel> products,
    bool isSelectionMode,
    String? targetUserRole,
  ) {
    // Xác định role để hiển thị giá
    String userRole;
    if (isSelectionMode && targetUserRole != null) {
      userRole = targetUserRole;
    } else {
      final authState = context.read<AuthBloc>().state;
      userRole = (authState is AuthAuthenticated) ? authState.user.role : 'agent_2';
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final price = product.getPriceForRole(userRole);
        
        // Hiệu ứng xuất hiện lần lượt (Staggered)
        return _ProductGridItem(
          product: product,
          price: price,
          isSelectionMode: isSelectionMode,
        ).animate(delay: (50 * index).ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
      },
    );
  }

  Widget _buildLoadingShimmer() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 14, width: 120, color: Colors.grey[300]),
                      const SizedBox(height: 8),
                      Container(height: 14, width: 80, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Container(height: 18, width: 100, color: Colors.grey[300]),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms, color: Colors.white.withOpacity(0.5));
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search_off_rounded, size: 64, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          const Text(
            'Không tìm thấy sản phẩm',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          Text(
            'Hãy thử tìm kiếm với từ khóa khác',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ).animate().fadeIn().scale(),
    );
  }
}

class _ProductGridItem extends StatelessWidget {
  final ProductModel product;
  final double price;
  final bool isSelectionMode;

  const _ProductGridItem({
    required this.product,
    required this.price,
    required this.isSelectionMode,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Section
              Expanded(
                flex: 4,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: Image.network(
                        product.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[100],
                          child: const Icon(Icons.image_not_supported, color: Colors.grey),
                        ),
                      ),
                    ),
                    if (product.isPrivate)
                      Positioned(
                        top: 0,
                        left: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFD32F2F), Color(0xFFEF5350)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(16),
                              bottomRight: Radius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'ĐỘC QUYỀN',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              // Info Section
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10), // Giảm padding
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13, // Giảm font size
                          height: 1.2,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.displayUnit,
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                      
                      const Spacer(), // Dùng Spacer để đẩy giá xuống đáy
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              price > 0 ? currencyFormatter.format(price) : 'Liên hệ',
                              style: TextStyle(
                                color: price > 0 ? const Color(0xFF1565C0) : Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 14, // Giảm font size giá tiền một chút
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isSelectionMode)
                            Container(
                              margin: const EdgeInsets.only(left: 4),
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryGreen, 
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.add, color: Colors.white, size: 14),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
