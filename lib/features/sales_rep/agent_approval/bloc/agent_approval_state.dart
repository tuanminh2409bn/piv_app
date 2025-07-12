part of 'agent_approval_cubit.dart';

abstract class AgentApprovalState extends Equatable {
  const AgentApprovalState();
  @override
  List<Object> get props => [];
}

class AgentApprovalInitial extends AgentApprovalState {}
class AgentApprovalLoading extends AgentApprovalState {}

class AgentApprovalLoaded extends AgentApprovalState {
  // Sửa lại kiểu dữ liệu thành UserModel
  final List<UserModel> users;
  const AgentApprovalLoaded(this.users);
  @override
  List<Object> get props => [users];
}

class AgentApprovalFailure extends AgentApprovalState {
  final String message;
  const AgentApprovalFailure(this.message);
  @override
  List<Object> get props => [message];
}