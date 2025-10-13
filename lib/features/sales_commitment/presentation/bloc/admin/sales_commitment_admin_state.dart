// lib/features/sales_commitment/presentation/bloc/admin/sales_commitment_admin_state.dart

part of 'sales_commitment_admin_cubit.dart';

enum SalesCommitmentAdminStatus { initial, loading, success, error }

class SalesCommitmentAdminState extends Equatable {
  final SalesCommitmentAdminStatus status;
  final List<SalesCommitmentModel> commitments;
  final String? errorMessage;

  const SalesCommitmentAdminState({
    this.status = SalesCommitmentAdminStatus.initial,
    this.commitments = const [],
    this.errorMessage,
  });

  @override
  List<Object?> get props => [status, commitments, errorMessage];

  SalesCommitmentAdminState copyWith({
    SalesCommitmentAdminStatus? status,
    List<SalesCommitmentModel>? commitments,
    String? errorMessage,
  }) {
    return SalesCommitmentAdminState(
      status: status ?? this.status,
      commitments: commitments ?? this.commitments,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}