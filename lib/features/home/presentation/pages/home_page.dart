//lib/features/home/presentation/pages/home_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/core/theme/app_theme.dart';
import 'package:piv_app/core/theme/nature_background_painter.dart';
import 'package:piv_app/features/cart/presentation/pages/cart_page.dart';
import 'package:piv_app/features/cart/presentation/widgets/cart_icon_with_badge.dart';
import 'package:piv_app/features/notifications/presentation/widgets/notification_icon_with_badge.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:piv_app/features/home/presentation/bloc/home_cubit.dart';
import 'package:piv_app/features/home/data/models/category_model.dart';
import 'package:piv_app/features/home/data/models/banner_model.dart';
import 'package:piv_app/features/home/data/models/product_model.dart';
import 'package:piv_app/data/models/news_article_model.dart';
import 'package:piv_app/features/news/presentation/pages/news_detail_page.dart';
import 'package:piv_app/features/products/presentation/pages/product_detail_page.dart';
import 'package:piv_app/features/products/presentation/pages/category_products_page.dart';
import 'package:piv_app/features/products/presentation/pages/search_page.dart';
import 'package:piv_app/features/auth/presentation/pages/login_page.dart';

import 'package:piv_app/features/cart/presentation/bloc/cart_cubit.dart';
import 'package:piv_app/features/checkout/presentation/pages/checkout_page.dart';
import 'package:piv_app/data/models/cart_item_model.dart';
import 'package:piv_app/data/models/packaging_option_model.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomeView();
  }
}

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. HỌA TIẾT NỀN
          Positioned.fill(
            child: CustomPaint(
              painter: NatureBackgroundPainter(
                color1: AppTheme.primaryGreen.withValues(alpha: 0.15),
                color2: AppTheme.secondaryGreen.withValues(alpha: 0.1),
                accent: AppTheme.accentGold.withValues(alpha: 0.25),
              ),
            ),
          ),

          // 2. NỘI DUNG CHÍNH
          BlocBuilder<HomeCubit, HomeState>(
            builder: (context, state) {
              if (state.status == HomeStatus.loading || state.status == HomeStatus.initial) {
                return const _ShimmerLoadingView();
              }
              if (state.status == HomeStatus.error) {
                return _ErrorView(errorMessage: state.errorMessage);
              }

              return RefreshIndicator.adaptive(
                onRefresh: () async => context.read<HomeCubit>().refreshHomeData(),
                child: CustomScrollView(
                  slivers: [
                    _HomeAppBar(),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    
                    // Header chào mừng
                    _WelcomeHeader(),
                    
                    // Banner
                    _BannerCarousel(banners: state.banners),
                    
                    // Danh mục
                    _SectionHeader(title: 'DANH MỤC NỔI BẬT'),
                    _CategoriesRow(categories: state.categories), 
                    
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),

                    // Sản phẩm
                    _SectionHeader(title: 'SẢN PHẨM NỔI BẬT'),
                    _FeaturedProductsGrid(products: state.featuredProducts),
                    
                    // Tin tức
                    _SectionHeader(title: 'TIN TỨC & SỰ KIỆN'),
                    _NewsList(newsArticles: state.newsArticles),
                    
                    const SliverToBoxAdapter(child: SizedBox(height: 120)),
                  ],
                ), 
              );
            },
          ),
        ],
      ),
    );
  }
}

// --- SLIVER & SECTION WIDGETS ---

class _HomeAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      floating: true,
      snap: true,
      elevation: 0,
      scrolledUnderElevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      surfaceTintColor: Colors.white,
      backgroundColor: Colors.white.withValues(alpha: 0.95),
      title: GestureDetector(
        onTap: () => Navigator.of(context).push(SearchPage.route()),
        child: Hero( 
          tag: 'search_bar',
          child: Material(
            color: Colors.transparent,
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Icon(Icons.search, color: AppTheme.textGrey, size: 20),
                  const SizedBox(width: 8),
                  Text('Tìm kiếm sản phẩm...', style: TextStyle(color: AppTheme.textGrey, fontSize: 14)),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        const NotificationIconWithBadge()
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .shake(delay: 2000.ms, duration: 1000.ms, hz: 2, rotation: 0.1), 
        CartIconWithBadge(
          onPressed: () => Navigator.of(context).push(CartPage.route()),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    String userIdentifier = 'Khách';

    if (authState is AuthAuthenticated) {
      userIdentifier = authState.user.displayName ?? authState.user.email ?? 'Đại lý';
    }
    
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chào mừng trở lại,',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.textGrey),
            ),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [AppTheme.primaryGreen, AppTheme.secondaryGreen],
              ).createShader(bounds),
              child: Text(
                userIdentifier,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white, 
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ).animate().slideX(begin: -0.2, end: 0, duration: 500.ms, curve: Curves.easeOut), // Animate nội dung bên trong
      ),
    );
  }
}

