// lib/features/lucky_wheel/presentation/bloc/admin/campaign_form_cubit.dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/data/models/lucky_wheel_campaign_model.dart';
import 'package:piv_app/features/lucky_wheel/domain/repositories/lucky_wheel_repository.dart';

part 'campaign_form_state.dart';

class CampaignFormCubit extends Cubit<CampaignFormState> {
  final LuckyWheelRepository _repository;

  CampaignFormCubit({required LuckyWheelRepository repository})
      : _repository = repository,
        super(CampaignFormState(
        // Khởi tạo một campaign rỗng khi tạo mới
        campaign: LuckyWheelCampaignModel(
          id: '',
          name: '',
          isActive: true,
          startDate: DateTime.now(),
          endDate: DateTime.now().add(const Duration(days: 30)),
          rules: [], // Sẽ thêm rules mặc định sau
          appliesToRole: ['agent_1', 'agent_2'],
          rewards: [],
        ),
      ));

  void init(LuckyWheelCampaignModel? campaign) {
    if (campaign != null) {
      // Chế độ chỉnh sửa
      emit(CampaignFormState(campaign: campaign, isEditing: true));
    } else {
      // Chế độ tạo mới (đã được khởi tạo trong super)
    }
  }

  void updateField({
    String? name,
    bool? isActive,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? appliesToRole,
  }) {
    emit(state.copyWith(
      campaign: state.campaign.copyWith(
        name: name,
        isActive: isActive,
        startDate: startDate,
        endDate: endDate,
        appliesToRole: appliesToRole,
      ),
    ));
  }

  void addReward() {
    final newRewards = List<RewardModel>.from(state.campaign.rewards);
    newRewards.add(const RewardModel(name: '', probability: 10, limit: 100));
    emit(state.copyWith(campaign: state.campaign.copyWith(rewards: newRewards)));
  }

  void updateReward(int index, RewardModel reward) {
    final newRewards = List<RewardModel>.from(state.campaign.rewards);
    newRewards[index] = reward;
    emit(state.copyWith(campaign: state.campaign.copyWith(rewards: newRewards)));
  }

  void removeReward(int index) {
    final newRewards = List<RewardModel>.from(state.campaign.rewards);
    newRewards.removeAt(index);
    emit(state.copyWith(campaign: state.campaign.copyWith(rewards: newRewards)));
  }

  Future<void> saveCampaign() async {
    emit(state.copyWith(status: CampaignFormStatus.loading));
    final result = await _repository.createOrUpdateCampaign(state.campaign);
    result.fold(
          (failure) => emit(state.copyWith(status: CampaignFormStatus.error, errorMessage: failure.message)),
          (_) => emit(state.copyWith(status: CampaignFormStatus.success)),
    );
  }
}

// Thêm copyWith vào LuckyWheelCampaignModel để dễ dàng cập nhật
extension LuckyWheelCampaignModelCopyWith on LuckyWheelCampaignModel {
  LuckyWheelCampaignModel copyWith({
    String? name,
    bool? isActive,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? appliesToRole,
    List<RewardModel>? rewards,
  }) {
    return LuckyWheelCampaignModel(
      id: id,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      rules: rules, // rules hiện tại không cho sửa trên form
      appliesToRole: appliesToRole ?? this.appliesToRole,
      rewards: rewards ?? this.rewards,
    );
  }
}