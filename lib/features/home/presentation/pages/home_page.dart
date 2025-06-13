import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:piv_app/features/home/presentation/bloc/home_cubit.dart';
import 'package:piv_app/core/di/injection_container.dart';
// Import các Model thật
import 'package:piv_app/features/home/data/models/category_model.dart';
import 'package:piv_app/features/home/data/models/banner_model.dart';
import 'package:piv_app/features/home/data/models/product_model.dart';
import 'package:piv_app/data/models/news_article_model.dart';
// Import các trang và widget liên quan
import 'package:piv_app/features/news/presentation/pages/news_detail_page.dart';
import 'package:piv_app/features/products/presentation/pages/product_detail_page.dart';
import 'package:piv_app/features/cart/presentation/widgets/cart_icon_with_badge.dart';
import 'package:piv_app/features/cart/presentation/pages/cart_page.dart';
import 'package:piv_app/features/profile/presentation/pages/profile_page.dart';
import 'package:piv_app/features/products/presentation/pages/category_products_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static PageRoute<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const HomePage());
  }

  @override
  Widget build(BuildContext context) {
    // Cung cấp HomeCubit và bắt đầu tải dữ liệu ngay khi trang được tạo
    return BlocProvider(
      create: (_) => sl<HomeCubit>()..fetchHomeScreenData(),
      child: const HomeView(),
    );
  }
}

// Tách phần giao diện chính ra một widget riêng để dễ quản lý
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    // Lấy thông tin người dùng từ AuthBloc để hiển thị lời chào
    final authState = context.watch<AuthBloc>().state;
    String userIdentifier = 'Khách';
    if (authState is AuthAuthenticated) {
      userIdentifier = authState.user.displayName ?? authState.user.email ?? authState.user.id;
    }

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade800, Colors.green.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text('Phân Bón PIV', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        elevation: 4.0,
        actionsIconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            tooltip: 'Hồ sơ cá nhân',
            onPressed: () {
              Navigator.of(context).push(ProfilePage.route());
            },
          ),
          CartIconWithBadge(
            iconColor: Colors.white,
            onPressed: () {
              Navigator.of(context).push(CartPage.route());
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: () {
              context.read<AuthBloc>().add(AuthLogoutRequested());
            },
          ),
        ],
      ),
      body: BlocBuilder<HomeCubit, HomeState>(
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
                    Text(
                      state.errorMessage ?? 'Không thể tải dữ liệu trang chủ.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<HomeCubit>().fetchHomeScreenData();
                      },
                      child: const Text('Thử lại'),
                    )
                  ],
                ),
              ),
            );
          }
          if (state.status == HomeStatus.success) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<HomeCubit>().fetchHomeScreenData();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
                      child: Text(
                        'Chào mừng trở lại, $userIdentifier!',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ),
                    if (state.banners.isNotEmpty)
                      _buildBannerCarousel(context, state.banners)
                    else
                      _buildPlaceholderContainer(context, 'Không có banner', height: MediaQuery.of(context).size.width * (9 / 16)),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle(context, 'Danh Mục Nổi Bật'),
                          if (state.categories.isNotEmpty)
                            _buildCategoriesRow(context, state.categories)
                          else
                            _buildPlaceholderContainer(context, 'Không có danh mục', height: 120),
                          const SizedBox(height: 24),
                          _buildSectionTitle(context, 'Sản Phẩm Nổi Bật'),
                          if (state.featuredProducts.isNotEmpty)
                            _buildFeaturedProductsGrid(context, state.featuredProducts)
                          else
                            _buildPlaceholderContainer(context, 'Không có sản phẩm', height: 200),
                          const SizedBox(height: 24),
                          _buildSectionTitle(context, 'Tin Tức & Sự Kiện'),
                          if (state.newsArticles.isNotEmpty)
                            _buildNewsList(context, state.newsArticles)
                          else
                            _buildPlaceholderContainer(context, 'Không có tin tức', height: 150),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          }
          return const Center(child: Text('Trạng thái không xác định.'));
        },
      ),
    );
  }

  // --- WIDGET HELPER FUNCTIONS ---

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
            onTap: () {
              final targetUrl = banner.targetUrl;
              if (targetUrl != null && targetUrl.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Điều hướng tới: $targetUrl')));
              }
            },
            child: Container(
              width: MediaQuery.of(context).size.width, margin: const EdgeInsets.symmetric(horizontal: 5.0),
              decoration: BoxDecoration(
                color: Colors.grey.shade300, borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 4))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(banner.imageUrl, fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image_outlined, size: 50, color: Colors.grey)),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(child: CircularProgressIndicator(
                      strokeWidth: 2.0, valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade700),
                      value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null,
                    ));
                  },
                ),
              ),
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
    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal, itemCount: categories.length, clipBehavior: Clip.none,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final category = categories[index];
          return SizedBox(
            width: 100,
            child: Card(
              elevation: 3, clipBehavior: Clip.antiAlias, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: InkWell(
                onTap: () {
                  Navigator.of(context).push(CategoryProductsPage.route(category));
                },
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    ClipRRect(borderRadius: BorderRadius.circular(8),
                      child: Image.network(category.imageUrl, height: 50, width: 50, fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.category_outlined, size: 40, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(category.name, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ]),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeaturedProductsGrid(BuildContext context, List<ProductModel> products) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return GridView.builder(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: products.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.7),
      itemBuilder: (context, index) {
        final product = products[index];
        return Card(elevation: 3, clipBehavior: Clip.antiAlias, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(ProductDetailPage.route(product.id));
            },
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Expanded(flex: 5,
                child: (product.imageUrl.isNotEmpty)
                    ? Image.network(product.imageUrl, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey.shade200, alignment: Alignment.center, child: const Icon(Icons.image_search_outlined, size: 50, color: Colors.grey)),)
                    : Container(color: Colors.grey.shade200, alignment: Alignment.center, child: const Icon(Icons.image_search_outlined, size: 50, color: Colors.grey)),
              ),
              Padding(padding: const EdgeInsets.all(10.0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text(product.name, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(
                    'Từ ${currencyFormatter.format(product.startingPrice)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                  ),
                ]),
              ),
            ]),
          ),
        );
      },
    );
  }

  Widget _buildNewsList(BuildContext context, List<NewsArticleModel> newsArticles) {
    final DateFormat dateFormat = DateFormat('dd/MM/yyyy');
    return ListView.separated(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: newsArticles.length,
      separatorBuilder: (context, index) => const SizedBox(height: 0),
      itemBuilder: (context, index) {
        final article = newsArticles[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12), elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: article.imageUrl.isNotEmpty
                  ? Image.network(
                article.imageUrl, width: 70, height: 70, fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(width: 70, height: 70, color: Colors.grey.shade200, child: const Icon(Icons.article_outlined, color: Colors.grey, size: 30,)),
              )
                  : Container(width: 70, height: 70, color: Colors.grey.shade200, child: const Icon(Icons.article_outlined, color: Colors.grey, size: 30,)),
            ),
            title: Text(article.title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                '${dateFormat.format(article.publishedDate.toDate())}\n${article.summary}', maxLines: 3,
                overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700, height: 1.4),
              ),
            ),
            trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade600),
            isThreeLine: true,
            onTap: () {
              Navigator.of(context).push(NewsDetailPage.route(article.id));
            },
          ),
        );
      },
    );
  }

  Widget _buildPlaceholderContainer(BuildContext context, String text, {double height = 100}) {
    return Container(
      height: height, width: double.infinity,
      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
      alignment: Alignment.center,
      child: Text(text, style: TextStyle(color: Colors.grey.shade600)),
    );
  }
}
