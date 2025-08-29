// lib/features/lucky_wheel/presentation/bloc/admin/lucky_wheel_admin_cubit.dart
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/data/models/lucky_wheel_campaign_model.dart';
import 'package:piv_app/data/models/spin_history_model.dart';
import 'package:piv_app/features/lucky_wheel/domain/repositories/lucky_wheel_repository.dart';

part 'lucky_wheel_admin_state.dart';

class LuckyWheelAdminCubit extends Cubit<LuckyWheelAdminState> {
  final LuckyWheelRepository _repository;
  StreamSubscription? _campaignsSubscription;
  StreamSubscription? _historySubscription;

  LuckyWheelAdminCubit({required LuckyWheelRepository repository})
      : _repository = repository,
        super(const LuckyWheelAdminState());

  void watchCampaignsAndHistory() {
    _campaignsSubscription?.cancel();
    _historySubscription?.cancel();
    emit(state.copyWith(status: LuckyWheelAdminStatus.loading));

    _campaignsSubscription = _repository.watchAllCampaigns().listen((campaigns) {
      emit(state.copyWith(status: LuckyWheelAdminStatus.success, campaigns: campaigns));
    }, onError: (e) {
      emit(state.copyWith(status: LuckyWheelAdminStatus.error, errorMessage: 'Lỗi tải chiến dịch.'));
    });

    _historySubscription = _repository.watchAllSpinHistory().listen((history) {
      emit(state.copyWith(status: LuckyWheelAdminStatus.success, spinHistory: history));
    }, onError: (e) {
      emit(state.copyWith(status: LuckyWheelAdminStatus.error, errorMessage: 'Lỗi tải lịch sử.'));
    });
  }

  // Thêm các hàm để CUD (Create, Update, Delete) campaigns sau này

  @override
  Future<void> close() {
    _campaignsSubscription?.cancel();
    _historySubscription?.cancel();
    return super.close();
  }
}