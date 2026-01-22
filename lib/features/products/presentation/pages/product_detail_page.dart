// lib/features/products/presentation/pages/product_detail_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/core/theme/app_theme.dart';
import 'package:piv_app/data/models/cart_item_model.dart';
import 'package:piv_app/data/models/packaging_option_model.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:piv_app/features/auth/presentation/pages/login_page.dart';
import 'package:piv_app/features/cart/presentation/bloc/cart_cubit.dart';
import 'package:piv_app/features/cart/presentation/pages/cart_page.dart';
import 'package:piv_app/features/cart/presentation/widgets/cart_icon_with_badge.dart';
import 'package:piv_app/features/checkout/presentation/pages/checkout_page.dart';
import 'package:piv_app/features/home/data/models/product_model.dart';
import 'package:piv_app/features/products/presentation/bloc/product_detail_cubit.dart';
import 'package:piv_app/features/wishlist/presentation/widgets/wishlist_button.dart';
import 'package:url_launcher/url_launcher.dart';

class ProductDetailPage extends StatelessWidget {
  final String productId;
  const ProductDetailPage({super.key, required this.productId});

  static PageRoute<void> route(String productId) {
    return MaterialPageRoute<void>(
      builder: (_) => ProductDetailPage(productId: productId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ProductDetailCubit>()..fetchProductDetail(productId),
      child: const ProductDetailView(),
    );
  }
}

class ProductDetailView extends StatelessWidget {
  const ProductDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    bool canViewPrice = false;
    bool isGuest = true;
    String userRole = 'guest';

