part of 'admin_settings_cubit.dart';

enum AdminSettingsStatus { initial, loading, success, error }

class AdminSettingsState extends Equatable {
  final AdminSettingsStatus status;
  final double commissionRate;

  const AdminSettingsState({
    this.status = AdminSettingsStatus.initial,
    this.commissionRate = 0.0,
  });

  @override
  List<Object> get props => [status, commissionRate];

  AdminSettingsState copyWith({
    AdminSettingsStatus? status,
    double? commissionRate,
  }) {
    return AdminSettingsState(
      status: status ?? this.status,
      commissionRate: commissionRate ?? this.commissionRate,
    );
  }
}