// lib/features/wishlist/presentation/pages/wishlist_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/core/theme/app_theme.dart';
import 'package:piv_app/core/theme/nature_background_painter.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:piv_app/features/home/data/models/product_model.dart';
import 'package:piv_app/features/home/domain/repositories/home_repository.dart';
import 'package:piv_app/features/products/presentation/pages/product_detail_page.dart';
import 'package:piv_app/features/wishlist/presentation/bloc/wishlist_cubit.dart';
import 'package:piv_app/features/wishlist/presentation/widgets/wishlist_button.dart';
import 'package:intl/intl.dart';
import 'package:equatable/equatable.dart';

// --- STATE ---
enum WishlistPageStatus { initial, loading, success, error }

class WishlistPageState extends Equatable {
  final WishlistPageStatus status;
  final List<ProductModel> wishlistedProducts;
  final String? errorMessage;

  const WishlistPageState({
    this.status = WishlistPageStatus.initial,
    this.wishlistedProducts = const [],
    this.errorMessage,
  });

  @override
  List<Object?> get props => [status, wishlistedProducts, errorMessage];

  WishlistPageState copyWith({
    WishlistPageStatus? status,
    List<ProductModel>? wishlistedProducts,
    String? errorMessage,
  }) {
    return WishlistPageState(
      status: status ?? this.status,
      wishlistedProducts: wishlistedProducts ?? this.wishlistedProducts,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// --- CUBIT ---
class WishlistPageCubit extends Cubit<WishlistPageState> {
  final HomeRepository _homeRepository;
  final WishlistCubit _wishlistCubit;
  StreamSubscription? _wishlistSubscription;

  WishlistPageCubit({required HomeRepository homeRepository, required WishlistCubit wishlistCubit})
      : _homeRepository = homeRepository,
        _wishlistCubit = wishlistCubit,
        super(const WishlistPageState()) {
    _wishlistSubscription = _wishlistCubit.stream.listen((wishlistState) {
      loadWishlistProducts(wishlistState.productIds);
    });
    loadWishlistProducts(_wishlistCubit.state.productIds);
  }

  Future<void> loadWishlistProducts(Set<String> productIds) async {
    if (productIds.isEmpty) {
      emit(state.copyWith(status: WishlistPageStatus.success, wishlistedProducts: []));
      return;
    }
    emit(state.copyWith(status: WishlistPageStatus.loading));
    final result = await _homeRepository.getProductsByIds(productIds.toList());
    result.fold(
          (failure) => emit(state.copyWith(status: WishlistPageStatus.error, errorMessage: failure.message)),
          (products) => emit(state.copyWith(status: WishlistPageStatus.success, wishlistedProducts: products)),
    );
  }

  @override
  Future<void> close() {
    _wishlistSubscription?.cancel();
    return super.close();
  }
}

// --- UI PAGE ---
class WishlistPage extends StatelessWidget {
  const WishlistPage({super.key});

  static PageRoute<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const WishlistPage());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => WishlistPageCubit(homeRepository: sl(), wishlistCubit: context.read<WishlistCubit>()),
      child: const WishlistView(),
    );
  }
}

// --- UI VIEW ---
class WishlistView extends StatelessWidget {
  const WishlistView({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    String userRole = 'agent_2';
    bool canViewPrice = false;

    if(authState is AuthAuthenticated) {
      userRole = authState.user.role;
      if (!authState.user.isGuest && authState.user.status == 'active') {
        canViewPrice = true;
      }
    }

    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final double screenWidth = MediaQuery.of(context).size.width;
    final double childAspectRatio = (screenWidth / 2) / 280;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: CustomPaint(
              painter: NatureBackgroundPainter(
                color1: AppTheme.primaryGreen.withValues(alpha: 0.05),
                color2: AppTheme.secondaryGreen.withValues(alpha: 0.03),
                accent: AppTheme.accentGold.withValues(alpha: 0.1),
              ),
            ),
          ),

          BlocBuilder<WishlistPageCubit, WishlistPageState>(
            builder: (context, state) {
              if (state.status == WishlistPageStatus.loading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.status == WishlistPageStatus.error) {
                return Center(child: Text(state.errorMessage ?? 'Lỗi tải dữ liệu.'));
              }
              
              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 120.0,
                    pinned: true,
                    backgroundColor: AppTheme.primaryGreen,
                    leading: const BackButton(color: Colors.white),
                    flexibleSpace: FlexibleSpaceBar(
                      centerTitle: true,
                      title: const Text('Danh sách yêu thích', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      background: Stack(
                        children: [
                          Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppTheme.primaryGreen, AppTheme.secondaryGreen],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: CustomPaint(
                              painter: NatureBackgroundPainter(
                                color1: Colors.white.withValues(alpha: 0.1),
                                color2: Colors.white.withValues(alpha: 0.05),
                                accent: AppTheme.accentGold.withValues(alpha: 0.2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (state.wishlistedProducts.isEmpty)
                    const SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.favorite_border, size: 80, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('Danh sách yêu thích đang trống', style: TextStyle(fontSize: 16, color: Colors.grey)),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.all(16.0),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: childAspectRatio,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final product = state.wishlistedProducts[index];
                            final price = product.getPriceForRole(userRole);
                            
                            return GestureDetector(
                              onTap: () => Navigator.of(context).push(ProductDetailPage.route(product.id)),
                              child: Card(
                                margin: EdgeInsets.zero,
                                elevation: 4,
                                shadowColor: Colors.black.withValues(alpha: 0.05),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                color: Colors.white,
                                child: Stack(
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        AspectRatio(
                                          aspectRatio: 1.0,
                                          child: ClipRRect(
                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                            child: Image.network(
                                              product.imageUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade100, child: const Icon(Icons.image, size: 40, color: Colors.grey)),
                                            ),
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
                                                  Text(
                                                    currencyFormatter.format(price),
                                                    style: TextStyle(
                                                      color: Theme.of(context).colorScheme.primary,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 15,
                                                    ),
                                                  )
                                                else
                                                  const Text(
                                                    'Liên hệ xem giá',
                                                    style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Wishlist Button Positioned
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white,
                                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                                        ),
                                        child: WishlistButton(productId: product.id),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ).animate().fadeIn(delay: (50 * index).ms).slideY(begin: 0.1, end: 0);
                          },
                          childCount: state.wishlistedProducts.length,
                        ),
                      ),
                    ),
                    
                  SliverToBoxAdapter(child: SizedBox(height: 40 + MediaQuery.of(context).padding.bottom)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}