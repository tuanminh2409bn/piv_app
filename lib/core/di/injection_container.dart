//lib/core/di/injection_container.dart

import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:piv_app/app/app_bloc_observer.dart';
import 'package:piv_app/core/services/notification_service.dart';

// Repositories
import 'package:piv_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:piv_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:piv_app/features/home/data/repositories/home_repository_impl.dart';
import 'package:piv_app/features/home/domain/repositories/home_repository.dart';
import 'package:piv_app/features/cart/data/repositories/cart_repository_impl.dart';
import 'package:piv_app/features/cart/domain/repositories/cart_repository.dart';
import 'package:piv_app/features/profile/data/repositories/user_profile_repository_impl.dart';
import 'package:piv_app/features/profile/domain/repositories/user_profile_repository.dart';
import 'package:piv_app/features/search/data/repositories/search_repository_impl.dart';
import 'package:piv_app/features/search/domain/repositories/search_repository.dart';
import 'package:piv_app/features/orders/data/repositories/order_repository_impl.dart';
import 'package:piv_app/features/orders/domain/repositories/order_repository.dart';
import 'package:piv_app/features/admin/data/repositories/storage_repository.dart';
import 'package:piv_app/features/admin/data/repositories/admin_repository_impl.dart';
import 'package:piv_app/features/admin/domain/repositories/admin_repository.dart';
import 'package:piv_app/features/vouchers/data/repositories/voucher_repository_impl.dart';
import 'package:piv_app/features/vouchers/domain/repositories/voucher_repository.dart';
import 'package:piv_app/features/sales_commitment/data/repositories/sales_commitment_repository_impl.dart';
import 'package:piv_app/features/sales_commitment/domain/repositories/sales_commitment_repository.dart';
import 'package:piv_app/features/lucky_wheel/data/repositories/lucky_wheel_repository_impl.dart';
import 'package:piv_app/features/lucky_wheel/domain/repositories/lucky_wheel_repository.dart';
import 'package:piv_app/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:piv_app/features/notifications/domain/repositories/notification_repository.dart';
import 'package:piv_app/features/quick_order/data/repositories/quick_order_repository_impl.dart';
import 'package:piv_app/features/quick_order/domain/repositories/quick_order_repository.dart';
import 'package:piv_app/features/returns/data/repositories/return_repository_impl.dart';
import 'package:piv_app/features/returns/domain/repositories/return_repository.dart';
import 'package:piv_app/features/returns/data/repositories/return_settings_repository_impl.dart';
import 'package:piv_app/features/returns/domain/repositories/return_settings_repository.dart';
import 'package:piv_app/features/admin/data/repositories/admin_settings_repository_impl.dart';
import 'package:piv_app/features/admin/domain/repositories/admin_settings_repository.dart';
import 'package:piv_app/features/admin/data/repositories/special_price_repository_impl.dart';
import 'package:piv_app/features/admin/domain/repositories/special_price_repository.dart';
import 'package:piv_app/features/admin/data/repositories/discount_repository_impl.dart';
import 'package:piv_app/features/admin/domain/repositories/discount_repository.dart';

// Blocs/Cubits
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:piv_app/features/auth/presentation/bloc/login_cubit.dart';
import 'package:piv_app/features/auth/presentation/bloc/register_cubit.dart';
import 'package:piv_app/features/auth/presentation/bloc/forgot_password_cubit.dart';
import 'package:piv_app/features/auth/presentation/bloc/social_sign_in_cubit.dart';
import 'package:piv_app/features/home/presentation/bloc/home_cubit.dart';
import 'package:piv_app/features/news/presentation/bloc/news_detail_cubit.dart';
import 'package:piv_app/features/products/presentation/bloc/product_detail_cubit.dart';
import 'package:piv_app/features/products/presentation/bloc/category_products_cubit.dart';
import 'package:piv_app/features/cart/presentation/bloc/cart_cubit.dart';
import 'package:piv_app/features/cart/presentation/bloc/cart_suggestions_cubit.dart';
import 'package:piv_app/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:piv_app/features/wishlist/presentation/bloc/wishlist_cubit.dart';
import 'package:piv_app/features/search/bloc/search_cubit.dart';
import 'package:piv_app/features/checkout/presentation/bloc/checkout_cubit.dart';
import 'package:piv_app/features/orders/presentation/bloc/my_orders_cubit.dart';
import 'package:piv_app/features/orders/presentation/bloc/order_detail_cubit.dart';
import 'package:piv_app/features/admin/presentation/bloc/admin_orders_cubit.dart';
import 'package:piv_app/features/admin/presentation/bloc/admin_products_cubit.dart';
import 'package:piv_app/features/admin/presentation/bloc/product_form_cubit.dart';
import 'package:piv_app/features/admin/presentation/bloc/admin_categories_cubit.dart';
import 'package:piv_app/features/admin/presentation/bloc/admin_users_cubit.dart';
import 'package:piv_app/features/admin/presentation/bloc/admin_commissions_cubit.dart';
import 'package:piv_app/features/sales_rep/presentation/bloc/sales_rep_cubit.dart';
import 'package:piv_app/features/sales_rep/presentation/bloc/sales_rep_commissions_cubit.dart';
import 'package:piv_app/features/sales_rep/presentation/bloc/agent_orders_cubit.dart';
import 'package:piv_app/features/vouchers/presentation/bloc/voucher_management_cubit.dart';
import 'package:piv_app/features/admin/presentation/bloc/admin_vouchers_cubit.dart';
import 'package:piv_app/features/sales_rep/agent_approval/bloc/agent_approval_cubit.dart';
import 'package:piv_app/features/accountant/presentation/bloc/accountant_agents_cubit.dart';
import 'package:piv_app/features/sales_commitment/presentation/bloc/admin/sales_commitment_admin_cubit.dart';
import 'package:piv_app/features/sales_commitment/presentation/bloc/agent/sales_commitment_agent_cubit.dart';
import 'package:piv_app/features/lucky_wheel/presentation/bloc/admin/lucky_wheel_admin_cubit.dart';
import 'package:piv_app/features/lucky_wheel/presentation/bloc/lucky_wheel_cubit.dart';
import 'package:piv_app/features/lucky_wheel/presentation/bloc/history/spin_history_cubit.dart';
import 'package:piv_app/features/lucky_wheel/presentation/bloc/admin/campaign_form_cubit.dart';
import 'package:piv_app/features/notifications/presentation/bloc/notification_cubit.dart';
import 'package:piv_app/features/returns/presentation/bloc/create_return_request_cubit.dart';
import 'package:piv_app/features/returns/presentation/bloc/admin_returns_cubit.dart';
import 'package:piv_app/features/profile/presentation/bloc/debt_payment_cubit.dart';
import 'package:piv_app/features/admin/presentation/bloc/admin_discount_settings_cubit.dart';
import 'package:piv_app/features/admin/presentation/bloc/admin_discount_requests_cubit.dart';

