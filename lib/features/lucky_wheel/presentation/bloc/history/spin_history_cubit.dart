// lib/features/lucky_wheel/presentation/bloc/history/spin_history_cubit.dart
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/data/models/spin_history_model.dart';
import 'package:piv_app/features/lucky_wheel/domain/repositories/lucky_wheel_repository.dart';

part 'spin_history_state.dart';

class SpinHistoryCubit extends Cubit<SpinHistoryState> {
  final LuckyWheelRepository _repository;
  StreamSubscription? _historySubscription;

  SpinHistoryCubit({required LuckyWheelRepository repository})
      : _repository = repository,
        super(const SpinHistoryState());

  // Nếu isMyHistory là true, chỉ fetch lịch sử của user hiện tại.
  // Nếu là false, fetch tất cả (cho Admin).
  void watchHistory(bool isMyHistory) {
    _historySubscription?.cancel();
    emit(state.copyWith(status: SpinHistoryStatus.loading));

    final historyStream = isMyHistory
        ? _repository.watchMySpinHistory()
        : _repository.watchAllSpinHistory();

    _historySubscription = historyStream.listen(
          (history) {
        emit(state.copyWith(
          status: SpinHistoryStatus.success,
          history: history,
        ));
      },
      onError: (e) {
        emit(state.copyWith(
          status: SpinHistoryStatus.error,
          errorMessage: 'Không thể tải lịch sử.',
        ));
      },
    );
  }

  @override
  Future<void> close() {
    _historySubscription?.cancel();
    return super.close();
  }
}