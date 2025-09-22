// lib/features/lucky_wheel/presentation/bloc/lucky_wheel_cubit.dart

import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/data/models/lucky_wheel_campaign_model.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:piv_app/features/lucky_wheel/domain/repositories/lucky_wheel_repository.dart';

part 'lucky_wheel_state.dart';

class LuckyWheelCubit extends Cubit<LuckyWheelState> {
  final LuckyWheelRepository _repository;
  final AuthBloc _authBloc;
  StreamSubscription? _authSubscription;
  StreamSubscription? _campaignSubscription;
  String _currentUserRole = '';
  bool _dailySpinGranted = false; // --- THAY ĐỔI: Thêm cờ để chỉ gọi 1 lần ---

  LuckyWheelCubit({
    required LuckyWheelRepository repository,
    required AuthBloc authBloc,
  })  : _repository = repository,
        _authBloc = authBloc,
        super(const LuckyWheelState()) {
    _authSubscription = _authBloc.stream.listen((authState) {
      if (authState is AuthAuthenticated) {
        _setUserRoleAndListen(authState.user.role);
      } else {
        _setUserRoleAndListen('');
      }
    });

    final initialState = _authBloc.state;
    if (initialState is AuthAuthenticated) {
      _setUserRoleAndListen(initialState.user.role);
    }
  }

  void _setUserRoleAndListen(String role) {
    if (_currentUserRole == role) return;

    _currentUserRole = role;
    _dailySpinGranted = false; // Reset cờ khi user thay đổi
    _campaignSubscription?.cancel();

    if (role.isEmpty) {
      emit(state.copyWith(status: LuckyWheelStatus.initial, forceCampaignToNull: true));
      return;
    }

    emit(state.copyWith(status: LuckyWheelStatus.loading));

    _campaignSubscription = _repository.watchActiveCampaign(role).listen(
          (campaign) {
        // --- THAY ĐỔI: Chỉ gọi grantDailySpin một lần sau khi có campaign ---
        if (!_dailySpinGranted) {
          _dailySpinGranted = true;
          grantDailySpin();
        }
        // -----------------------------------------------------------------
        emit(state.copyWith(
          status: LuckyWheelStatus.success,
          activeCampaign: campaign,
          forceCampaignToNull: campaign == null,
        ));
      },
      onError: (error) {
        emit(state.copyWith(status: LuckyWheelStatus.error, errorMessage: 'Lỗi tải chương trình vòng quay.'));
      },
    );
  }

  Future<void> grantDailySpin() async {
    final result = await _repository.grantDailyLoginSpin();
    result.fold(
          (failure) {
        // Có thể emit một thông báo nhẹ nhàng nếu muốn, ví dụ: 'Hôm nay bạn đã nhận lượt rồi'
        // Hoặc không làm gì cả để tránh làm phiền người dùng.
        emit(state.copyWith(status: LuckyWheelStatus.success, successMessage: failure.message));
      },
          (message) {
        // Hiển thị thông báo nhận lượt quay thành công
        emit(state.copyWith(status: LuckyWheelStatus.success, successMessage: message));
      },
    );
  }

  Future<void> spinWheel() async {
    if (state.status == LuckyWheelStatus.spinning) return;
    emit(state.copyWith(status: LuckyWheelStatus.spinning));

    final result = await _repository.spinTheWheel();

    result.fold(
          (failure) => emit(state.copyWith(
        status: LuckyWheelStatus.error,
        errorMessage: failure.message,
      )),
          (reward) => emit(state.copyWith(
        status: LuckyWheelStatus.won,
        winningReward: reward,
      )),
    );
  }

  void acknowledgeReward() {
    emit(state.copyWith(status: LuckyWheelStatus.success, winningReward: null, successMessage: null));
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    _campaignSubscription?.cancel();
    return super.close();
  }
}