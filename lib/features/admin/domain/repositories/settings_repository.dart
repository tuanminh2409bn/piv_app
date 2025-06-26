import 'package:dartz/dartz.dart';
import 'package:piv_app/core/error/failure.dart';

abstract class SettingsRepository {
  Future<Either<Failure, double>> getCommissionRate();
  Future<Either<Failure, Unit>> updateCommissionRate(double newRate);
}