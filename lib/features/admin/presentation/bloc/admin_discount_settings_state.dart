import 'package:equatable/equatable.dart';
import 'package:piv_app/features/admin/data/models/discount_policy_model.dart';

abstract class AdminDiscountSettingsState extends Equatable {
  const AdminDiscountSettingsState();

  @override
  List<Object?> get props => [];
}

class AdminDiscountSettingsInitial extends AdminDiscountSettingsState {}

class AdminDiscountSettingsLoading extends AdminDiscountSettingsState {}

class AdminDiscountSettingsLoaded extends AdminDiscountSettingsState {
  final DiscountPolicyModel policy;

  const AdminDiscountSettingsLoaded(this.policy);

  @override
  List<Object?> get props => [policy];
}

class AdminDiscountSettingsError extends AdminDiscountSettingsState {
  final String message;

  const AdminDiscountSettingsError(this.message);

  @override
  List<Object?> get props => [message];
}