    if (authState is AuthAuthenticated) {
      isGuest = authState.user.isGuest;
      userRole = authState.user.role;
      if (!isGuest && authState.user.status == 'active') {
        canViewPrice = true;
      }
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(), // Ẩn bàn phím khi chạm ra ngoài
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        body: BlocListener<CartCubit, CartState>(
          listener: (context, cartState) {
            if (cartState.status == CartStatus.itemAddedSuccess) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(
                  content: const Text('Đã thêm sản phẩm vào giỏ hàng!'),
                  backgroundColor: AppTheme.secondaryGreen,
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ));
            } else if (cartState.status == CartStatus.error) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(
                  content: Text(cartState.errorMessage ?? 'Thêm vào giỏ hàng thất bại.'),
                  backgroundColor: AppTheme.errorRed,
                ));
            }
          },
          child: BlocBuilder<ProductDetailCubit, ProductDetailState>(
            builder: (context, state) {
              if (state.status == ProductDetailStatus.loading || state.status == ProductDetailStatus.initial) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.status == ProductDetailStatus.error || state.product == null) {
                return _buildErrorView(context, state.errorMessage);
              }

              final product = state.product!;
              final selectedOption = state.selectedPackagingOption;
              final bottomPadding = MediaQuery.of(context).viewInsets.bottom; // Lấy chiều cao bàn phím

              return Stack(
                children: [
                  CustomScrollView(
                    slivers: <Widget>[
                      _buildSliverAppBar(context, product, isGuest),
                      SliverToBoxAdapter(
                        child: Padding(
                          // Thêm padding bottom động để đẩy nội dung lên
                          // viewInsets.bottom: Bàn phím
                          // padding.bottom: Thanh điều hướng
                          padding: EdgeInsets.fromLTRB(16, 16, 16, 150 + bottomPadding + MediaQuery.of(context).padding.bottom),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. Tên và Giá
                              _buildTitleAndPrice(context, product, selectedOption, userRole, canViewPrice),
                              const SizedBox(height: 24),

                              // 2. Chọn Quy cách (Chips)
                              if (product.packingOptions.isNotEmpty) ...[
                                Text('QUY CÁCH ĐÓNG GÓI', style: _sectionTitleStyle(context)),
                                const SizedBox(height: 12),
                                _buildPackagingChips(context, product.packingOptions, selectedOption),
                                const SizedBox(height: 24),
                              ],

                              // 3. Chọn Số lượng
                              Text('SỐ LƯỢNG', style: _sectionTitleStyle(context)),
                              const SizedBox(height: 12),
                              _buildQuantitySelector(context, state.quantity),
                              
                              const SizedBox(height: 24),
                              const Divider(),
                              const SizedBox(height: 16),

                              // 4. Mô tả sản phẩm
                              _buildExpandableDescription(context, product.description),
                              
                              const SizedBox(height: 24),

                              // 5. Thông số kỹ thuật
                              if (product.attributes != null && product.attributes!.isNotEmpty) ...[
                                Text('THÔNG SỐ KỸ THUẬT', style: _sectionTitleStyle(context)),
                                const SizedBox(height: 12),
                                _buildAttributesTable(context, product.attributes!),
                                const SizedBox(height: 24),
                              ],
                            ],
                          ),
                        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
                      ),
                    ],
                  ),
                  
                  // Bottom Sticky Bar (Chỉ hiển thị khi bàn phím tắt hoặc vẫn hiển thị đè lên)
                  // Để tránh che bàn phím, ta có thể ẩn nó khi bàn phím hiện, hoặc giữ nguyên
                  // Ở đây ta giữ nguyên vì nó là sticky bottom bar
                  if (!isGuest)
                    _buildStickyBottomBar(context, product, state.quantity, selectedOption, userRole),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  TextStyle _sectionTitleStyle(BuildContext context) {
    return TextStyle(
      color: AppTheme.textGrey,
      fontSize: 12,
      fontWeight: FontWeight.bold,
      letterSpacing: 1.2,
    );
  }

  Widget _buildSliverAppBar(BuildContext context, ProductModel product, bool isGuest) {
    return SliverAppBar(
      expandedHeight: 350.0,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      actions: [
        if (!isGuest)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                shape: BoxShape.circle,
              ),
              child: WishlistButton(productId: product.id, color: AppTheme.primaryGreen),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              shape: BoxShape.circle,
            ),
            child: CartIconWithBadge(
              iconColor: AppTheme.primaryGreen,
              onPressed: () => Navigator.of(context).push(CartPage.route()),
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: Colors.white),
            Hero(
              tag: 'prod_img_${product.id}',
              child: GestureDetector(
                onTap: () {},
                child: (product.imageUrl.isNotEmpty)
                    ? Image.network(product.imageUrl, fit: BoxFit.cover)
                    : const Center(child: Icon(Icons.image_not_supported, size: 80, color: Colors.grey)),
              ),
            ),
            if (product.isPrivate)
              Positioned(
                bottom: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.errorRed,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.red.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
                  ),
                  child: const Text(
                    'SẢN PHẨM ĐỘC QUYỀN',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleAndPrice(BuildContext context, ProductModel product, PackagingOptionModel? selectedOption, String userRole, bool canViewPrice) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final priceForRole = selectedOption?.getPriceForRole(userRole) ?? 0.0;
    final bool showContact = canViewPrice && priceForRole <= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.name,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, height: 1.3),
        ),
        const SizedBox(height: 8),
        if (showContact)
          OutlinedButton.icon(
            onPressed: () async {
              final Uri launchUri = Uri(scheme: 'tel', path: '0345012346');
              if (await canLaunchUrl(launchUri)) {
                await launchUrl(launchUri);
              }
            },
            icon: const Icon(Icons.phone),
            label: const Text('Liên hệ báo giá: 0345.012.346'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange,
              side: const BorderSide(color: Colors.orange),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          )
        else if (canViewPrice)
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currencyFormatter.format(priceForRole),
                style: TextStyle(
                  color: AppTheme.primaryGreen,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              if (selectedOption != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text(
                    '/ ${selectedOption.unit}',
                    style: TextStyle(color: AppTheme.textGrey, fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
            ],
          )
        else
          TextButton.icon(
            onPressed: () => Navigator.of(context).pushAndRemoveUntil(LoginPage.route(), (route) => false),
            icon: const Icon(Icons.lock_outline, size: 16),
            label: const Text('Đăng nhập để xem giá'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryGreen,
              backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
            ),
          ),
      ],
    );
  }

  Widget _buildPackagingChips(BuildContext context, List<PackagingOptionModel> options, PackagingOptionModel? selectedOption) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: options.map((option) {
        final isSelected = selectedOption == option;
        return ChoiceChip(
          label: Text(option.name),
          selected: isSelected,
          onSelected: (bool selected) {
            if (selected) {
              context.read<ProductDetailCubit>().selectPackagingOption(option);
            }
          },
          selectedColor: AppTheme.primaryGreen,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textDark,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? Colors.transparent : Colors.grey.shade300,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        );
      }).toList(),
    );
  }

  Widget _buildQuantitySelector(BuildContext context, int quantity) {
    return _QuantityInput(
      quantity: quantity,
      onChanged: (val) => context.read<ProductDetailCubit>().setQuantity(val),
      onIncrement: () => context.read<ProductDetailCubit>().incrementQuantity(),
      onDecrement: () => context.read<ProductDetailCubit>().decrementQuantity(),
    );
  }

  Widget _buildExpandableDescription(BuildContext context, String? description) {
    if (description == null || description.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('MÔ TẢ SẢN PHẨM', style: _sectionTitleStyle(context)),
        const SizedBox(height: 12),
        Text(
          description,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6, color: AppTheme.textDark),
        ),
      ],
    );
  }

  Widget _buildAttributesTable(BuildContext context, Map<String, dynamic> attributes) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: attributes.entries.map((entry) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    entry.key,
                    style: const TextStyle(color: AppTheme.textGrey, fontWeight: FontWeight.w500),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    entry.value.toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStickyBottomBar(BuildContext context, ProductModel product, int quantity, PackagingOptionModel? selectedOption, String userRole) {
    final cartStatus = context.watch<CartCubit>().state.status;
    final bool canAddToCart = selectedOption != null;
    final double price = selectedOption?.getPriceForRole(userRole) ?? 0.0;
    
    if (price <= 0) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          // Bỏ padding cứng ở đây
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, -5),
              )
            ],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16.0), // Padding đều 16
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                      final Uri launchUri = Uri(scheme: 'tel', path: '0345012346');
                      if (await canLaunchUrl(launchUri)) {
                        await launchUrl(launchUri);
                      }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.phone),
                  label: const Text('LIÊN HỆ ĐẶT HÀNG'),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        // Bỏ padding cứng ở đây
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            )
          ],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16.0), // Padding đều 16
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: canAddToCart && cartStatus != CartStatus.itemAdding
                        ? () => context.read<CartCubit>().addProduct(product: product, selectedOption: selectedOption, quantity: quantity)
                        : null,
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('Thêm vào giỏ'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: canAddToCart ? AppTheme.primaryGreen : Colors.grey),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: canAddToCart
                        ? () => _showBuyNowDialog(context, product, userRole, quantity)
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 8,
                      shadowColor: AppTheme.primaryGreen.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('MUA NGAY'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().slideY(begin: 1, end: 0, duration: 500.ms, curve: Curves.easeOutQuart);
  }

  Widget _buildErrorView(BuildContext context, String? errorMessage) {
    return Scaffold(
      appBar: AppBar(title: const Text("Lỗi")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.errorRed),
            const SizedBox(height: 16),
            Text(errorMessage ?? 'Không thể tải chi tiết sản phẩm.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Quay lại'),
            )
          ],
        ),
      ),
    );
  }
}

