import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:piv_app/core/error/failure.dart';
import 'package:piv_app/data/models/order_model.dart';
import 'package:piv_app/features/returns/domain/entities/return_request_item.dart';

abstract class ReturnRepository {
  Future<Either<Failure, void>> createReturnRequest({
    required OrderModel order,
    required List<ReturnRequestItem> items,
    required List<File> images,
    required String userNotes,
  });
}