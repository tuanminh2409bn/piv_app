// lib/features/admin/presentation/pages/agent_product_visibility_page.dart

import 'package:flutter/material.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/data/models/user_model.dart';
import 'package:piv_app/features/home/data/models/product_model.dart';
import 'package:piv_app/features/home/domain/repositories/home_repository.dart';
import 'package:piv_app/features/profile/domain/repositories/user_profile_repository.dart';

class AgentProductVisibilityPage extends StatefulWidget {
  final UserModel agent;
  const AgentProductVisibilityPage({super.key, required this.agent});

  @override
  State<AgentProductVisibilityPage> createState() => _AgentProductVisibilityPageState();
}

class _AgentProductVisibilityPageState extends State<AgentProductVisibilityPage> {
  final _homeRepository = sl<HomeRepository>();
  final _userProfileRepository = sl<UserProfileRepository>();
  
  List<ProductModel> _allProducts = [];
  Set<String> _hiddenProductIds = {};
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final productsResult = await _homeRepository.getAllProductsForAdmin();
    final hiddenResult = await _userProfileRepository.getHiddenProductIds(widget.agent.id);

    productsResult.fold(
      (l) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.message))),
      (r) => _allProducts = r,
    );

    hiddenResult.fold(
      (l) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.message))),
      (r) => _hiddenProductIds = r.toSet(),
    );

    setState(() => _isLoading = false);
  }

  Future<void> _toggleVisibility(String productId, bool currentlyHidden) async {
    final newHiddenState = !currentlyHidden;
    final result = await _userProfileRepository.toggleProductVisibility(
      widget.agent.id,
      productId,
      newHiddenState,
    );

    result.fold(
      (l) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.message))),
      (r) {
        setState(() {
          if (newHiddenState) {
            _hiddenProductIds.add(productId);
          } else {
            _hiddenProductIds.remove(productId);
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = _allProducts.where((p) => 
      p.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Hiển thị SP: ${widget.agent.displayName}'),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Tìm kiếm sản phẩm...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    final isHidden = _hiddenProductIds.contains(product.id);
                    return ListTile(
                      leading: product.imageUrl.isNotEmpty 
                        ? Image.network(product.imageUrl, width: 50, height: 50, fit: BoxFit.cover)
                        : const Icon(Icons.image_not_supported),
                      title: Text(product.name),
                      subtitle: Text(isHidden ? 'Đang ẩn' : 'Đang hiển thị', 
                        style: TextStyle(color: isHidden ? Colors.red : Colors.green)),
                      trailing: Switch(
                        value: !isHidden, 
                        onChanged: (visible) => _toggleVisibility(product.id, isHidden),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
    );
  }
}
