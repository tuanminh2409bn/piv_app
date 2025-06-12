import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';

// Auth Feature
import 'package:piv_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:piv_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:piv_app/features/auth/presentation/bloc/login_cubit.dart';
import 'package:piv_app/features/auth/presentation/bloc/register_cubit.dart';

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

// Profile Feature
import 'package:piv_app/features/profile/domain/repositories/user_profile_repository.dart';
import 'package:piv_app/features/profile/data/repositories/user_profile_repository_impl.dart';
import 'package:piv_app/features/profile/presentation/bloc/profile_cubit.dart';

// Checkout & Order Feature
import 'package:piv_app/features/checkout/presentation/bloc/checkout_cubit.dart';
import 'package:piv_app/features/orders/domain/repositories/order_repository.dart';
import 'package:piv_app/features/orders/data/repositories/order_repository_impl.dart';
import 'package:piv_app/features/orders/presentation/bloc/my_orders_cubit.dart';
import 'package:piv_app/features/orders/presentation/bloc/order_detail_cubit.dart';

// Admin Feature
import 'package:piv_app/features/admin/data/repositories/storage_repository.dart';
import 'package:piv_app/features/admin/presentation/bloc/admin_orders_cubit.dart';
import 'package:piv_app/features/admin/presentation/bloc/admin_products_cubit.dart';
import 'package:piv_app/features/admin/presentation/bloc/product_form_cubit.dart';
import 'package:piv_app/features/admin/presentation/bloc/admin_categories_cubit.dart';


final sl = GetIt.instance;

Future<void> initializeDependencies() async {
  // --- Core ---
  sl.registerLazySingleton<firebase_auth.FirebaseAuth>(() => firebase_auth.FirebaseAuth.instance);
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);

  // --- Features ---

  // == Auth ==
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(firebaseAuth: sl(), firestore: sl()));
  sl.registerLazySingleton<AuthBloc>(() => AuthBloc(authRepository: sl()));
  sl.registerFactory<LoginCubit>(() => LoginCubit(authRepository: sl()));
  sl.registerFactory<RegisterCubit>(() => RegisterCubit(authRepository: sl()));

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

  // == Profile ==
  sl.registerLazySingleton<UserProfileRepository>(() => UserProfileRepositoryImpl(firestore: sl()));
  sl.registerLazySingleton<ProfileCubit>(() => ProfileCubit(userProfileRepository: sl(), authBloc: sl()));

  // == Order & Checkout ==
  sl.registerLazySingleton<OrderRepository>(() => OrderRepositoryImpl(firestore: sl()));
  sl.registerFactory<CheckoutCubit>(
        () => CheckoutCubit(
      userProfileRepository: sl(),
      orderRepository: sl(),
      authBloc: sl(),
      cartCubit: sl(),
    ),
  );
  sl.registerLazySingleton<MyOrdersCubit>(() => MyOrdersCubit(orderRepository: sl(), authBloc: sl()));
  sl.registerFactory<OrderDetailCubit>(() => OrderDetailCubit(orderRepository: sl()));

  // == Admin ==
  sl.registerLazySingleton<StorageRepository>(() => StorageRepository());
  sl.registerFactory<AdminOrdersCubit>(() => AdminOrdersCubit(orderRepository: sl()));
  sl.registerFactory<AdminProductsCubit>(() => AdminProductsCubit(homeRepository: sl()));
  sl.registerFactory<ProductFormCubit>(
        () => ProductFormCubit(
      homeRepository: sl(),
      storageRepository: sl(),
    ),
  );
  sl.registerFactory<AdminCategoriesCubit>(
        () => AdminCategoriesCubit(homeRepository: sl<HomeRepository>()),
  );
}