class _BannerCarousel extends StatelessWidget {
  final List<BannerModel> banners;
  const _BannerCarousel({required this.banners});

  @override
  Widget build(BuildContext context) {
    if (banners.isEmpty) return const SizedBox.shrink();

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: CarouselSlider.builder(
          itemCount: banners.length,
          itemBuilder: (context, index, realIndex) {
            final banner = banners[index];
            return GestureDetector(
              onTap: () { /* Handle banner tap */ },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: AppTheme.primaryGreen.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))
                  ]
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    banner.imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image_outlined)),
                  ),
                ),
              ),
            );
          },
          options: CarouselOptions(
            aspectRatio: 16 / 9,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 5),
            enlargeCenterPage: true,
            viewportFraction: 0.9,
            enlargeStrategy: CenterPageEnlargeStrategy.zoom,
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            autoPlayCurve: Curves.fastOutSlowIn,
          ),
        ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOutBack), // Animate nội dung
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  const _SectionHeader({required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.only(left: 8),
              decoration: const BoxDecoration(
                border: Border(left: BorderSide(color: AppTheme.accentGold, width: 4))
              ),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            if (onSeeAll != null)
              TextButton(
                onPressed: onSeeAll,
                child: const Text('Xem tất cả'),
              )
          ],
        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0), // Animate nội dung
      ),
    );
  }
}

class _CategoriesRow extends StatelessWidget {
  final List<CategoryModel> categories;
  const _CategoriesRow({required this.categories});

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return _buildPlaceholder('Chưa có danh mục nào');

