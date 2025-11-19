//lib/features/home/presentation/pages/home_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/core/di/injection_container.dart'; // Cần để dùng sl nếu cần
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

// --- THÊM CÁC IMPORT MỚI ĐỂ HỖ TRỢ MUA HÀNG ---
import 'package:piv_app/features/cart/presentation/bloc/cart_cubit.dart';
import 'package:piv_app/features/checkout/presentation/pages/checkout_page.dart';
import 'package:piv_app/data/models/cart_item_model.dart';
import 'package:piv_app/data/models/packaging_option_model.dart';
// -------------------------------------------------

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
    final authState = context.watch<AuthBloc>().state;
    String userIdentifier = 'Khách';
    String userRole = 'guest';
    bool canViewPrice = false;

    if (authState is AuthAuthenticated) {
      final user = authState.user;
      userIdentifier = user.displayName ?? user.email ?? 'Đại lý';
      userRole = user.role;
      if (!user.isGuest && user.status == 'active') {
        canViewPrice = true;
      }
    }

    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        if (state.status == HomeStatus.loading || state.status == HomeStatus.initial) {
          return const Center(child: CircularProgressIndicator(color: Colors.green));
        }
        if (state.status == HomeStatus.error) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.errorMessage ?? 'Không thể tải dữ liệu trang chủ.', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: () => context.read<HomeCubit>().refreshHomeData(), child: const Text('Thử lại')),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          // Thay đổi màu nền nhẹ nhàng hơn để làm nổi bật Card
          backgroundColor: const Color(0xFFF9F9F9),
          body: RefreshIndicator(
            onRefresh: () async => context.read<HomeCubit>().refreshHomeData(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchBar(context),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0),
                    child: Text('Chào mừng trở lại, $userIdentifier!', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600, color: Colors.green.shade800)),
                  ),
                  if (state.banners.isNotEmpty) _buildBannerCarousel(context, state.banners) else _buildPlaceholderContainer(context, 'Không có banner', height: MediaQuery.of(context).size.width * (9 / 16)),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle(context, 'Danh Mục Nổi Bật'),
                        if (state.categories.isNotEmpty) _buildCategoriesRow(context, state.categories) else _buildPlaceholderContainer(context, 'Không có danh mục', height: 120),
                        const SizedBox(height: 24),
                        _buildSectionTitle(context, 'Sản Phẩm Nổi Bật'),
                        if (state.featuredProducts.isNotEmpty)
                          _buildFeaturedProductsGrid(context, state.featuredProducts, userRole, canViewPrice)
                        else
                          _buildPlaceholderContainer(context, 'Không có sản phẩm nổi bật.', height: 200),
                        const SizedBox(height: 24),
                        _buildSectionTitle(context, 'Tin Tức & Sự Kiện'),
                        if (state.newsArticles.isNotEmpty) _buildNewsList(context, state.newsArticles) else _buildPlaceholderContainer(context, 'Không có tin tức', height: 150),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10), // Thêm padding bottom để không bị che bởi navigation bar nếu có
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- CÁC HÀM BUILD HELPER ---

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(SearchPage.route());
        },
        child: AbsorbPointer(
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Tìm kiếm sản phẩm...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide(color: Colors.grey.shade300)),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBannerCarousel(BuildContext context, List<BannerModel> banners) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: CarouselSlider(
        options: CarouselOptions(
          aspectRatio: 16/9, autoPlay: true, autoPlayInterval: const Duration(seconds: 5),
          enlargeCenterPage: true, viewportFraction: 0.9, enlargeStrategy: CenterPageEnlargeStrategy.zoom,
        ),
        items: banners.map((banner) => Builder(builder: (BuildContext context) {
          return GestureDetector(
            onTap: () { /* Xử lý sự kiện */ },
            child: Container(
              width: MediaQuery.of(context).size.width, margin: const EdgeInsets.symmetric(horizontal: 5.0),
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 4))]),
              child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(banner.imageUrl, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image_outlined)))),
            ),
          );
        })).toList(),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.green.shade700)),
    );
  }

  Widget _buildCategoriesRow(BuildContext context, List<CategoryModel> categories) {
    final itemsToShow = categories.take(3).toList();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: itemsToShow.map((category) {
        return Expanded(
          child: InkWell(
            onTap: () => Navigator.of(context).push(CategoryProductsPage.route(category)),
            borderRadius: BorderRadius.circular(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  width: 70, height: 70,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
                  child: Image.network(category.imageUrl, errorBuilder: (c, e, s) => const Icon(Icons.category_outlined, color: Colors.green)),
                ),
                const SizedBox(height: 8),
                Text(category.name, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // --- CẬP NHẬT: TỶ LỆ THẺ CAO HƠN (0.58) ĐỂ TRÁNH TRÀN ---
  Widget _buildFeaturedProductsGrid(BuildContext context, List<ProductModel> products, String userRole, bool canViewPrice) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Tinh chỉnh tỷ lệ:
    // Màn hình nhỏ (< 360): 0.55 (thẻ cao hơn)
    // Màn hình thường: 0.58 - 0.6
    double aspectRatio = 0.58;
    if (screenWidth < 380) {
      aspectRatio = 0.55;
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: products.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: aspectRatio, // <-- Tỷ lệ an toàn mới
      ),
      itemBuilder: (context, index) {
        final product = products[index];
        return _FeaturedProductCard(
          product: product,
          userRole: userRole,
          canViewPrice: canViewPrice,
        );
      },
    );
  }

  Widget _buildNewsList(BuildContext context, List<NewsArticleModel> newsArticles) {
    final DateFormat dateFormat = DateFormat('dd/MM/yyyy');
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: newsArticles.length,
      separatorBuilder: (context, index) => const SizedBox(height: 0),
      itemBuilder: (context, index) {
        final article = newsArticles[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
            leading: ClipRRect(borderRadius: BorderRadius.circular(8), child: article.imageUrl.isNotEmpty ? Image.network(article.imageUrl, width: 70, height: 70, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(width: 70, height: 70, color: Colors.grey.shade200, child: const Icon(Icons.article_outlined, color: Colors.grey, size: 30))) : Container(width: 70, height: 70, color: Colors.grey.shade200, child: const Icon(Icons.article_outlined, color: Colors.grey, size: 30))),
            title: Text(article.title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: Padding(padding: const EdgeInsets.only(top: 4.0), child: Text('${dateFormat.format(article.publishedDate.toDate())}\n${article.summary}', maxLines: 3, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700, height: 1.4))),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            isThreeLine: true,
            onTap: () => Navigator.of(context).push(NewsDetailPage.route(article.id)),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholderContainer(BuildContext context, String text, {double height = 100}) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
      alignment: Alignment.center,
      child: Text(text, style: TextStyle(color: Colors.grey.shade600)),
    );
  }
}

// --- WIDGET MỚI: CARD SẢN PHẨM ĐẸP MẮT (Tách riêng để code gọn gàng) ---
class _FeaturedProductCard extends StatelessWidget {
  final ProductModel product;
  final String userRole;
  final bool canViewPrice;
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  _FeaturedProductCard({
    required this.product,
    required this.userRole,
    required this.canViewPrice,
  });

  // ... (Giữ nguyên hàm _showPackagingOptionsDialog cũ của bạn ở đây) ...
  Future<CartItemModel?> _showPackagingOptionsDialog(BuildContext context) async {
    return showDialog<CartItemModel>(
      context: context,
      builder: (dialogContext) {
        if (product.packingOptions.isEmpty) {
          return AlertDialog(
            title: const Text('Thông báo'),
            content: const Text('Sản phẩm này chưa có quy cách đóng gói.'),
            actions: [TextButton(onPressed: ()=> Navigator.of(dialogContext).pop(), child: const Text('Đóng'))],
          );
        }

        PackagingOptionModel selectedOption = product.packingOptions.first;
        final quantityController = TextEditingController(text: '1');

        return StatefulBuilder(
          builder: (stfContext, stfSetState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Chọn quy cách cho ${product.name}', style: const TextStyle(fontSize: 18)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<PackagingOptionModel>(
                      value: selectedOption,
                      isExpanded: true,
                      items: product.packingOptions.map((option) {
                        final price = option.getPriceForRole(userRole);
                        return DropdownMenuItem(
                          value: option,
                          child: Text('${option.name} - ${currencyFormatter.format(price)}', overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) stfSetState(() => selectedOption = value);
                      },
                      decoration: InputDecoration(
                        labelText: 'Quy cách',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: quantityController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: 'Số lượng',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: IconButton(
                            onPressed: () {
                              int current = int.tryParse(quantityController.text) ?? 0;
                              if(current > 1) quantityController.text = (current - 1).toString();
                            },
                            icon: const Icon(Icons.remove)
                        ),
                        suffixIcon: IconButton(
                            onPressed: () {
                              int current = int.tryParse(quantityController.text) ?? 0;
                              quantityController.text = (current + 1).toString();
                            },
                            icon: const Icon(Icons.add)
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(dialogContext).pop(null), child: const Text('Hủy')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    final quantity = int.tryParse(quantityController.text) ?? 0;
                    if (quantity > 0) {
                      final price = selectedOption.getPriceForRole(userRole);
                      final cartItem = CartItemModel(
                        productId: product.id,
                        productName: product.name,
                        imageUrl: product.imageUrl,
                        price: price,
                        itemUnitName: selectedOption.unit,
                        quantity: quantity,
                        quantityPerPackage: selectedOption.quantityPerPackage,
                        caseUnitName: selectedOption.name,
                        categoryId: product.categoryId,
                      );
                      Navigator.of(dialogContext).pop(cartItem);
                    }
                  },
                  child: const Text('Xác nhận'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  // ... (Hết hàm dialog) ...

  @override
  Widget build(BuildContext context) {
    final price = product.getPriceForRole(userRole);

    return GestureDetector(
      onTap: () => Navigator.of(context).push(ProductDetailPage.route(product.id)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. ẢNH (TỶ LỆ 1:1 GIỮ NGUYÊN) ---
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: (product.imageUrl.isNotEmpty)
                        ? Image.network(product.imageUrl, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey.shade100, child: Icon(Icons.image, size: 40, color: Colors.grey.shade300)))
                        : Container(color: Colors.grey.shade100, child: Icon(Icons.image, size: 40, color: Colors.grey.shade300)),
                  ),
                ),
                if (product.isPrivate)
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('SẢN PHẨM ĐỘC QUYỀN', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            // --- 2. NỘI DUNG (SỬ DỤNG EXPANDED + LAYOUTBUILDER ĐỂ CHỐNG TRÀN) ---
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                // LayoutBuilder giúp chúng ta biết chiều cao còn lại
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const ClampingScrollPhysics(), // Cho phép cuộn nhẹ nếu quá chật
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: IntrinsicHeight(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween, // Thay thế Spacer()
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, height: 1.2),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  if (canViewPrice)
                                    Text(
                                      currencyFormatter.format(price),
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    )
                                  else
                                    Text(
                                      'Liên hệ để xem giá',
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontStyle: FontStyle.italic),
                                    ),
                                ],
                              ),

                              // Khoảng cách an toàn
                              const SizedBox(height: 8),

                              // Nút bấm
                              if (canViewPrice)
                                Row(
                                  children: [
                                    Expanded(
                                      child: SizedBox(
                                        height: 32,
                                        child: OutlinedButton(
                                          onPressed: () async {
                                            final cartItem = await _showPackagingOptionsDialog(context);
                                            if (cartItem != null && context.mounted) {
                                              Navigator.of(context).push(CheckoutPage.route(buyNowItems: [cartItem]));
                                            }
                                          },
                                          style: OutlinedButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                            side: BorderSide(color: Theme.of(context).colorScheme.primary),
                                          ),
                                          child: const Text('Mua', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 32,
                                      height: 32,
                                      child: IconButton.filled(
                                        padding: EdgeInsets.zero,
                                        icon: const Icon(Icons.add_shopping_cart, size: 16),
                                        onPressed: () async {
                                          final cartItem = await _showPackagingOptionsDialog(context);
                                          if (cartItem != null && context.mounted) {
                                            context.read<CartCubit>().addProduct(
                                              product: product,
                                              selectedOption: product.packingOptions.firstWhere((opt) => opt.name == cartItem.caseUnitName),
                                              quantity: cartItem.quantity,
                                            );
                                            ScaffoldMessenger.of(context)
                                              ..hideCurrentSnackBar()
                                              ..showSnackBar(SnackBar(content: Text('Đã thêm ${product.name} vào giỏ hàng')));
                                          }
                                        },
                                        style: IconButton.styleFrom(
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                          foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              else
                                SizedBox(
                                  width: double.infinity,
                                  height: 32,
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.of(context).pushAndRemoveUntil(LoginPage.route(), (route) => false),
                                    style: OutlinedButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                    ),
                                    child: const Text('Đăng nhập để xem giá', style: TextStyle(fontSize: 12)),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}