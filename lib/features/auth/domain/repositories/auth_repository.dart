// lib/features/auth/domain/repositories/auth_repository.dart

import 'package:dartz/dartz.dart';
import 'package:piv_app/core/error/failure.dart';
import 'package:piv_app/data/models/user_model.dart';
import 'package:piv_app/features/auth/domain/entities/social_sign_in_result.dart'; // Thêm import này

abstract class AuthRepository {
  Stream<UserModel> get user;

  Future<Either<Failure, UserModel>> getCurrentUser();

  Future<Either<Failure, Unit>> signUp({
    required String email,
    required String password,
    String? displayName,
    String? referralCode,
  });

  Future<Either<Failure, Unit>> logInWithEmailAndPassword({
    required String email,
    required String password,
  });

  // ***** BẮT ĐẦU THAY ĐỔI *****
  Future<Either<Failure, SocialSignInResult>> signInWithGoogle();
  Future<Either<Failure, SocialSignInResult>> signInWithFacebook();
  Future<Either<Failure, SocialSignInResult>> signInWithApple();
  // ***** KẾT THÚC THAY ĐỔI *****

  Future<Either<Failure, Unit>> signInAnonymously();

  Future<Either<Failure, Unit>> logOut();

  Future<Either<Failure, Unit>> sendEmailVerification();

  Future<Either<Failure, Unit>> sendPasswordResetEmail({required String email});
}