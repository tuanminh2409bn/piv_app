// lib/features/lucky_wheel/presentation/bloc/admin/campaign_form_state.dart
part of 'campaign_form_cubit.dart';

enum CampaignFormStatus { initial, loading, success, error }

class CampaignFormState extends Equatable {
  final CampaignFormStatus status;
  final LuckyWheelCampaignModel campaign;
  final bool isEditing;
  final String? errorMessage;

  const CampaignFormState({
    this.status = CampaignFormStatus.initial,
    required this.campaign,
    this.isEditing = false,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [status, campaign, isEditing, errorMessage];

  CampaignFormState copyWith({
    CampaignFormStatus? status,
    LuckyWheelCampaignModel? campaign,
    String? errorMessage,
  }) {
    return CampaignFormState(
      status: status ?? this.status,
      campaign: campaign ?? this.campaign,
      isEditing: isEditing,
      errorMessage: errorMessage,
    );
  }
}