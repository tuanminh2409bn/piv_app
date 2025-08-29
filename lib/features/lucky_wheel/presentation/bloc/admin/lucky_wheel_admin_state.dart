// lib/features/lucky_wheel/presentation/bloc/admin/lucky_wheel_admin_state.dart
part of 'lucky_wheel_admin_cubit.dart';

enum LuckyWheelAdminStatus { initial, loading, success, error }

class LuckyWheelAdminState extends Equatable {
  final LuckyWheelAdminStatus status;
  final List<LuckyWheelCampaignModel> campaigns;
  final List<SpinHistoryModel> spinHistory;
  final String? errorMessage;

  const LuckyWheelAdminState({
    this.status = LuckyWheelAdminStatus.initial,
    this.campaigns = const [],
    this.spinHistory = const [],
    this.errorMessage,
  });

  @override
  List<Object?> get props => [status, campaigns, spinHistory, errorMessage];

  LuckyWheelAdminState copyWith({
    LuckyWheelAdminStatus? status,
    List<LuckyWheelCampaignModel>? campaigns,
    List<SpinHistoryModel>? spinHistory,
    String? errorMessage,
  }) {
    return LuckyWheelAdminState(
      status: status ?? this.status,
      campaigns: campaigns ?? this.campaigns,
      spinHistory: spinHistory ?? this.spinHistory,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}