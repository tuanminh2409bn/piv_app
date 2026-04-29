//lib/features/home/presentation/pages/home_page.dart

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/common/widgets/app_network_image.dart';
import 'package:piv_app/common/widgets/responsive_wrapper.dart';
import 'package:piv_app/core/theme/app_theme.dart';
import 'package:piv_app/core/theme/nature_background_painter.dart';
import 'package:piv_app/core/utils/responsive.dart';
import 'package:piv_app/data/models/cart_item_model.dart';
import 'package:piv_app/data/models/news_article_model.dart';
import 'package:piv_app/data/models/packaging_option_model.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:piv_app/features/auth/presentation/pages/login_page.dart';
import 'package:piv_app/features/cart/presentation/bloc/cart_cubit.dart';
import 'package:piv_app/features/cart/presentation/pages/cart_page.dart';
import 'package:piv_app/features/cart/presentation/widgets/cart_icon_with_badge.dart';
import 'package:piv_app/features/home/data/models/banner_model.dart';
import 'package:piv_app/features/home/data/models/category_model.dart';
import 'package:piv_app/features/home/data/models/product_model.dart';
import 'package:piv_app/features/home/presentation/bloc/home_cubit.dart';
import 'package:piv_app/features/news/presentation/pages/news_detail_page.dart';
import 'package:piv_app/features/notifications/presentation/widgets/notification_icon_with_badge.dart';
import 'package:piv_app/features/products/presentation/pages/category_products_page.dart';
import 'package:piv_app/features/products/presentation/pages/product_detail_page.dart';
import 'package:piv_app/features/products/presentation/pages/search_page.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

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
          Positioned.fill(
            child: ResponsiveWrapper(
              backgroundColor: Colors.transparent, // Không đè nền họa tiết
              showShadow: false, // Bỏ bóng để nội dung hòa vào nền
              maxWidth: Responsive.isDesktop(context) ? double.infinity : 1200, // Cho phép tràn viền trên Web
              child: RefreshIndicator.adaptive(
                onRefresh: () async => context.read<HomeCubit>().refreshHomeData(),
                child: CustomScrollView(
                  slivers: [
                    _wrapConstrained(context, _HomeAppBar()),
                    _wrapConstrained(context, const SliverToBoxAdapter(child: SizedBox(height: 24))),

                    // Header chào mừng - Luôn hiển thị và phản ứng ngay với AuthBloc
                    _wrapConstrained(context, _WelcomeHeader()),

                    // Phần nội dung phụ thuộc vào HomeCubit
                    BlocBuilder<HomeCubit, HomeState>(
                      builder: (context, state) {
                        if (state.status == HomeStatus.loading || state.status == HomeStatus.initial) {
                          return SliverToBoxAdapter(
                            child: _ShimmerContent(isDesktop: Responsive.isDesktop(context)),
                          );
                        }
                        if (state.status == HomeStatus.error) {
                          return SliverToBoxAdapter(
                            child: _ErrorView(errorMessage: state.errorMessage),
                          );
                        }

                        return SliverMainAxisGroup(
                          slivers: [
                            // Khoảng cách trên banner
                            if (Responsive.isDesktop(context))
                              const SliverToBoxAdapter(child: SizedBox(height: 40)),

                            // Banner - KHÔNG bọc constrained để tràn viền
                            _BannerCarousel(banners: state.banners),

                            // Khoảng cách dưới banner
                            if (Responsive.isDesktop(context))
                              const SliverToBoxAdapter(child: SizedBox(height: 40)),

                            // Danh mục
                            _wrapConstrained(context, _SectionHeader(title: 'DANH MỤC NỔI BẬT')),
                            _wrapConstrained(context, _CategoriesRow(categories: state.categories)),

                            _wrapConstrained(context, const SliverToBoxAdapter(child: SizedBox(height: 24))),

                            // Sản phẩm
                            _wrapConstrained(context, _SectionHeader(title: 'SẢN PHẨM NỔI BẬT')),
                            _wrapConstrained(context, _FeaturedProductsGrid(products: state.featuredProducts)),

                            // Tin tức
                            _wrapConstrained(context, _SectionHeader(title: 'TIN TỨC & SỰ KIỆN')),
                            _wrapConstrained(context, _NewsList(newsArticles: state.newsArticles)),
                          ],
                        );
                      },
                    ),

                    _wrapConstrained(context, const SliverToBoxAdapter(child: SizedBox(height: 120))),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Hàm hỗ trợ bọc các thành phần cần giới hạn chiều rộng trên Web
  Widget _wrapConstrained(BuildContext context, Widget sliver) {
    if (!Responsive.isDesktop(context)) return sliver;
    final double screenWidth = MediaQuery.of(context).size.width;
    const double maxWidth = 1200;
    if (screenWidth <= maxWidth) return sliver;
    
    final double padding = (screenWidth - maxWidth) / 2;
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      sliver: sliver,
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
      centerTitle: false,
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
                  Text('Tìm kiếm sản phẩm...',
                      style: TextStyle(color: AppTheme.textGrey, fontSize: 14)),
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
      userIdentifier =
          authState.user.displayName ?? authState.user.email ?? 'Đại lý';
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chào mừng trở lại,',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: AppTheme.textGrey),
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
        ).animate().slideX(
            begin: -0.2,
            end: 0,
            duration: 500.ms,
            curve: Curves.easeOut), // Animate nội dung bên trong
      ),
    );
  }
}

class _BannerCarousel extends StatefulWidget {
  final List<BannerModel> banners;
  const _BannerCarousel({required this.banners});

  @override
  State<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<_BannerCarousel> {
  int _currentIndex = 0;
  final CarouselSliderController _controller = CarouselSliderController();

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) return const SizedBox.shrink();

    final bool isDesktop = Responsive.isDesktop(context);

    return SliverToBoxAdapter(
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: isDesktop ? 20.0 : 20.0),
            child: CarouselSlider.builder(
              carouselController: _controller,
              itemCount: widget.banners.length,
              itemBuilder: (context, index, realIndex) {
                final banner = widget.banners[index];
                return _BannerItem(banner: banner, isDesktop: isDesktop);
              },
              options: CarouselOptions(
                // Tỷ lệ 16/5 giúp ảnh cover không bị mất quá nhiều chi tiết trên Desktop
                aspectRatio: isDesktop ? 16 / 5 : 16 / 9,
                autoPlay: true,
                autoPlayInterval: const Duration(seconds: 5),
                enlargeCenterPage: true, // Luôn phóng to trang giữa như Mobile
                // Hiển thị một phần của 2 slide bên cạnh (giống Mobile)
                viewportFraction: isDesktop ? 0.92 : 0.88,
                onPageChanged: (index, reason) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                autoPlayAnimationDuration: const Duration(milliseconds: 1200),
                autoPlayCurve: Curves.fastOutSlowIn,
              ),
            ),
          ),
          // Chỉ số trang
          Positioned(
            bottom: isDesktop ? 40 : 40,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: widget.banners.asMap().entries.map((entry) {
                  return GestureDetector(
                    onTap: () => _controller.animateToPage(entry.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: _currentIndex == entry.key ? 18 : 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: _currentIndex == entry.key 
                            ? Colors.white 
                            : Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ).animate().fadeIn(duration: 800.ms),
    );
  }
}

class _BannerItem extends StatefulWidget {
  final BannerModel banner;
  final bool isDesktop;
  const _BannerItem({required this.banner, required this.isDesktop});

  @override
  State<_BannerItem> createState() => _BannerItemState();
}

class _BannerItemState extends State<_BannerItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {},
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutQuint,
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24), // Luôn bo góc như Mobile
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isHovered ? 0.25 : 0.15),
                blurRadius: _isHovered ? 25 : 15,
                offset: Offset(0, _isHovered ? 12 : 6),
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // 1. ẢNH CHÍNH: Lấp đầy khung (Cover)
                Positioned.fill(
                  child: AnimatedScale(
                    scale: _isHovered ? 1.05 : 1.0,
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.easeOutCubic,
                    child: AppNetworkImage(
                      imageUrl: widget.banner.imageUrl,
                      fit: BoxFit.cover, // Lấp đầy toàn bộ khung hình
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                ),

                // 2. Lớp phủ Gradient bảo vệ nội dung và tạo chiều sâu
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.7, 1.0],
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.3),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
                  border: Border(
                      left: BorderSide(color: AppTheme.accentGold, width: 4))),
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
        )
            .animate()
            .fadeIn(delay: 300.ms)
            .slideY(begin: 0.2, end: 0), // Animate nội dung
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

    final bool isDesktop = Responsive.isDesktop(context);
    
    // <<< GIẢI PHÁP CỨNG: CHỈ LẤY ĐÚNG 2 DANH MỤC ĐẦU TIÊN >>>
    // Điều này đảm bảo dù Firebase trả về bao nhiêu thì cũng chỉ hiện 2 cái đẹp nhất
    final itemsToShow = categories.take(2).toList();

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverToBoxAdapter(
        child: Row(
          children: itemsToShow.asMap().entries.map((entry) {
            final index = entry.key;
            final category = entry.value;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: isDesktop ? 16.0 : 6.0),
                child: InkWell(
                  onTap: () => Navigator.of(context)
                      .push(CategoryProductsPage.route(category)),
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    height: isDesktop ? 220 : 140, // To hơn trên Desktop
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      border: Border.all(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                          width: 1),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Container(
                            margin: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                                  AppTheme.primaryGreen.withValues(alpha: 0.05),
                              shape: BoxShape.circle,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Hero(
                                tag: 'cat_${category.id}',
                                child: AppNetworkImage(
                                  imageUrl: category.imageUrl,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                          child: Text(
                            category.name.toUpperCase(),
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                                fontSize: isDesktop ? 20 : 14,
                                letterSpacing: 1.1),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: (200 * index).ms)
                  .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack),
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

    final bool isDesktop = Responsive.isDesktop(context);
    // Giới hạn: 8 sản phẩm trên Web, 6 sản phẩm trên Mobile
    final int displayLimit = isDesktop ? 8 : 6;
    final displayItems = products.take(displayLimit).toList();

    final int crossAxisCount = isDesktop ? 4 : 2;
    final double childAspectRatio = Responsive.value(
      context, 
      mobile: (MediaQuery.of(context).size.width / 2) / 330,
      desktop: 0.65, 
    );

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid.builder(
        itemCount: displayItems.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: childAspectRatio,
        ),
        itemBuilder: (context, index) {
          final product = displayItems[index];
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
    // canViewPrice mặc định là false nếu authState là AuthUnauthenticated
    
    final price = product.getPriceForRole(userRole);

    return GestureDetector(
      onTap: () =>
          Navigator.of(context).push(ProductDetailPage.route(product.id)),
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
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(16)),
                      child: (product.imageUrl.isNotEmpty)
                          ? AppNetworkImage(
                              imageUrl: product.imageUrl,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: Colors.grey.shade100,
                              child: const Icon(Icons.image,
                                  size: 40, color: Colors.grey)),
                    ),
                  ),
                  if (product.isPrivate)
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: const BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(16),
                                bottomRight: Radius.circular(12))),
                        child: const Text('ĐỘC QUYỀN',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold)),
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
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          height: 1.2),
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
                                style: const TextStyle(
                                    color: AppTheme.primaryGreen,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Material(
                              color: AppTheme.secondaryGreen,
                              borderRadius: BorderRadius.circular(8),
                              child: InkWell(
                                onTap: () async => _handleAddToCart(
                                    context, product, userRole),
                                borderRadius: BorderRadius.circular(8),
                                child: const Padding(
                                  padding: EdgeInsets.all(6.0),
                                  child: Icon(Icons.add_shopping_cart,
                                      color: Colors.white, size: 18),
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
                              final Uri launchUri =
                                  Uri(scheme: 'tel', path: '0345012346');
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
                            label: const Text('Liên hệ',
                                style: TextStyle(fontSize: 12)),
                          ),
                        )
                    else
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: FittedBox(
                          child: TextButton(
                            onPressed: () => Navigator.of(context)
                                .pushAndRemoveUntil(
                                    LoginPage.route(), (route) => false),
                            style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap),
                            child: const Text('Đăng nhập xem giá',
                                style: TextStyle(
                                    color: AppTheme.primaryGreen,
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic)),
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

  Future<void> _handleAddToCart(
      BuildContext context, ProductModel product, String userRole) async {
    final cartItem =
        await _showPackagingOptionsDialog(context, product, userRole);
    if (cartItem != null && context.mounted) {
      context.read<CartCubit>().addProduct(
            product: product,
            selectedOption: product.packingOptions
                .firstWhere((opt) => opt.name == cartItem.caseUnitName),
            quantity: cartItem.quantity,
          );
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text('Đã thêm ${product.name} vào giỏ hàng'),
          backgroundColor: AppTheme.secondaryGreen,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
    }
  }

  Future<CartItemModel?> _showPackagingOptionsDialog(
      BuildContext context, ProductModel product, String userRole) async {
    final currencyFormatter =
        NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return showDialog<CartItemModel>(
      context: context,
      builder: (dialogContext) {
        if (product.packingOptions.isEmpty) {
          return AlertDialog(
              title: const Text('Thông báo'),
              content: const Text('Sản phẩm này chưa có quy cách đóng gói.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Đóng'))
              ]);
        }

        // --- TỰ ĐỘNG THÊM QUY CÁCH LẺ NẾU CHƯA CÓ ---
        List<PackagingOptionModel> finalOptions =
            List.from(product.packingOptions);
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Text('Chọn mua ${product.name}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Quy cách đóng gói:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 12),
                      ...finalOptions.map((option) {
                        final bool isRetail = option.quantityPerPackage == 1;
                        final String typeLabel =
                            isRetail ? 'MUA LẺ' : 'MUA THÙNG';
                        final String subLabel = isRetail
                            ? 'Đơn vị: ${option.unit}'
                            : 'Quy cách: ${option.name} (${option.quantityPerPackage} ${option.unit})';
                        final price = option.getPriceForRole(userRole);
                  
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selectedOption == option
                                  ? AppTheme.primaryGreen
                                  : Colors.grey.shade300,
                              width: selectedOption == option ? 2 : 1,
                            ),
                            color: selectedOption == option
                                ? AppTheme.primaryGreen.withValues(alpha: 0.05)
                                : Colors.transparent,
                          ),
                          child: RadioListTile<PackagingOptionModel>(
                            value: option,
                            groupValue: selectedOption,
                            activeColor: AppTheme.primaryGreen,
                            onChanged: (value) {
                              if (value != null)
                                stfSetState(() => selectedOption = value);
                            },
                            title: Text(typeLabel,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: selectedOption == option
                                        ? AppTheme.primaryGreen
                                        : AppTheme.textDark,
                                    fontSize: 14)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(subLabel,
                                    style: const TextStyle(fontSize: 12)),
                                Text(currencyFormatter.format(price),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange,
                                        fontSize: 13)),
                              ],
                            ),
                            isThreeLine: true,
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                      const Text('Số lượng đặt:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 12),
                      TextField(
                        controller: quantityController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                          prefixIcon: IconButton(
                              onPressed: () {
                                int current =
                                    int.tryParse(quantityController.text) ?? 0;
                                if (current > 1)
                                  stfSetState(() => quantityController.text =
                                      (current - 1).toString());
                              },
                              icon: const Icon(Icons.remove_circle_outline)),
                          suffixIcon: IconButton(
                              onPressed: () {
                                int current =
                                    int.tryParse(quantityController.text) ?? 0;
                                stfSetState(() => quantityController.text =
                                    (current + 1).toString());
                              },
                              icon: const Icon(Icons.add_circle_outline)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(null),
                    child: const Text('Hủy',
                        style: TextStyle(color: AppTheme.textGrey))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
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
                  child: const Text('XÁC NHẬN',
                      style: TextStyle(fontWeight: FontWeight.bold)),
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

    final int limit = Responsive.value(context, mobile: 3, desktop: 5);
    final items =
        newsArticles.length > limit ? newsArticles.sublist(0, limit) : newsArticles;

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: Responsive.isMobile(context)
          ? SliverList.separated(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final article = items[index];
                return _NewsCard(article: article).animate().slideX(
                    begin: 0.2,
                    end: 0,
                    delay: (100 * index).ms,
                    curve: Curves.easeOut);
              },
              separatorBuilder: (context, index) => const SizedBox(height: 12),
            )
          : SliverGrid.builder(
              itemCount: items.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 3,
              ),
              itemBuilder: (context, index) {
                final article = items[index];
                return _NewsCard(article: article)
                    .animate()
                    .fadeIn(delay: (100 * index).ms, curve: Curves.easeOut);
              },
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
        margin: EdgeInsets.zero,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20)),
              child: AppNetworkImage(
                imageUrl: article.imageUrl,
                width: 100,
                height: 110,
                fit: BoxFit.cover,
                errorWidget: Container(
                    width: 100,
                    height: 110,
                    color: Colors.grey.shade100,
                    child: const Icon(Icons.article_outlined,
                        color: Colors.grey, size: 30)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                    left: 12.0,
                    right: 12.0,
                    top: Responsive.value(context, mobile: 12.0, desktop: 36.0),
                    bottom: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      article.title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: Responsive.value(
                              context, mobile: 14.0, desktop: 13.0),
                          height: Responsive.value(
                              context, mobile: 1.4, desktop: 1.2)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: Responsive.value(
                                context, mobile: 12.0, desktop: 14.0),
                            color: AppTheme.textGrey),
                        const SizedBox(width: 4),
                        Text(
                          dateFormat.format(article.publishedDate.toDate()),
                          style: TextStyle(
                              color: AppTheme.textGrey,
                              fontSize: Responsive.value(
                                  context, mobile: 12.0, desktop: 14.0)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Icon(Icons.arrow_forward_ios,
                  size: 16, color: AppTheme.textGrey),
            )
          ],
        ),
      ),
    );
  }
}

// --- UTILITY WIDGETS (LOADING & ERROR) ---

class _ShimmerContent extends StatelessWidget {
  final bool isDesktop;
  const _ShimmerContent({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            _buildShimmerContainer(
                height: isDesktop ? 300 : 180, width: double.infinity, radius: 24),
            const SizedBox(height: 40),
            _buildShimmerContainer(height: 24, width: 200),
            const SizedBox(height: 24),
            Row(
              children: List.generate(
                  2,
                  (index) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: _buildShimmerContainer(
                              height: isDesktop ? 220 : 140, width: double.infinity, radius: 24),
                        ),
                      )),
            ),
            const SizedBox(height: 40),
            _buildShimmerContainer(height: 24, width: 200),
            const SizedBox(height: 24),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: isDesktop ? 4 : 2,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isDesktop ? 4 : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.7,
              ),
              itemBuilder: (_, __) => _buildShimmerContainer(height: 200, width: double.infinity, radius: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerContainer(
      {required double height, required double width, double radius = 8}) {
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
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 60, color: AppTheme.textGrey),
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
