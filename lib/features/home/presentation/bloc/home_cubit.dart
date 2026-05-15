// lib/features/home/presentation/bloc/home_cubit.dart

import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/core/error/failure.dart';
import 'package:piv_app/data/models/news_article_model.dart';
import 'package:piv_app/data/models/user_model.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:piv_app/features/home/data/models/banner_model.dart';
import 'package:piv_app/features/home/data/models/category_model.dart';
import 'package:piv_app/features/home/data/models/product_model.dart';
import 'package:piv_app/features/home/domain/repositories/home_repository.dart';
import 'package:piv_app/features/vouchers/domain/repositories/voucher_repository.dart';
import 'package:piv_app/features/vouchers/data/models/voucher_model.dart';
import 'dart:developer' as developer;

part 'home_state.dart';

String _removeDiacritics(String str) {
  var withDia = 'áàảãạăắằẳẵặâấầẩẫậéèẻẽẹêếềểễệíìỉĩịóòỏõọôốồổỗộơớờởỡợúùủũụưứừửữựýỳỷỹỵđ';
  var withoutDia = 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';
  for (int i = 0; i < withDia.length; i++) {
    str = str.replaceAll(withDia[i], withoutDia[i]);
  }
  return str;
}

class HomeCubit extends Cubit<HomeState> {
  final HomeRepository _homeRepository;
  final AuthBloc _authBloc;
  final VoucherRepository _voucherRepository;
  StreamSubscription? _authSubscription;
  UserModel? _currentUser;

  HomeCubit({
    required HomeRepository homeRepository,
    required AuthBloc authBloc,
    required VoucherRepository voucherRepository,
  })  : _homeRepository = homeRepository,
        _authBloc = authBloc,
        _voucherRepository = voucherRepository,
        super(const HomeState()) {

    final currentState = _authBloc.state;
    // Cho phép tải dữ liệu kể cả khi chưa đăng nhập (user rỗng)
    loadHomeData(currentState.user);

    _authSubscription = _authBloc.stream.listen((authState) {
      // Phản ứng ngay lập tức với bất kỳ sự thay đổi ID người dùng nào
      if (authState.user.id != _currentUser?.id) {
        developer.log('HomeCubit: User ID changed from ${_currentUser?.id} to ${authState.user.id}. Reloading...', name: 'HomeCubit');
        loadHomeData(authState.user);
      }
    });
  }

  Future<void> loadHomeData(UserModel user) async {
    // Luôn cập nhật user hiện tại và phát ra trạng thái loading ngay lập tức
    _currentUser = user;
    emit(state.copyWith(status: HomeStatus.loading, user: user));
    
    developer.log('HomeCubit: Fetching all home screen data for user: ${user.id}', name: 'HomeCubit');

    try {
      final results = await Future.wait([
        _homeRepository.getBanners(),
        _homeRepository.getFeaturedCategories(),
        _homeRepository.getFeaturedProducts(currentUserId: user.id),
        _homeRepository.getLatestNewsArticles(),
        _homeRepository.getAllProducts(currentUserId: user.id),
        _homeRepository.getAllCategories(), // Lấy tất cả danh mục
      ]);
      
      // Fetch vouchers in parallel but do not block UI if it fails
      List<VoucherModel> activeVouchers = [];
      if (user.role == 'agent_1' || user.role == 'agent_2') {
         final voucherResult = await _voucherRepository.getActiveVouchers();
         activeVouchers = voucherResult.getOrElse(() => []);
      }

      List<String> errors = [];
      final finalBanners = (results[0] as Either<Failure, List<BannerModel>>).fold((f) {errors.add(f.message); return <BannerModel>[];}, (r) => r);
      var finalFeaturedCategories = (results[1] as Either<Failure, List<CategoryModel>>).fold((f) {errors.add(f.message); return <CategoryModel>[];}, (r) => r);
      var finalFeaturedProducts = (results[2] as Either<Failure, List<ProductModel>>).fold((f) {errors.add(f.message); return <ProductModel>[];}, (r) => r);
      final finalNews = (results[3] as Either<Failure, List<NewsArticleModel>>).fold((f) {errors.add(f.message); return <NewsArticleModel>[];}, (r) => r);
      final finalAllProducts = (results[4] as Either<Failure, List<ProductModel>>).fold((f) {errors.add(f.message); return <ProductModel>[];}, (r) => r);
      var finalAllCategories = (results[5] as Either<Failure, List<CategoryModel>>).fold((f) {errors.add(f.message); return <CategoryModel>[];}, (r) => r);

      if (errors.isNotEmpty) {
        emit(state.copyWith(status: HomeStatus.error, errorMessage: errors.join('\n')));
      } else {
        // --- LỌC DANH MỤC PHÂN BÓN GỐC ---
        bool isRootCategory(CategoryModel cat) {
          final n = cat.name.toLowerCase();
          final id = cat.id.toLowerCase();
          
          if (id.contains('root')) return true;
          
          final normalizedName = _removeDiacritics(n).replaceAll(RegExp(r'\s+'), '');
          if (normalizedName.contains('phanbongoc')) return true;
          if (normalizedName.contains('goc') && normalizedName.contains('phan')) return true;
          if (normalizedName.contains('root')) return true;
          
          return false;
        }

        finalFeaturedCategories = finalFeaturedCategories.where((cat) => !isRootCategory(cat)).toList();
        finalAllCategories = finalAllCategories.where((cat) => !isRootCategory(cat)).toList();

        // <<< LOGIC QUAN TRỌNG NẰM Ở ĐÂY >>>
        if (user.role != 'admin' && finalFeaturedProducts.length > 8) {
          finalFeaturedProducts.shuffle();
          finalFeaturedProducts = finalFeaturedProducts.take(8).toList();
        }

        emit(state.copyWith(
            status: HomeStatus.success,
            banners: finalBanners,
            categories: finalFeaturedCategories,
            allCategories: finalAllCategories,
            featuredProducts: finalFeaturedProducts,
            filteredFeaturedProducts: finalFeaturedProducts,
            newsArticles: finalNews,
            allProducts: finalAllProducts,
            isSearching: false,
            user: user,
            activeVouchers: activeVouchers,
        ));
      }
    } catch (e) {
      emit(state.copyWith(status: HomeStatus.error, errorMessage: 'Lỗi không xác định: ${e.toString()}'));
    }
  }

  void refreshHomeData() {
    if (_currentUser != null) {
      loadHomeData(_currentUser!);
    }
  }

  void searchFeaturedProducts(String query) {
    if (query.isEmpty) {
      emit(state.copyWith(
        filteredFeaturedProducts: state.featuredProducts,
        isSearching: false,
      ));
      return;
    }
    final normalizedQuery = _removeDiacritics(query.toLowerCase());
    final filtered = state.allProducts.where((product) {
      final normalizedProductName = _removeDiacritics(product.name.toLowerCase());
      final normalizedProductDesc = _removeDiacritics(product.description.toLowerCase());
      return normalizedProductName.contains(normalizedQuery) ||
          normalizedProductDesc.contains(normalizedQuery);
    }).toList();
    emit(state.copyWith(
      filteredFeaturedProducts: filtered,
      isSearching: true,
    ));
  }

  UserModel? get currentUser => _currentUser;

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}