    final itemsToShow = categories.length > 3 ? categories.sublist(0, 3) : categories;

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverToBoxAdapter(
        child: Row(
          children: itemsToShow.asMap().entries.map((entry) {
            final index = entry.key;
            final category = entry.value;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: InkWell(
                  onTap: () => Navigator.of(context).push(CategoryProductsPage.route(category)),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Hero(
                              tag: 'cat_${category.id}',
                              child: Image.network(
                                category.imageUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (c, e, s) => const Icon(Icons.category_outlined, color: AppTheme.primaryGreen, size: 32),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: Text(
                              category.name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: (100 * index).ms).slideX(begin: 0.2, end: 0, curve: Curves.easeOut),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _FeaturedProductsGrid extends StatelessWidget {
  final List<ProductModel> products;
  const _FeaturedProductsGrid({required this.products});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return _buildPlaceholder('Không có sản phẩm nổi bật');
    
    final double screenWidth = MediaQuery.of(context).size.width;
    final double childAspectRatio = (screenWidth / 2) / 330; 

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid.builder(
        itemCount: products.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: childAspectRatio, 
        ),
        itemBuilder: (context, index) {
          final product = products[index];
          return _FeaturedProductCard(product: product);
        },
      ),
    );
  }
}

class _FeaturedProductCard extends StatelessWidget {
  final ProductModel product;
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  _FeaturedProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    bool canViewPrice = false;
    String userRole = 'guest';

    if (authState is AuthAuthenticated) {
      userRole = authState.user.role;
      if (!authState.user.isGuest && authState.user.status == 'active') {
        canViewPrice = true;
      }
    }
    final price = product.getPriceForRole(userRole);

    return GestureDetector(
      onTap: () => Navigator.of(context).push(ProductDetailPage.route(product.id)),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.0,
              child: Stack(
                children: [
                  Hero(
                    tag: 'prod_img_${product.id}',
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: (product.imageUrl.isNotEmpty)
                          ? Image.network(product.imageUrl, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: Colors.grey.shade100, child: const Icon(Icons.image, size: 40, color: Colors.grey)))
                          : Container(color: Colors.grey.shade100, child: const Icon(Icons.image, size: 40, color: Colors.grey)),
                    ),
                  ),
                  if (product.isPrivate)
                    Positioned(
                      top: 0, left: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: const BoxDecoration(color: Colors.red, borderRadius: BorderRadius.only(topLeft: Radius.circular(16), bottomRight: Radius.circular(12))),
                        child: const Text('ĐỘC QUYỀN', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, height: 1.2),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (canViewPrice)
                      if (price > 0)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Text(
                                currencyFormatter.format(price),
                                style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 15),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Material(
                              color: AppTheme.secondaryGreen,
                              borderRadius: BorderRadius.circular(8),
                              child: InkWell(
                                onTap: () async => _handleAddToCart(context, product, userRole),
                                borderRadius: BorderRadius.circular(8),
                                child: const Padding(
                                  padding: EdgeInsets.all(6.0),
                                  child: Icon(Icons.add_shopping_cart, color: Colors.white, size: 18),
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                         SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final Uri launchUri = Uri(scheme: 'tel', path: '0345012346');
                              if (await canLaunchUrl(launchUri)) {
                                await launchUrl(launchUri);
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              side: const BorderSide(color: Colors.orange),
                              foregroundColor: Colors.orange,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            icon: const Icon(Icons.phone, size: 14),
                            label: const Text('Liên hệ', style: TextStyle(fontSize: 12)),
                          ),
                        )
                    else
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: FittedBox(
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pushAndRemoveUntil(LoginPage.route(), (route) => false),
                            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                            child: const Text('Đăng nhập xem giá', style: TextStyle(color: AppTheme.primaryGreen, fontSize: 11, fontStyle: FontStyle.italic)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().scale(duration: 300.ms, curve: Curves.easeOut);
  }

  Future<void> _handleAddToCart(BuildContext context, ProductModel product, String userRole) async {
    final cartItem = await _showPackagingOptionsDialog(context, product, userRole);
    if (cartItem != null && context.mounted) {
      context.read<CartCubit>().addProduct(
        product: product,
        selectedOption: product.packingOptions.firstWhere((opt) => opt.name == cartItem.caseUnitName),
        quantity: cartItem.quantity,
      );
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text('Đã thêm ${product.name} vào giỏ hàng'),
          backgroundColor: AppTheme.secondaryGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
    }
  }

  Future<CartItemModel?> _showPackagingOptionsDialog(BuildContext context, ProductModel product, String userRole) async {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
     return showDialog<CartItemModel>(
      context: context,
      builder: (dialogContext) {
        if (product.packingOptions.isEmpty) {
          return AlertDialog(
            title: const Text('Thông báo'), 
            content: const Text('Sản phẩm này chưa có quy cách đóng gói.'), 
            actions: [TextButton(onPressed: ()=> Navigator.of(dialogContext).pop(), child: const Text('Đóng'))]
          );
        }

        // --- TỰ ĐỘNG THÊM QUY CÁCH LẺ NẾU CHƯA CÓ ---
        List<PackagingOptionModel> finalOptions = List.from(product.packingOptions);
        bool hasRetail = finalOptions.any((opt) => opt.quantityPerPackage == 1);
        if (!hasRetail && finalOptions.isNotEmpty) {
          final caseOption = finalOptions.first;
          final retailOption = PackagingOptionModel(
            name: 'Lẻ ${caseOption.unit}',
            quantityPerPackage: 1,
            unit: caseOption.unit,
            prices: caseOption.prices,
          );
          finalOptions.insert(0, retailOption);
        }

        // Ưu tiên chọn THÙNG làm mặc định
        PackagingOptionModel selectedOption = finalOptions.firstWhere(
          (opt) => opt.quantityPerPackage > 1,
          orElse: () => finalOptions.first,
        );

        final quantityController = TextEditingController(text: '1');
        return StatefulBuilder(
          builder: (stfContext, stfSetState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('Chọn mua ${product.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView( 
                  child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Quy cách đóng gói:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 12),
                    ...finalOptions.map((option) {
                      final bool isRetail = option.quantityPerPackage == 1;
                      final String typeLabel = isRetail ? 'MUA LẺ' : 'MUA THÙNG';
                      final String subLabel = isRetail 
                          ? 'Đơn vị: ${option.unit}' 
                          : 'Quy cách: ${option.name} (${option.quantityPerPackage} ${option.unit})';
                      final price = option.getPriceForRole(userRole);
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selectedOption == option ? AppTheme.primaryGreen : Colors.grey.shade300,
                            width: selectedOption == option ? 2 : 1,
                          ),
                          color: selectedOption == option ? AppTheme.primaryGreen.withValues(alpha: 0.05) : Colors.transparent,
                        ),
                        child: RadioListTile<PackagingOptionModel>(
                          value: option,
                          groupValue: selectedOption,
                          activeColor: AppTheme.primaryGreen,
                          onChanged: (value) { if (value != null) stfSetState(() => selectedOption = value); },
                          title: Text(typeLabel, style: TextStyle(fontWeight: FontWeight.bold, color: selectedOption == option ? AppTheme.primaryGreen : AppTheme.textDark, fontSize: 14)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(subLabel, style: const TextStyle(fontSize: 12)),
                              Text(currencyFormatter.format(price), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 13)),
                            ],
                          ),
                          isThreeLine: true,
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    const Text('Số lượng đặt:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: quantityController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        prefixIcon: IconButton(
                            onPressed: () {
                              int current = int.tryParse(quantityController.text) ?? 0;
                              if(current > 1) stfSetState(() => quantityController.text = (current - 1).toString());
                            },
                            icon: const Icon(Icons.remove_circle_outline)
                        ),
                        suffixIcon: IconButton(
                            onPressed: () {
                              int current = int.tryParse(quantityController.text) ?? 0;
                              stfSetState(() => quantityController.text = (current + 1).toString());
                            },
                            icon: const Icon(Icons.add_circle_outline)
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(dialogContext).pop(null), child: const Text('Hủy', style: TextStyle(color: AppTheme.textGrey))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: () {
                    final quantity = int.tryParse(quantityController.text) ?? 0;
                    if (quantity > 0) {
                      final price = selectedOption.getPriceForRole(userRole);
                      Navigator.of(dialogContext).pop(CartItemModel(
                        productId: product.id,
                        productName: product.name,
                        imageUrl: product.imageUrl,
                        price: price,
                        itemUnitName: selectedOption.unit,
                        quantity: quantity,
                        quantityPerPackage: selectedOption.quantityPerPackage,
                        caseUnitName: selectedOption.name,
                        categoryId: product.categoryId,
                      ));
                    }
                  },
                  child: const Text('XÁC NHẬN', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _NewsList extends StatelessWidget {
  final List<NewsArticleModel> newsArticles;
  const _NewsList({required this.newsArticles});

  @override
  Widget build(BuildContext context) {
    if (newsArticles.isEmpty) return _buildPlaceholder('Không có tin tức mới');

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList.separated(
        itemCount: newsArticles.length > 3 ? 3 : newsArticles.length, 
        itemBuilder: (context, index) {
          final article = newsArticles[index];
          return _NewsCard(article: article)
              .animate().slideX(begin: 0.2, end: 0, delay: (100 * index).ms, curve: Curves.easeOut); // Tin tức trượt vào
        },
        separatorBuilder: (context, index) => const SizedBox(height: 12),
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  final NewsArticleModel article;
  const _NewsCard({required this.article});

  @override
  Widget build(BuildContext context) {
    final DateFormat dateFormat = DateFormat('dd/MM/yyyy');
    return InkWell(
      onTap: () => Navigator.of(context).push(NewsDetailPage.route(article.id)),
      borderRadius: BorderRadius.circular(20),
      child: Card(
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)),
              child: Image.network(
                article.imageUrl,
                width: 100,
                height: 110,
                fit: BoxFit.cover,
                errorBuilder: (c,e,s) => Container(width: 100, height: 110, color: Colors.grey.shade100, child: const Icon(Icons.article_outlined, color: Colors.grey, size: 30)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      article.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 12, color: AppTheme.textGrey),
                        const SizedBox(width: 4),
                        Text(
                          dateFormat.format(article.publishedDate.toDate()),
                          style: TextStyle(color: AppTheme.textGrey, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.textGrey),
            )
          ],
        ),
      ),
    );
  }
}

// --- UTILITY WIDGETS (LOADING & ERROR) ---

class _ShimmerLoadingView extends StatelessWidget {
  const _ShimmerLoadingView();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppTheme.backgroundLight,
            title: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  _buildShimmerContainer(height: 20, width: 150),
                  const SizedBox(height: 8),
                  _buildShimmerContainer(height: 30, width: 250),
                  const SizedBox(height: 40),
                  _buildShimmerContainer(height: 180, width: double.infinity, radius: 20),
                  const SizedBox(height: 40),
                  _buildShimmerContainer(height: 24, width: 200),
                   const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(4, (index) => Column(
                      children: [
                        _buildShimmerContainer(height: 60, width: 60, radius: 16),
                        const SizedBox(height: 8),
                        _buildShimmerContainer(height: 10, width: 50),
                      ],
                    )),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
  Widget _buildShimmerContainer({required double height, required double width, double radius = 8}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String? errorMessage;
  const _ErrorView({this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 60, color: AppTheme.textGrey),
            const SizedBox(height: 16),
            Text(
              errorMessage ?? 'Không thể tải dữ liệu trang chủ.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.read<HomeCubit>().refreshHomeData(),
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildPlaceholder(String text, {double height = 150}) {
  return SliverToBoxAdapter(
    child: Container(
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      child: Text(text, style: const TextStyle(color: AppTheme.textGrey)),
    ),
  );
}