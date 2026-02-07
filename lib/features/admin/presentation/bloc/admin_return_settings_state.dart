import 'package:equatable/equatable.dart';
import 'package:piv_app/data/models/return_policy_config_model.dart';

abstract class AdminReturnSettingsState extends Equatable {
  const AdminReturnSettingsState();

  @override
  List<Object?> get props => [];
}

class AdminReturnSettingsLoading extends AdminReturnSettingsState {}

class AdminReturnSettingsLoaded extends AdminReturnSettingsState {
  final ReturnPolicyConfigModel policy;

  const AdminReturnSettingsLoaded(this.policy);

  @override
  List<Object?> get props => [policy];
}

class AdminReturnSettingsError extends AdminReturnSettingsState {
  final String message;

  const AdminReturnSettingsError(this.message);

  @override
  List<Object?> get props => [message];
}
