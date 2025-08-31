// lib/features/lucky_wheel/presentation/bloc/history/spin_history_state.dart
part of 'spin_history_cubit.dart';

enum SpinHistoryStatus { initial, loading, success, error }

class SpinHistoryState extends Equatable {
  final SpinHistoryStatus status;
  final List<SpinHistoryModel> history;
  final String? errorMessage;

  const SpinHistoryState({
    this.status = SpinHistoryStatus.initial,
    this.history = const [],
    this.errorMessage,
  });

  @override
  List<Object?> get props => [status, history, errorMessage];

  SpinHistoryState copyWith({
    SpinHistoryStatus? status,
    List<SpinHistoryModel>? history,
    String? errorMessage,
  }) {
    return SpinHistoryState(
      status: status ?? this.status,
      history: history ?? this.history,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}