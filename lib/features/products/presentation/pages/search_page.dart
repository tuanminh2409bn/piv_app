// lib/features/products/presentation/pages/search_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:piv_app/features/home/data/models/product_model.dart';
import 'package:piv_app/features/products/presentation/pages/product_detail_page.dart';
import 'package:piv_app/features/search/bloc/search_cubit.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  static PageRoute<void> route() {
    return MaterialPageRoute<void>(
      builder: (_) => BlocProvider(
        create: (_) => sl<SearchCubit>()..loadSearchHistory(),
        child: const SearchView(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const SearchView();
  }
}

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
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
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
              onPressed: () {
                _searchController.clear();
                context.read<SearchCubit>().searchProducts('');
              },
            )
                : null,
          ),
          onSubmitted: _onSubmitted,
          onChanged: (query) {
            // Thêm một chút trễ để người dùng gõ xong rồi mới tìm
            // Điều này giúp tránh gọi API liên tục, nhưng với logic hiện tại thì không quá cần thiết
            // vì getAllProducts chỉ gọi 1 lần.
          },
        ),
      ),
      body: BlocBuilder<SearchCubit, SearchState>(
        builder: (context, state) {
          if (_searchController.text.isEmpty) {
            return _buildSearchHistory(context, state);
          } else {
            if (state.status == SearchStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.searchResults.isEmpty) {
              return const Center(child: Text('Không tìm thấy kết quả nào.'));
            }
            return _buildSearchResultsList(context, state.searchResults);
          }
        },
      ),
    );
  }

  Widget _buildSearchHistory(BuildContext context, SearchState state) {
    if (state.status == SearchStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.searchHistory.isEmpty) {
      return const Center(child: Text('Chưa có lịch sử tìm kiếm.'));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tìm kiếm gần đây', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              if (state.searchHistory.isNotEmpty)
                TextButton(
                  onPressed: () => context.read<SearchCubit>().clearHistory(),
                  child: const Text('Xóa tất cả'),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: state.searchHistory.length,
            itemBuilder: (context, index) {
              final term = state.searchHistory[index];
              return ListTile(
                leading: const Icon(Icons.history),
                title: Text(term),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => context.read<SearchCubit>().removeSearchTerm(term),
                ),
                onTap: () {
                  _searchController.text = term;
                  _searchController.selection = TextSelection.fromPosition(TextPosition(offset: term.length));
                  _onSubmitted(term);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResultsList(BuildContext context, List<ProductModel> products) {
    final authState = context.read<AuthBloc>().state;
    String userRole = 'agent_2';
    if (authState is AuthAuthenticated) {
      userRole = authState.user.role;
    }
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return ListView.separated(
      padding: const EdgeInsets.all(16.0),
      itemCount: products.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final product = products[index];
        final price = product.getPriceForRole(userRole);
        final unit = product.displayUnit;
        return ListTile(
          leading: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(product.imageUrl, width: 70, height: 70, fit: BoxFit.cover, errorBuilder: (c,e,s) => Container(color: Colors.grey.shade200, child: const Icon(Icons.image)))),
          title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('${currencyFormatter.format(price)} / $unit', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w500)),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => Navigator.of(context).push(ProductDetailPage.route(product.id)),
        );
      },
    );
  }
}