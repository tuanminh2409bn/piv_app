import 'dart:async';
import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
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
    _firebaseAuth.authStateChanges().listen((firebaseUser) async {
      if (firebaseUser == null) {
        _userStreamController.add(UserModel.empty);
      } else {
        final userDoc = _firestore.collection('users').doc(firebaseUser.uid);
        final snapshot = await userDoc.get();

        if (snapshot.exists && snapshot.data() != null) {
          _userStreamController.add(UserModel.fromJson(snapshot.data()!));
        } else {
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
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
        FacebookAuth.instance.logOut(),
      ]);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định khi đăng xuất: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Unit>> sendEmailVerification() async {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, Unit>> sendPasswordResetEmail({required String email}) async {
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

      return _linkOrCreateUser(credential);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(AuthFailure(e.message ?? 'Lỗi đăng nhập Google.'));
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Unit>> signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login();
      if (result.status == LoginStatus.success) {
        final AccessToken accessToken = result.accessToken!;
        final firebase_auth.AuthCredential credential =
        firebase_auth.FacebookAuthProvider.credential(accessToken.tokenString);

        return _linkOrCreateUser(credential);
      } else if (result.status == LoginStatus.cancelled) {
        return Left(AuthFailure('Đã hủy đăng nhập bằng Facebook.'));
      } else {
        return Left(AuthFailure(result.message ?? 'Lỗi đăng nhập Facebook không xác định.'));
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(AuthFailure(e.message ?? 'Lỗi đăng nhập Facebook.'));
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định: ${e.toString()}'));
    }
  }

  /// Xử lý logic chung cho việc đăng nhập mạng xã hội: liên kết hoặc tạo người dùng mới.
  Future<Either<Failure, Unit>> _linkOrCreateUser(firebase_auth.AuthCredential credential) async {
    try {
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        final userDoc = _firestore.collection('users').doc(firebaseUser.uid);
        final docSnapshot = await userDoc.get();

        if (!docSnapshot.exists) {
          developer.log('Creating new user in Firestore: ${firebaseUser.uid}', name: 'AuthRepository');
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
        return Left(AuthFailure('Không thể lấy thông tin người dùng.'));
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      // ** SỬA LỖI Ở ĐÂY **
      if (e.code == 'account-exists-with-different-credential' && e.email != null) {
        final methods = await _firebaseAuth.fetchSignInMethodsForEmail(e.email!);

        // Thêm kiểm tra an toàn: chỉ truy cập .first nếu danh sách không rỗng
        if (methods.isNotEmpty) {
          String provider = methods.first.replaceAll('.com', '').capitalize();
          return Left(AuthFailure('Email này đã được sử dụng. Vui lòng đăng nhập bằng $provider.'));
        } else {
          // Trường hợp đặc biệt: trả về một lỗi chung hơn
          return Left(AuthFailure('Tài khoản đã tồn tại với một phương thức đăng nhập khác.'));
        }
      }
      return Left(AuthFailure(e.message ?? 'Lỗi xác thực.'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

// Extension để viết hoa chữ cái đầu
extension StringExtension on String {
  String capitalize() {
    if (this.isEmpty) return "";
    return "${this[0].toUpperCase()}${this.substring(1).toLowerCase()}";
  }
}
