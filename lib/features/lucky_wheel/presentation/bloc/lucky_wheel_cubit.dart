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

  LuckyWheelCubit({
    required LuckyWheelRepository repository,
    required AuthBloc authBloc,
  })  : _repository = repository,
        _authBloc = authBloc,
        super(const LuckyWheelState()) {
    _authSubscription = _authBloc.stream.listen((authState) {
      if (authState is AuthAuthenticated) {
        _setUserRoleAndListen(authState.user.role);
        // Tự động gọi để nhận lượt quay hàng ngày khi user đăng nhập
        grantDailySpin();
      } else {
        _setUserRoleAndListen('');
      }
    });

    final initialState = _authBloc.state;
    if (initialState is AuthAuthenticated) {
      _setUserRoleAndListen(initialState.user.role);
      // Tự động gọi để nhận lượt quay hàng ngày khi cubit được tạo
      grantDailySpin();
    }
  }

  void _setUserRoleAndListen(String role) {
    if (_currentUserRole == role || role.isEmpty) return;
    _currentUserRole = role;
    _campaignSubscription?.cancel();

    emit(state.copyWith(status: LuckyWheelStatus.loading));
    _campaignSubscription = _repository.watchActiveCampaign(role).listen(
          (campaign) {
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
        // Không cần hiển thị lỗi này, vì nó thường xuyên xảy ra khi user đã nhận rồi
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

  // Hàm để reset lại trạng thái sau khi hiển thị popup trúng thưởng
  void acknowledgeReward() {
    emit(state.copyWith(status: LuckyWheelStatus.success, winningReward: null));
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    _campaignSubscription?.cancel();
    return super.close();
  }
}