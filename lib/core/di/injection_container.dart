import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Auth Feature
import 'package:piv_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:piv_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:piv_app/features/auth/presentation/bloc/login_cubit.dart';
import 'package:piv_app/features/auth/presentation/bloc/register_cubit.dart';
import 'package:piv_app/features/auth/presentation/bloc/social_sign_in_cubit.dart';

// Home Feature
import 'package:piv_app/features/home/presentation/bloc/home_cubit.dart';
import 'package:piv_app/features/home/domain/repositories/home_repository.dart';
import 'package:piv_app/features/home/data/repositories/home_repository_impl.dart';

// News Feature
import 'package:piv_app/features/news/presentation/bloc/news_detail_cubit.dart';

// Product Feature
import 'package:piv_app/features/products/presentation/bloc/product_detail_cubit.dart';
import 'package:piv_app/features/products/presentation/bloc/category_products_cubit.dart';

// Cart Feature
import 'package:piv_app/features/cart/domain/repositories/cart_repository.dart';
import 'package:piv_app/features/cart/data/repositories/cart_repository_impl.dart';
import 'package:piv_app/features/cart/presentation/bloc/cart_cubit.dart';
import 'package:piv_app/features/cart/presentation/bloc/cart_suggestions_cubit.dart';

// Profile Feature
import 'package:piv_app/features/profile/domain/repositories/user_profile_repository.dart';
import 'package:piv_app/features/profile/data/repositories/user_profile_repository_impl.dart';
import 'package:piv_app/features/profile/presentation/bloc/profile_cubit.dart';

// Wishlist Feature
import 'package:piv_app/features/wishlist/presentation/bloc/wishlist_cubit.dart';
import 'package:piv_app/features/wishlist/presentation/pages/wishlist_page.dart';

// Search Feature
import 'package:piv_app/features/search/data/repositories/search_repository_impl.dart';
import 'package:piv_app/features/search/domain/repositories/search_repository.dart';
import 'package:piv_app/features/search/bloc/search_cubit.dart';

// Checkout & Order Feature
import 'package:piv_app/features/checkout/presentation/bloc/checkout_cubit.dart';
import 'package:piv_app/features/orders/domain/repositories/order_repository.dart';
import 'package:piv_app/features/orders/data/repositories/order_repository_impl.dart';
import 'package:piv_app/features/orders/presentation/bloc/my_orders_cubit.dart';
import 'package:piv_app/features/orders/presentation/bloc/order_detail_cubit.dart';

// Admin Feature
import 'package:piv_app/features/admin/data/repositories/storage_repository.dart';
import 'package:piv_app/features/admin/domain/repositories/admin_repository.dart';
import 'package:piv_app/features/admin/data/repositories/admin_repository_impl.dart';
import 'package:piv_app/features/admin/presentation/bloc/admin_orders_cubit.dart';
import 'package:piv_app/features/admin/presentation/bloc/admin_products_cubit.dart';
import 'package:piv_app/features/admin/presentation/bloc/product_form_cubit.dart';
import 'package:piv_app/features/admin/presentation/bloc/admin_categories_cubit.dart';
import 'package:piv_app/features/admin/presentation/bloc/admin_users_cubit.dart';
import 'package:piv_app/features/admin/presentation/bloc/admin_commissions_cubit.dart';

// Sales Rep Feature
import 'package:piv_app/features/sales_rep/presentation/bloc/sales_rep_cubit.dart';
import 'package:piv_app/features/sales_rep/presentation/bloc/sales_rep_commissions_cubit.dart';

import 'package:piv_app/features/quick_order/presentation/bloc/quick_order_cubit.dart';


final sl = GetIt.instance;

