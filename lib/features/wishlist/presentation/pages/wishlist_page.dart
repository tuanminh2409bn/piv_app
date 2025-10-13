// lib/features/wishlist/presentation/pages/wishlist_page.dart

import 'dart:async'; // <<< THÊM DÒNG NÀY ĐỂ SỬA LỖI
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:piv_app/core/di/injection_container.dart';
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
    final authState = context.read<AuthBloc>().state;
    String userRole = 'agent_2';
    if(authState is AuthAuthenticated) {
      userRole = authState.user.role;
    }

    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách yêu thích'),
      ),
      body: BlocBuilder<WishlistPageCubit, WishlistPageState>(
        builder: (context, state) {
          if (state.status == WishlistPageStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == WishlistPageStatus.error) {
            return Center(child: Text(state.errorMessage ?? 'Lỗi tải dữ liệu.'));
          }
          if (state.wishlistedProducts.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Danh sách yêu thích của bạn đang trống', style: TextStyle(fontSize: 18)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16.0),
            itemCount: state.wishlistedProducts.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final product = state.wishlistedProducts[index];
              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(product.imageUrl, width: 70, height: 70, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.image)),
                ),
                title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  '${currencyFormatter.format(product.getPriceForRole(userRole))} / ${product.displayUnit}',
                  style: TextStyle(color: Theme.of(context).colorScheme.primary),
                ),
                trailing: WishlistButton(productId: product.id),
                onTap: () => Navigator.of(context).push(ProductDetailPage.route(product.id)),
              );
            },
          );
        },
      ),
    );
  }
}