class _QuantityInput extends StatefulWidget {
  final int quantity;
  final ValueChanged<int> onChanged;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _QuantityInput({
    required this.quantity,
    required this.onChanged,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  State<_QuantityInput> createState() => _QuantityInputState();
}

class _QuantityInputState extends State<_QuantityInput> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.quantity.toString());
  }

  @override
  void didUpdateWidget(covariant _QuantityInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.quantity != widget.quantity) {
      if (int.tryParse(_controller.text) != widget.quantity) {
         _controller.text = widget.quantity.toString();
         _controller.selection = TextSelection.fromPosition(TextPosition(offset: _controller.text.length));
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSubmitted(String value) {
    final int? newQty = int.tryParse(value);
    if (newQty != null && newQty > 0) {
      widget.onChanged(newQty);
    } else {
      _controller.text = widget.quantity.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: widget.quantity > 1 ? widget.onDecrement : null,
            color: AppTheme.textGrey,
          ),
          SizedBox(
            width: 50,
            child: TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              textAlign: TextAlign.center,
              // TỐI ƯU CHO CẢ ANDROID VÀ IPHONE:
              // scrollPadding này ép buộc ScrollView cuộn lên sao cho mép dưới của TextField
              // cách mép trên của bàn phím một khoảng là 200px.
              // 200px này đủ để "vượt qua" chiều cao của thanh nút bấm (khoảng 80-100px).
              scrollPadding: const EdgeInsets.only(bottom: 200),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onSubmitted: (val) {
                _handleSubmitted(val);
                FocusScope.of(context).unfocus();
              },
              onTapOutside: (_) {
                 _handleSubmitted(_controller.text);
                 FocusScope.of(context).unfocus();
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: widget.onIncrement,
            color: AppTheme.primaryGreen,
          ),
        ],
      ),
    );
  }
}

Future<void> _showBuyNowDialog(BuildContext context, ProductModel product, String userRole, int quantity) async {
  if (product.packingOptions.isEmpty) return;
  PackagingOptionModel? selectedOption = product.packingOptions.first;

  showDialog<PackagingOptionModel>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xác nhận mua ngay'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<PackagingOptionModel>(
              value: selectedOption,
              isExpanded: true,
              items: product.packingOptions.map((o) => DropdownMenuItem(value: o, child: Text(o.name))).toList(),
              onChanged: (v) => setState(() => selectedOption = v),
              decoration: const InputDecoration(labelText: 'Quy cách', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('HỦY')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, selectedOption),
            child: const Text('MUA'),
          ),
        ],
      ),
    ),
  ).then((option) {
    if (option != null) {
      final item = CartItemModel(
        productId: product.id, productName: product.name, imageUrl: product.imageUrl,
        price: option.getPriceForRole(userRole), itemUnitName: option.unit,
        quantity: quantity, quantityPerPackage: option.quantityPerPackage,
        caseUnitName: option.name, categoryId: product.categoryId,
      );
      Navigator.of(context).push(CheckoutPage.route(buyNowItems: [item]));
    }
  });
}