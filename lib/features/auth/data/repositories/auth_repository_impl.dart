// lib/features/auth/data/repositories/auth_repository_impl.dart

import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:piv_app/core/error/failure.dart';
import 'package:piv_app/data/models/user_model.dart';
import 'package:piv_app/features/auth/domain/entities/social_sign_in_result.dart';
import 'package:piv_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';

class AuthRepositoryImpl implements AuthRepository {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;
  final _userStreamController = StreamController<UserModel>.broadcast();

  AuthRepositoryImpl({
    firebase_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })
      :
        _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(scopes: ['email']) {
    _firebaseAuth.authStateChanges().listen((firebaseUser) async {
      if (firebaseUser == null) {
        // Người dùng đã đăng xuất, phát ra user rỗng
        _userStreamController.add(UserModel.empty);
      } else {
        // Người dùng đã đăng nhập, kiểm tra trong Firestore
        final userDocRef = _firestore.collection('users').doc(firebaseUser.uid);
        final userDoc = await userDocRef.get();

        if (userDoc.exists && userDoc.data() != null) {
          // Document người dùng tồn tại, xử lý như bình thường
          final user = UserModel.fromJson(userDoc.data()!);
          if (user.status != 'active') {
            developer.log('User ${user.id} logged in but status is ${user
                .status}. Forcing logout.', name: 'AuthRepository');
            await logOut(); // Đăng xuất sẽ tự kích hoạt lại stream này với user là null
          } else {
            _userStreamController.add(user);
          }
        } else {
          // Document người dùng CHƯA tồn tại
          // Kiểm tra xem đây có phải là người dùng ẩn danh (khách) không
          if (firebaseUser.isAnonymous) {
            developer.log('New anonymous user detected (${firebaseUser
                .uid}). Creating guest document.', name: 'AuthRepository');
            // Tạo một UserModel cho khách
            final guestUser = UserModel(
              id: firebaseUser.uid,
              displayName: 'Khách',
              role: 'guest',
              status: 'active',
              referralPromptPending: false,
            );
            // Lưu document vào Firestore
            await userDocRef.set(guestUser.toJson());
            // Phát ra UserModel của khách để AuthBloc xử lý
            _userStreamController.add(guestUser);
          } else {
            // Đây là một người dùng mới (ví dụ: đăng nhập bằng Google lần đầu)
            // nhưng document chưa được tạo. _linkOrCreateUser sẽ xử lý việc này.
            // Trong lúc chờ, chúng ta có thể coi họ là chưa xác thực.
            _userStreamController.add(UserModel.empty);
          }
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
        final userDoc = await _firestore.collection('users').doc(
            firebaseUser.uid).get();
        if (userDoc.exists && userDoc.data() != null) {
          return Right(UserModel.fromJson(userDoc.data()!));
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
      return Left(ServerFailure(
          'Lỗi không xác định khi lấy người dùng hiện tại: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Unit>> signUp({
    required String email,
    required String password,
    String? displayName,
    String? referralCode,
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

        String? foundReferrerId;
        String? foundSalesRepId;

        if (referralCode != null && referralCode.isNotEmpty) {
          final referrerDoc = await _firestore.collection('users').doc(
              referralCode).get();
          if (referrerDoc.exists) {
            foundReferrerId = referrerDoc.id;
            final referrerData = UserModel.fromJson(referrerDoc.data()!);
            if (referrerData.role == 'sales_rep') {
              foundSalesRepId = referrerDoc.id;
            }
          }
        }

        final newUser = UserModel(
          id: firebaseUser.uid,
          email: firebaseUser.email,
          displayName: displayName ?? firebaseUser.displayName,
          referrerId: foundReferrerId,
          salesRepId: foundSalesRepId,
          referralPromptPending: (foundReferrerId == null),
        );
        await _firestore.collection('users').doc(firebaseUser.uid).set(
            newUser.toJson());
        await _firebaseAuth.signOut();
        return const Right(unit);
      } else {
        return const Left(AuthFailure('Không thể tạo người dùng.'));
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return Left(AuthFailure('Địa chỉ email này đã được sử dụng.'));
      }
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
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        return Left(
            AuthFailure('Đăng nhập thất bại, không có thông tin người dùng.'));
      }

      final userDoc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();
      if (!userDoc.exists) {
        await _firebaseAuth.signOut();
        return Left(AuthFailure(
            'Tài khoản không tồn tại trong hệ thống. Vui lòng liên hệ quản trị viên.'));
      }

      final user = UserModel.fromJson(userDoc.data()!);
      if (user.status == 'pending_approval') {
        await _firebaseAuth.signOut();
        return Left(AuthFailure('Tài khoản của bạn đang chờ phê duyệt.'));
      }

      if (user.status == 'suspended') {
        await _firebaseAuth.signOut();
        return Left(AuthFailure('Tài khoản của bạn đã bị khóa.'));
      }

      return const Right(unit);
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        return Left(AuthFailure('Email hoặc mật khẩu không chính xác.'));
      }
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
      return Left(
          ServerFailure('Lỗi không xác định khi đăng xuất: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Unit>> sendEmailVerification() async {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, Unit>> sendPasswordResetEmail(
      {required String email}) async {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, SocialSignInResult>> signInWithGoogle() async {
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

      return _linkOrCreateUser(
        credential: credential,
        email: googleUser.email,
        displayName: googleUser.displayName,
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(AuthFailure(e.message ?? 'Lỗi đăng nhập Google.'));
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, SocialSignInResult>> signInWithFacebook() async {
    try {
      final status = await AppTrackingTransparency.requestTrackingAuthorization();
      developer.log('App Tracking Transparency status: $status', name: 'AuthRepository');

      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['public_profile', 'email'],
        loginTracking: LoginTracking.enabled,
      );

      if (result.status == LoginStatus.success) {
        final AccessToken accessToken = result.accessToken!;
        final firebase_auth.AuthCredential credential = firebase_auth.FacebookAuthProvider.credential(accessToken.tokenString);

        final userData = await FacebookAuth.instance.getUserData();
        final String? email = userData['email'];
        final String? displayName = userData['name'];

        return _linkOrCreateUser(
          credential: credential,
          email: email,
          displayName: displayName,
        );
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

  @override
  Future<Either<Failure, SocialSignInResult>> signInWithApple() async {
    try {
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
        nonce: nonce,
      );

      final oauthCredential = firebase_auth.OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
        accessToken: appleCredential.authorizationCode,
      );

      String? displayName;
      if (appleCredential.givenName != null || appleCredential.familyName != null) {
        displayName = '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'.trim();
      }

      return _linkOrCreateUser(
        credential: oauthCredential,
        email: appleCredential.email,
        displayName: displayName,
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(AuthFailure(e.message ?? 'Lỗi đăng nhập Apple.'));
    } catch (e) {
      if (e is SignInWithAppleAuthorizationException && e.code == AuthorizationErrorCode.canceled) {
        return Left(AuthFailure('Đã hủy đăng nhập bằng Apple.'));
      }
      return Left(ServerFailure('Lỗi không xác định: ${e.toString()}'));
    }
  }

  Future<Either<Failure, SocialSignInResult>> _linkOrCreateUser({
    required firebase_auth.AuthCredential credential,
    String? email,
    String? displayName,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        final userDoc = _firestore.collection('users').doc(firebaseUser.uid);
        final docSnapshot = await userDoc.get();

        final bool isNewUser = userCredential.additionalUserInfo?.isNewUser ?? !docSnapshot.exists;

        if (isNewUser) {
          developer.log('Creating new user in Firestore: ${firebaseUser.uid}', name: 'AuthRepository');
          final newUser = UserModel(
            id: firebaseUser.uid,
            email: email ?? firebaseUser.email,
            displayName: displayName ?? firebaseUser.displayName,
            photoUrl: firebaseUser.photoURL,
            role: 'agent_2', // Hoặc vai trò mặc định khác
            status: 'pending_approval',
            referralPromptPending: true,
          );
          await userDoc.set(newUser.toJson());
        }

        // Đọc lại document để lấy thông tin status mới nhất
        final updatedUserSnapshot = await userDoc.get();
        if (!updatedUserSnapshot.exists) {
          await logOut();
          return Left(AuthFailure('Không tìm thấy thông tin tài khoản sau khi đăng nhập.'));
        }

        final user = UserModel.fromJson(updatedUserSnapshot.data()!);
        if (user.status != 'active') {
          await logOut();
          // Nếu user đang chờ duyệt (hoặc bị khóa), ta vẫn coi đây là một
          // kết quả "thành công" về mặt đăng ký và trả về isNewUser.
          // UI sẽ dựa vào isNewUser để hiển thị thông báo phù hợp.
          return Right(SocialSignInResult(isNewUser: isNewUser));
        }

        // Nếu user active, trả về kết quả thành công và isNewUser (sẽ là false cho user cũ).
        return Right(SocialSignInResult(isNewUser: isNewUser));
      } else {
        return Left(AuthFailure('Không thể lấy thông tin người dùng.'));
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        return Left(AuthFailure('Tài khoản đã tồn tại với một phương thức đăng nhập khác.'));
      }
      return Left(ServerFailure(e.message ?? e.toString()));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> signInAnonymously() async {
    try {
      await _firebaseAuth.signInAnonymously();
      return const Right(unit);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(AuthFailure(e.message ?? 'Lỗi đăng nhập khách.'));
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định: ${e.toString()}'));
    }
  }

  /// Tạo một chuỗi ngẫu nhiên (nonce) cho việc đăng nhập.
  String _generateNonce([int length = 32]) {
    final random = Random.secure();
    final values = List<int>.generate(length, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }

  /// Băm một chuỗi sử dụng SHA256.
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}

extension StringExtension on String {
  String capitalize() {
    if (this.isEmpty) return "";
    return "${this[0].toUpperCase()}${this.substring(1).toLowerCase()}";
  }
}