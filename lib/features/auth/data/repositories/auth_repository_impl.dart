import 'dart:async';
import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:piv_app/core/error/failure.dart';
import 'package:piv_app/data/models/user_model.dart';
import 'package:piv_app/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  final _userStreamController = StreamController<UserModel>.broadcast();

  AuthRepositoryImpl({
    firebase_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn() {
    // Lắng nghe sự thay đổi trạng thái người dùng từ Firebase Auth
    // và cập nhật stream của chúng ta
    _firebaseAuth.authStateChanges().listen((firebaseUser) async {
      if (firebaseUser == null) {
        _userStreamController.add(UserModel.empty);
      } else {
        final userDoc = _firestore.collection('users').doc(firebaseUser.uid);
        final snapshot = await userDoc.get();

        if (snapshot.exists && snapshot.data() != null) {
          _userStreamController.add(UserModel.fromJson(snapshot.data()!));
        } else {
          // Trường hợp user đã xác thực nhưng chưa có trong Firestore
          // (ví dụ: đăng nhập lần đầu bằng Google), tạo một UserModel tạm thời
          final newUser = UserModel(
            id: firebaseUser.uid,
            email: firebaseUser.email,
            displayName: firebaseUser.displayName,
            photoUrl: firebaseUser.photoURL,
          );
          _userStreamController.add(newUser);
        }
      }
    });
  }

  @override
  Stream<UserModel> get user => _userStreamController.stream;

  @override
  Future<Either<Failure, UserModel>> getCurrentUser() async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser != null) {
        final userDoc = _firestore.collection('users').doc(firebaseUser.uid);
        final snapshot = await userDoc.get();
        if (snapshot.exists && snapshot.data() != null) {
          return Right(UserModel.fromJson(snapshot.data()!));
        } else {
          return Right(UserModel(
            id: firebaseUser.uid,
            email: firebaseUser.email,
            displayName: firebaseUser.displayName,
            photoUrl: firebaseUser.photoURL,
          ));
        }
      } else {
        return Right(UserModel.empty);
      }
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định khi lấy người dùng hiện tại: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Unit>> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        final firebaseUser = userCredential.user!;
        if (displayName != null && displayName.isNotEmpty) {
          await firebaseUser.updateDisplayName(displayName);
        }

        final newUser = UserModel(
          id: firebaseUser.uid,
          email: firebaseUser.email,
          displayName: displayName ?? firebaseUser.displayName,
        );
        await _firestore.collection('users').doc(firebaseUser.uid).set(newUser.toJson());
        return const Right(unit);
      } else {
        return const Left(AuthFailure('Không thể tạo người dùng.'));
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(AuthFailure(e.message ?? 'Lỗi đăng ký.'));
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Unit>> logInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return const Right(unit);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(AuthFailure(e.message ?? 'Lỗi đăng nhập.'));
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Unit>> logOut() async {
    try {
      // Đảm bảo đăng xuất khỏi cả Firebase và Google
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
      ]);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định khi đăng xuất: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Unit>> sendEmailVerification() async {
    // TODO: Implement sendEmailVerification
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, Unit>> sendPasswordResetEmail({required String email}) async {
    // TODO: Implement sendPasswordResetEmail
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, Unit>> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return Left(AuthFailure('Đã hủy đăng nhập bằng Google.'));
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final firebase_auth.AuthCredential credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        final userDoc = _firestore.collection('users').doc(firebaseUser.uid);
        final docSnapshot = await userDoc.get();

        if (!docSnapshot.exists) {
          developer.log('Creating new user in Firestore for Google Sign-In: ${firebaseUser.uid}', name: 'AuthRepository');
          final newUser = UserModel(
            id: firebaseUser.uid,
            email: firebaseUser.email,
            displayName: firebaseUser.displayName,
            photoUrl: firebaseUser.photoURL,
            role: 'customer',
          );
          await userDoc.set(newUser.toJson());
        }
        return const Right(unit);
      } else {
        return Left(AuthFailure('Không thể lấy thông tin người dùng từ Google.'));
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(AuthFailure(e.message ?? 'Lỗi đăng nhập Google.'));
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định: ${e.toString()}'));
    }
  }
}