Future<void> initializeDependencies() async {
  // --- Core ---
  sl.registerLazySingleton<firebase_auth.FirebaseAuth>(() => firebase_auth.FirebaseAuth.instance);
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);

  final prefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => prefs);

  // --- Features ---

  // == Auth ==
  sl.registerLazySingleton<GoogleSignIn>(() => GoogleSignIn());
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(firebaseAuth: sl(), firestore: sl(), googleSignIn: sl()));
  sl.registerLazySingleton<AuthBloc>(() => AuthBloc(authRepository: sl(), userProfileRepository: sl()));
  sl.registerFactory<LoginCubit>(() => LoginCubit(authRepository: sl()));
  sl.registerFactory<RegisterCubit>(() => RegisterCubit(authRepository: sl()));
  sl.registerFactory<SocialSignInCubit>(() => SocialSignInCubit(authRepository: sl()));

  // == Home ==
  sl.registerLazySingleton<HomeRepository>(() => HomeRepositoryImpl(firestore: sl()));
  sl.registerFactory<HomeCubit>(() => HomeCubit(homeRepository: sl()));

  // == News ==
  sl.registerFactory<NewsDetailCubit>(() => NewsDetailCubit(homeRepository: sl()));

  // == Product & Category ==
  sl.registerFactory<ProductDetailCubit>(() => ProductDetailCubit(homeRepository: sl()));
  sl.registerFactory<CategoryProductsCubit>(() => CategoryProductsCubit(homeRepository: sl()));

  // == Cart ==
  sl.registerLazySingleton<CartRepository>(() => CartRepositoryImpl(firestore: sl()));
  sl.registerLazySingleton<CartCubit>(() => CartCubit(cartRepository: sl(), authBloc: sl()));
  sl.registerFactory<CartSuggestionsCubit>(() => CartSuggestionsCubit(homeRepository: sl()));

  // == Profile ==
  sl.registerLazySingleton<UserProfileRepository>(() => UserProfileRepositoryImpl(firestore: sl()));
  sl.registerLazySingleton<ProfileCubit>(() => ProfileCubit(userProfileRepository: sl(), authBloc: sl()));

  // == Wishlist ==
  sl.registerLazySingleton<WishlistCubit>(() => WishlistCubit(userProfileRepository: sl(), authBloc: sl()));
  sl.registerFactory<WishlistPageCubit>(() => WishlistPageCubit(homeRepository: sl(), wishlistCubit: sl()));

  // == Search ==
  sl.registerLazySingleton<SearchRepository>(() => SearchRepositoryImpl(prefs: sl()));
  sl.registerFactory<SearchCubit>(() => SearchCubit(searchRepository: sl(), homeRepository: sl()));

  // == Order & Checkout ==
  sl.registerLazySingleton<OrderRepository>(() => OrderRepositoryImpl(firestore: sl()));
  sl.registerFactory<CheckoutCubit>(() => CheckoutCubit(userProfileRepository: sl(), orderRepository: sl(), authBloc: sl(), cartCubit: sl()));
  sl.registerLazySingleton<MyOrdersCubit>(() => MyOrdersCubit(orderRepository: sl(), authBloc: sl()));
  sl.registerFactory<OrderDetailCubit>(() => OrderDetailCubit(orderRepository: sl()));

  // == Admin ==
  sl.registerLazySingleton<StorageRepository>(() => StorageRepository());
  sl.registerLazySingleton<AdminRepository>(() => AdminRepositoryImpl(firestore: sl()));
  sl.registerFactory<AdminOrdersCubit>(() => AdminOrdersCubit(orderRepository: sl()));
  sl.registerFactory<AdminProductsCubit>(() => AdminProductsCubit(homeRepository: sl()));
  sl.registerFactory<AdminUsersCubit>(() => AdminUsersCubit(adminRepository: sl()));
  sl.registerFactory<ProductFormCubit>(() => ProductFormCubit(homeRepository: sl(), storageRepository: sl()));
  sl.registerFactory<AdminCategoriesCubit>(() => AdminCategoriesCubit(homeRepository: sl<HomeRepository>()));
  sl.registerFactory<AdminCommissionsCubit>(() => AdminCommissionsCubit(orderRepository: sl(), authBloc: sl()));

  // == Sales Rep ==
  sl.registerFactory<SalesRepCubit>(() => SalesRepCubit(adminRepository: sl(), authBloc: sl()));
  sl.registerFactory<SalesRepCommissionsCubit>(() => SalesRepCommissionsCubit(orderRepository: sl(), authBloc: sl()));

  sl.registerFactory<QuickOrderCubit>(() => QuickOrderCubit(homeRepository: sl(), cartCubit: sl()));
}