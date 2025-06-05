import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:piv_app/data/models/user_model.dart';
import 'package:piv_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:piv_app/core/error/failure.dart';
import 'dart:async';
import 'dart:developer' as developer; // Để log

class AuthRepositoryImpl implements AuthRepository {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  // StreamController để quản lý stream của UserModel
  // publishSubject vì chúng ta muốn nhiều listener có thể lắng nghe
  final _userStreamController = StreamController<UserModel>.broadcast();


  AuthRepositoryImpl({
    firebase_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance {
    // Lắng nghe sự thay đổi trạng thái người dùng từ Firebase Auth
    // và cập nhật stream của chúng ta
    _firebaseAuth.authStateChanges().listen((firebaseUser) async {
      if (firebaseUser == null) {
        _userStreamController.add(UserModel.empty);
      } else {
        // Lấy thông tin người dùng từ Firestore (nếu có)
        // hoặc tạo UserModel từ FirebaseUser
        final userDoc = _firestore.collection('users').doc(firebaseUser.uid);
        final snapshot = await userDoc.get();

        if (snapshot.exists && snapshot.data() != null) {
          _userStreamController.add(UserModel.fromJson(snapshot.data()!));
        } else {
          // Nếu không có trong Firestore, tạo một UserModel cơ bản
          // và có thể lưu vào Firestore nếu cần (ví dụ: khi đăng ký)
          final newUser = UserModel(
            id: firebaseUser.uid,
            email: firebaseUser.email,
            displayName: firebaseUser.displayName,
            photoUrl: firebaseUser.photoURL,
          );
          _userStreamController.add(newUser);
          // Cân nhắc: có nên tự động tạo document user trong Firestore ở đây không?
          // Thường thì việc này sẽ được thực hiện trong hàm signUp.
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
          // Trường hợp người dùng đã xác thực với Firebase nhưng chưa có record trong Firestore
          // (có thể xảy ra nếu record bị xóa hoặc quá trình đăng ký không hoàn chỉnh)
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
      developer.log('Lỗi getCurrentUser: $e', name: 'AuthRepositoryImpl');
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
        // Cập nhật tên hiển thị nếu có
        if (displayName != null && displayName.isNotEmpty) {
          await firebaseUser.updateDisplayName(displayName);
        }

        // Tạo UserModel
        final newUser = UserModel(
          id: firebaseUser.uid,
          email: firebaseUser.email,
          displayName: displayName ?? firebaseUser.displayName,
          // photoUrl: firebaseUser.photoURL, // Ban đầu có thể chưa có
          // createdAt: DateTime.now(), // Thêm thời gian tạo
        );

        // Lưu thông tin người dùng vào Firestore
        await _firestore.collection('users').doc(firebaseUser.uid).set(newUser.toJson());

        // Kích hoạt việc gửi UserModel mới qua stream
        // _userStreamController.add(newUser); // authStateChanges sẽ tự động làm điều này

        return const Right(unit);
      } else {
        return const Left(AuthFailure('Không thể tạo người dùng, không có thông tin user trả về.'));
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      developer.log('Lỗi SignUp (FirebaseAuth): ${e.code} - ${e.message}', name: 'AuthRepositoryImpl');
      return Left(AuthFailure(_mapFirebaseAuthExceptionToMessage(e), statusCode: e.code.hashCode));
    } catch (e) {
      developer.log('Lỗi SignUp (Unknown): $e', name: 'AuthRepositoryImpl');
      return Left(ServerFailure('Lỗi không xác định trong quá trình đăng ký: ${e.toString()}'));
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
      // authStateChanges sẽ tự động phát ra UserModel mới
      return const Right(unit);
    } on firebase_auth.FirebaseAuthException catch (e) {
      developer.log('Lỗi LogIn (FirebaseAuth): ${e.code} - ${e.message}', name: 'AuthRepositoryImpl');
      return Left(AuthFailure(_mapFirebaseAuthExceptionToMessage(e), statusCode: e.code.hashCode));
    } catch (e) {
      developer.log('Lỗi LogIn (Unknown): $e', name: 'AuthRepositoryImpl');
      return Left(ServerFailure('Lỗi không xác định trong quá trình đăng nhập: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Unit>> logOut() async {
    try {
      await _firebaseAuth.signOut();
      // authStateChanges sẽ tự động phát ra UserModel.empty
      return const Right(unit);
    } on firebase_auth.FirebaseAuthException catch (e) {
      developer.log('Lỗi LogOut (FirebaseAuth): ${e.code} - ${e.message}', name: 'AuthRepositoryImpl');
      return Left(AuthFailure(_mapFirebaseAuthExceptionToMessage(e), statusCode: e.code.hashCode));
    } catch (e) {
      developer.log('Lỗi LogOut (Unknown): $e', name: 'AuthRepositoryImpl');
      return Left(ServerFailure('Lỗi không xác định trong quá trình đăng xuất: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Unit>> sendEmailVerification() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        return const Right(unit);
      } else if (user == null) {
        return const Left(AuthFailure('Người dùng chưa đăng nhập để gửi email xác thực.'));
      } else {
        return const Left(AuthFailure('Email đã được xác thực hoặc không thể gửi.'));
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(AuthFailure(_mapFirebaseAuthExceptionToMessage(e), statusCode: e.code.hashCode));
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định khi gửi email xác thực: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Unit>> sendPasswordResetEmail({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return const Right(unit);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(AuthFailure(_mapFirebaseAuthExceptionToMessage(e), statusCode: e.code.hashCode));
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định khi gửi email đặt lại mật khẩu: ${e.toString()}'));
    }
  }

  // Hàm tiện ích để chuyển đổi FirebaseAuthException thành thông điệp dễ hiểu hơn
  String _mapFirebaseAuthExceptionToMessage(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Mật khẩu quá yếu.';
      case 'email-already-in-use':
        return 'Địa chỉ email này đã được sử dụng.';
      case 'user-not-found':
        return 'Không tìm thấy người dùng với email này.';
      case 'wrong-password':
        return 'Sai mật khẩu.';
      case 'invalid-email':
        return 'Địa chỉ email không hợp lệ.';
      case 'user-disabled':
        return 'Tài khoản người dùng này đã bị vô hiệu hóa.';
      case 'too-many-requests':
        return 'Quá nhiều yêu cầu. Vui lòng thử lại sau.';
      case 'operation-not-allowed':
        return 'Hoạt động này không được phép.';
    // Thêm các case khác nếu cần
      default:
        return e.message ?? 'Đã xảy ra lỗi xác thực không xác định.';
    }
  }
}
