// lib/features/auth/data/repositories/auth_repository_impl.dart

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

  // StreamController vẫn giữ nguyên
  final _userStreamController = StreamController<UserModel>.broadcast();
  // SỬA: Thêm một biến để quản lý việc lắng nghe Firestore
  StreamSubscription<DocumentSnapshot>? _firestoreSubscription;

  AuthRepositoryImpl({
    firebase_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn() {

    // ====================== THAY ĐỔI LOGIC LẮNG NGHE TẠI ĐÂY ======================
    _firebaseAuth.authStateChanges().listen((firebaseUser) {
      // Hủy bỏ việc lắng nghe cũ (nếu có) trước khi tạo một cái mới
      _firestoreSubscription?.cancel();

      if (firebaseUser == null) {
        _userStreamController.add(UserModel.empty);
      } else {
        // Dùng .snapshots() để lắng nghe sự thay đổi theo thời gian thực
        _firestoreSubscription = _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .snapshots()
            .listen((userDoc) {
          if (userDoc.exists && userDoc.data() != null) {
            final user = UserModel.fromSnap(userDoc); // Dùng fromSnap cho DocumentSnapshot
            if (user.status != 'active') {
              developer.log('User ${user.id} status is ${user.status}. Forcing logout.', name: 'AuthRepository');
              logOut();
              // _userStreamController đã được xử lý ở authStateChanges tiếp theo
            } else {
              _userStreamController.add(user);
            }
          } else {
            // User đã xác thực nhưng không có document trong 'users'
            _userStreamController.add(UserModel.empty);
          }
        });
      }
    });
    // ===========================================================================
  }

  @override
  Stream<UserModel> get user => _userStreamController.stream;

  // ... (Tất cả các hàm khác từ getCurrentUser đến hết file giữ nguyên không đổi)
  @override
  Future<Either<Failure, UserModel>> getCurrentUser() async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser != null) {
        final userDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();
        if (userDoc.exists && userDoc.data() != null) {
          return Right(UserModel.fromSnap(userDoc)); // Sửa lại dùng fromSnap
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
          final referrerDoc = await _firestore.collection('users').doc(referralCode).get();
          if (referrerDoc.exists) {
            foundReferrerId = referrerDoc.id;
            final referrerData = UserModel.fromSnap(referrerDoc);
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
        await _firestore.collection('users').doc(firebaseUser.uid).set(newUser.toJson());

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
        return Left(AuthFailure('Đăng nhập thất bại, không có thông tin người dùng.'));
      }

      final userDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();

      if (!userDoc.exists) {
        await _firebaseAuth.signOut();
        return Left(AuthFailure('Tài khoản không tồn tại trong hệ thống. Vui lòng liên hệ quản trị viên.'));
      }

      final user = UserModel.fromSnap(userDoc);

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
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
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
            role: 'agent_2',
            status: 'pending_approval',
            referralPromptPending: true,
          );
          await userDoc.set(newUser.toJson());
        }

        final updatedUserSnapshot = await userDoc.get();
        if (!updatedUserSnapshot.exists) {
          await logOut();
          return Left(AuthFailure('Không tìm thấy thông tin tài khoản sau khi đăng nhập.'));
        }

        final user = UserModel.fromSnap(updatedUserSnapshot);
        if (user.status != 'active') {
          await logOut();
          if (user.status == 'pending_approval') {
            return Left(AuthFailure('Tài khoản của bạn đang chờ phê duyệt.'));
          }
          return Left(AuthFailure('Tài khoản của bạn không hoạt động.'));
        }

        return const Right(unit);
      } else {
        return Left(AuthFailure('Không thể lấy thông tin người dùng.'));
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential' && e.email != null) {
        final methods = await _firebaseAuth.fetchSignInMethodsForEmail(e.email!);
        if (methods.isNotEmpty) {
          String provider = methods.first.replaceAll('.com', '').capitalize();
          return Left(AuthFailure('Email này đã được sử dụng. Vui lòng đăng nhập bằng $provider.'));
        } else {
          return Left(AuthFailure('Tài khoản đã tồn tại với một phương thức đăng nhập khác.'));
        }
      }
      return Left(AuthFailure(e.message ?? 'Lỗi xác thực.'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    if (this.isEmpty) return "";
    return "${this[0].toUpperCase()}${this.substring(1).toLowerCase()}";
  }
}