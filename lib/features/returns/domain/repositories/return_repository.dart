// lib/features/returns/domain/repositories/return_repository.dart

import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:piv_app/core/error/failure.dart';
import 'package:piv_app/data/models/order_model.dart';
import 'package:piv_app/features/returns/data/models/return_request_model.dart';
import 'package:piv_app/features/returns/domain/entities/return_request_item.dart';

abstract class ReturnRepository {
  Future<Either<Failure, void>> createReturnRequest({
    required OrderModel order,
    required List<ReturnRequestItem> items,
    required List<File> images,
    required String userNotes,
  });

  // --- THAY ĐỔI: Thêm các hàm mới ---
  Stream<List<ReturnRequestModel>> watchAllReturnRequests();

  Stream<ReturnRequestModel> watchReturnRequestById(String requestId);

  Future<Either<Failure, void>> updateReturnRequestStatus({
    required String requestId,
    required String newStatus,
    String? adminNotes,
    String? rejectionReason,
  });
// --- KẾT THÚC THAY ĐỔI ---
}