// lib/features/lucky_wheel/presentation/bloc/lucky_wheel_state.dart

part of 'lucky_wheel_cubit.dart';

enum LuckyWheelStatus { initial, loading, success, error, spinning, won }

class LuckyWheelState extends Equatable {
  final LuckyWheelStatus status;
  final LuckyWheelCampaignModel? activeCampaign;
  final RewardModel? winningReward;
  final String? errorMessage;
  final String? successMessage;

  const LuckyWheelState({
    this.status = LuckyWheelStatus.initial,
    this.activeCampaign,
    this.winningReward,
    this.errorMessage,
    this.successMessage,
  });

  @override
  List<Object?> get props => [status, activeCampaign, winningReward, errorMessage, successMessage];

  LuckyWheelState copyWith({
    LuckyWheelStatus? status,
    LuckyWheelCampaignModel? activeCampaign,
    RewardModel? winningReward,
    String? errorMessage,
    String? successMessage,
    bool forceCampaignToNull = false,
  }) {
    return LuckyWheelState(
      status: status ?? this.status,
      activeCampaign: forceCampaignToNull ? null : activeCampaign ?? this.activeCampaign,
      winningReward: winningReward, // winningReward is transient, doesn't need to be preserved
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}