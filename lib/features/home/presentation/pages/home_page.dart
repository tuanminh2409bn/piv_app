//lib/features/home/presentation/pages/home_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:intl/intl.dart';
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
                  // <<< SỬA LẠI: GỌI HÀM refreshHomeData >>>
                  ElevatedButton(onPressed: () => context.read<HomeCubit>().refreshHomeData(), child: const Text('Thử lại')),
                ],
              ),
            ),
          );
        }

        return Scaffold(
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
                        // ========== TRUYỀN THÊM BIẾN canViewPrice ==========
                          _buildFeaturedProductsGrid(context, state.featuredProducts, userRole, canViewPrice)
                        else
                          _buildPlaceholderContainer(context, 'Không có sản phẩm nổi bật.', height: 200),
                        const SizedBox(height: 24),
                        _buildSectionTitle(context, 'Tin Tức & Sự Kiện'),
                        if (state.newsArticles.isNotEmpty) _buildNewsList(context, state.newsArticles) else _buildPlaceholderContainer(context, 'Không có tin tức', height: 150),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- CÁC HÀM BUILD HELPER GIỮ NGUYÊN ---

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

  Widget _buildFeaturedProductsGrid(BuildContext context, List<ProductModel> products, String userRole, bool canViewPrice) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: products.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.7),
      itemBuilder: (context, index) {
        final product = products[index];
        final price = product.getPriceForRole(userRole);
        final unit = product.displayUnit;
        return Card(
          elevation: 3,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: () => Navigator.of(context).push(ProductDetailPage.route(product.id)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 5, child: (product.imageUrl.isNotEmpty) ? Image.network(product.imageUrl, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey.shade200, alignment: Alignment.center, child: const Icon(Icons.image_search_outlined, size: 50, color: Colors.grey))) : Container(color: Colors.grey.shade200, alignment: Alignment.center, child: const Icon(Icons.image_search_outlined, size: 50, color: Colors.grey))),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(product.name, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      // --- HIỂN THỊ GIÁ CÓ ĐIỀU KIỆN ---
                      if (canViewPrice)
                        Text('${currencyFormatter.format(price)} / $unit', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold))
                      else
                        TextButton(
                          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 20), alignment: Alignment.centerLeft),
                          onPressed: () => Navigator.of(context).pushAndRemoveUntil(LoginPage.route(), (route) => false),
                          child: const Text('Xem giá'),
                        ),
                      // ------------------------------------
                    ],
                  ),
                ),
              ],
            ),
          ),
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