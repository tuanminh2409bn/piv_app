import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:image_picker/image_picker.dart';
import 'package:piv_app/core/error/failure.dart';
import 'package:dartz/dartz.dart';

class StorageRepository {
  final firebase_storage.FirebaseStorage _storage;
  final ImagePicker _picker;

  StorageRepository({
    firebase_storage.FirebaseStorage? storage,
    ImagePicker? picker,
  })  : _storage = storage ?? firebase_storage.FirebaseStorage.instance,
        _picker = picker ?? ImagePicker();

  /// Chọn ảnh từ thư viện
  Future<Either<Failure, File>> pickImageFromGallery() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // Giảm chất lượng ảnh để tối ưu dung lượng
      );
      if (pickedFile != null) {
        return Right(File(pickedFile.path));
      } else {
        return Left(ServerFailure('Không có ảnh nào được chọn.'));
      }
    } catch (e) {
      return Left(ServerFailure('Lỗi khi chọn ảnh: ${e.toString()}'));
    }
  }

  /// Tải ảnh lên Firebase Storage và trả về URL
  Future<Either<Failure, String>> uploadImage(File imageFile) async {
    try {
      // Tạo một tham chiếu duy nhất trên Storage, ví dụ: /product_images/timestamp.jpg
      final String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = _storage.ref().child('product_images/$fileName');

      // Tải file lên
      final uploadTask = await ref.putFile(imageFile);

      // Lấy URL để có thể truy cập ảnh
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return Right(downloadUrl);
    } catch (e) {
      return Left(ServerFailure('Lỗi khi tải ảnh lên: ${e.toString()}'));
    }
  }
}