final sl = GetIt.instance;

Future<void> initializeDependencies() async {
  // Core
  sl.registerLazySingleton(() => AppBlocObserver());
  sl.registerLazySingleton<firebase_auth.FirebaseAuth>(() => firebase_auth.FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => FirebaseFunctions.instanceFor(region: 'asia-southeast1'));
  sl.registerLazySingleton(() => FirebaseStorage.instance);
  sl.registerLazySingleton<GoogleSignIn>(() => GoogleSignIn.instance);
  final prefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => prefs);
  sl.registerLazySingleton(() => NotificationService());

  try {
     await GoogleSignIn.instance.initialize(
       serverClientId: '435533952242-8n673mvm4t37l3i82f5j48hdv4h8uv8m.apps.googleusercontent.com',
     );
  } catch (e) {
    debugPrint('GoogleSignIn initialize error: $e');
  }

  // Repositories
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(firebaseAuth: sl(), firestore: sl(), googleSignIn: sl()));
  sl.registerLazySingleton<HomeRepository>(() => HomeRepositoryImpl(firestore: sl()));
  sl.registerLazySingleton<CartRepository>(() => CartRepositoryImpl(firestore: sl()));
  sl.registerLazySingleton<UserProfileRepository>(() => UserProfileRepositoryImpl(firestore: sl()));
  sl.registerLazySingleton<SearchRepository>(() => SearchRepositoryImpl(prefs: sl()));
  sl.registerLazySingleton<OrderRepository>(() => OrderRepositoryImpl(firestore: sl()));
  sl.registerLazySingleton<AdminRepository>(() => AdminRepositoryImpl(firestore: sl()));
  sl.registerLazySingleton<StorageRepository>(() => StorageRepository());
  sl.registerLazySingleton<VoucherRepository>(() => VoucherRepositoryImpl(firestore: sl()));
  sl.registerLazySingleton<SalesCommitmentRepository>(() => SalesCommitmentRepositoryImpl(firestore: sl(), functions: sl()));
  sl.registerLazySingleton<LuckyWheelRepository>(() => LuckyWheelRepositoryImpl(firestore: sl(), functions: sl(), auth: sl()));
  sl.registerLazySingleton<NotificationRepository>(() => NotificationRepositoryImpl());
  sl.registerLazySingleton<QuickOrderRepository>(() => QuickOrderRepositoryImpl(firestore: sl()));
  sl.registerLazySingleton<ReturnRepository>(() => ReturnRepositoryImpl(firestore: sl(), storage: sl(), auth: sl()));
  sl.registerLazySingleton<ReturnSettingsRepository>(() => ReturnSettingsRepositoryImpl(sl()));
  sl.registerLazySingleton<AdminSettingsRepository>(() => AdminSettingsRepositoryImpl(sl()));
  sl.registerLazySingleton<SpecialPriceRepository>(() => SpecialPriceRepositoryImpl(sl()));
  sl.registerLazySingleton<DiscountRepository>(() => DiscountRepositoryImpl(sl()));

  // Blocs & Cubits
  sl.registerLazySingleton<AuthBloc>(() => AuthBloc(authRepository: sl(), userProfileRepository: sl()));
  sl.registerFactory<LoginCubit>(() => LoginCubit(authRepository: sl()));
  sl.registerFactory<RegisterCubit>(() => RegisterCubit(authRepository: sl()));
  sl.registerFactory<ForgotPasswordCubit>(() => ForgotPasswordCubit(authRepository: sl()));
  sl.registerFactory<SocialSignInCubit>(() => SocialSignInCubit(authRepository: sl()));
  
  sl.registerFactory<HomeCubit>(() => HomeCubit(homeRepository: sl(), authBloc: sl()));
  sl.registerFactory<NewsDetailCubit>(() => NewsDetailCubit(homeRepository: sl()));
  sl.registerFactory<ProductDetailCubit>(() => ProductDetailCubit(homeRepository: sl(), authBloc: sl()));
  sl.registerFactory<CategoryProductsCubit>(() => CategoryProductsCubit(homeRepository: sl()));
  
  sl.registerLazySingleton<CartCubit>(() => CartCubit(cartRepository: sl(), authBloc: sl()));
  sl.registerFactory<CartSuggestionsCubit>(() => CartSuggestionsCubit(homeRepository: sl()));
  
  sl.registerLazySingleton<ProfileCubit>(() => ProfileCubit(userProfileRepository: sl(), authBloc: sl()));
  sl.registerFactory(() => DebtPaymentCubit(authBloc: sl(), orderRepository: sl(), userProfileRepository: sl()));
  
  sl.registerLazySingleton<WishlistCubit>(() => WishlistCubit(userProfileRepository: sl(), authBloc: sl()));
  // WishlistPageCubit is created in the view, no need to register here.
  
  sl.registerFactory<SearchCubit>(() => SearchCubit(searchRepository: sl(), homeRepository: sl(), authBloc: sl()));
  sl.registerFactory<CheckoutCubit>(() => CheckoutCubit(userProfileRepository: sl(), orderRepository: sl(), authBloc: sl(), cartCubit: sl(), voucherRepository: sl(), functions: sl()));
  sl.registerLazySingleton<MyOrdersCubit>(() => MyOrdersCubit(orderRepository: sl(), authBloc: sl()));
  sl.registerFactory<OrderDetailCubit>(() => OrderDetailCubit(orderRepository: sl(), userProfileRepository: sl(), returnRepository: sl(), voucherRepository: sl(), authBloc: sl()));
  
  sl.registerFactory<AdminOrdersCubit>(() => AdminOrdersCubit(orderRepository: sl(), userProfileRepository: sl()));
  sl.registerFactory<AdminProductsCubit>(() => AdminProductsCubit(homeRepository: sl()));
  sl.registerFactory(() => AdminUsersCubit(adminRepository: sl(), authBloc: sl()));
  sl.registerFactory<ProductFormCubit>(() => ProductFormCubit(homeRepository: sl(), storageRepository: sl(), adminRepository: sl()));
  sl.registerFactory<AdminCategoriesCubit>(() => AdminCategoriesCubit(homeRepository: sl<HomeRepository>()));
  sl.registerFactory<AdminCommissionsCubit>(() => AdminCommissionsCubit(orderRepository: sl(), adminRepository: sl(), authBloc: sl()));
  sl.registerFactory<AdminVouchersCubit>(() => AdminVouchersCubit(firestore: sl(), authBloc: sl()));
  sl.registerFactory<AdminDiscountSettingsCubit>(() => AdminDiscountSettingsCubit(sl()));
  sl.registerFactory(() => AdminDiscountRequestsCubit(repository: sl(), authBloc: sl()));
  
  sl.registerFactory<SalesRepCubit>(() => SalesRepCubit(adminRepository: sl(), authBloc: sl()));
  sl.registerFactory<SalesRepCommissionsCubit>(() => SalesRepCommissionsCubit(orderRepository: sl(), authBloc: sl()));
  sl.registerFactory<AgentOrdersCubit>(() => AgentOrdersCubit(orderRepository: sl(), authBloc: sl()));
  sl.registerFactory<VoucherManagementCubit>(() => VoucherManagementCubit(voucherRepository: sl(), authBloc: sl()));
  sl.registerFactory(() => AgentApprovalCubit(userProfileRepository: sl()));
  sl.registerFactory<AccountantAgentsCubit>(() => AccountantAgentsCubit(userProfileRepository: sl()));
  
  sl.registerFactory(() => SalesCommitmentAgentCubit(repository: sl(), authBloc: sl()));
  sl.registerFactory(() => SalesCommitmentAdminCubit(repository: sl()));
  
  sl.registerFactory(() => LuckyWheelCubit(repository: sl(), authBloc: sl()));
  sl.registerFactory(() => LuckyWheelAdminCubit(repository: sl()));
  sl.registerFactory(() => SpinHistoryCubit(repository: sl()));
  sl.registerFactory(() => CampaignFormCubit(repository: sl()));
  
  sl.registerFactory(() => NotificationCubit(notificationRepository: sl(), authBloc: sl()));
  sl.registerFactory(() => CreateReturnRequestCubit(returnRepository: sl(), settingsRepository: sl()));
  sl.registerFactory(() => AdminReturnsCubit(returnRepository: sl()));
}
