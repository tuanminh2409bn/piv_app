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
// Import HomeRepository và Impl
import 'package:piv_app/features/home/domain/repositories/home_repository.dart';
import 'package:piv_app/features/home/data/repositories/home_repository_impl.dart';


final sl = GetIt.instance;

Future<void> initializeDependencies() async {
  // --- Core ---
  sl.registerLazySingleton<firebase_auth.FirebaseAuth>(() => firebase_auth.FirebaseAuth.instance);
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);

  // --- Features ---

  // == Auth ==
  sl.registerLazySingleton<AuthRepository>(
        () => AuthRepositoryImpl(
      firebaseAuth: sl<firebase_auth.FirebaseAuth>(),
      firestore: sl<FirebaseFirestore>(),
    ),
  );
  sl.registerLazySingleton<AuthBloc>(
        () => AuthBloc(authRepository: sl<AuthRepository>()),
  );
  sl.registerFactory<LoginCubit>(
        () => LoginCubit(authRepository: sl<AuthRepository>()),
  );
  sl.registerFactory<RegisterCubit>(
        () => RegisterCubit(authRepository: sl<AuthRepository>()),
  );

  // == Home ==
  // Đăng ký HomeRepository
  sl.registerLazySingleton<HomeRepository>(
        () => HomeRepositoryImpl(firestore: sl<FirebaseFirestore>()),
  );

  sl.registerFactory<HomeCubit>(
        () => HomeCubit(homeRepository: sl<HomeRepository>()), // Truyền HomeRepository vào HomeCubit
  );
}
    