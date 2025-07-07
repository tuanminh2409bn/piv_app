import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:dartz/dartz.dart'; // <<< THÊM IMPORT
import 'package:piv_app/core/error/failure.dart'; // <<< THÊM IMPORT
import 'package:piv_app/data/models/commission_model.dart'; // <<< THÊM IMPORT
import 'package:piv_app/data/models/commission_with_details.dart';
import 'package:piv_app/data/models/user_model.dart';
import 'package:piv_app/features/admin/domain/repositories/admin_repository.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:piv_app/features/orders/domain/repositories/order_repository.dart';

part 'admin_commissions_state.dart';

class AdminCommissionsCubit extends Cubit<AdminCommissionsState> {
  final OrderRepository _orderRepository;
  final AdminRepository _adminRepository;
  final AuthBloc _authBloc;

  AdminCommissionsCubit({
    required OrderRepository orderRepository,
    required AdminRepository adminRepository,
    required AuthBloc authBloc,
  })  : _orderRepository = orderRepository,
        _adminRepository = adminRepository,
        _authBloc = authBloc,
        super(const AdminCommissionsState());

  Future<void> fetchAllData() async {
    emit(state.copyWith(status: AdminCommissionsStatus.loading));

    final results = await Future.wait([
      _orderRepository.getAllCommissions(
        startDate: state.startDate,
        endDate: state.endDate,
      ),
      _adminRepository.getAllUsers(),
    ]);

    final commissionsResult = results[0] as Either<Failure, List<CommissionModel>>;
    final usersResult = results[1] as Either<Failure, List<UserModel>>;

    commissionsResult.fold(
          (failure) => emit(state.copyWith(status: AdminCommissionsStatus.error, errorMessage: failure.message)),
          (commissions) {
        usersResult.fold(
              (failure) => emit(state.copyWith(status: AdminCommissionsStatus.error, errorMessage: failure.message)),
              (users) {
            final salesReps = users.where((UserModel user) => user.isSalesRep).toList();

            // Tạo một map để tra cứu tên người dùng nhanh hơn
            final userMap = {for (var user in users) user.id: user.displayName ?? 'N/A'};

            final commissionsWithDetails = commissions.map((commission) {
              return CommissionWithDetails(
                commission: commission,
                salesRepName: userMap[commission.salesRepId] ?? 'Không rõ',
                agentName: userMap[commission.agentId] ?? 'Không rõ', // <<< SỬA LẠI
              );
            }).toList();

            emit(state.copyWith(
              status: AdminCommissionsStatus.success,
              allCommissions: commissionsWithDetails,
              salesReps: salesReps,
            ));
            _applyFilters();
          },
        );
      },
    );
  }

  void _applyFilters() {
    List<CommissionWithDetails> listToProcess = List.from(state.allCommissions);

    if (state.currentFilter != 'all') {
      listToProcess = listToProcess.where((c) => c.commission.statusString == state.currentFilter).toList();
    }

    if (state.selectedSalesRepId != null) {
      listToProcess = listToProcess.where((c) => c.commission.salesRepId == state.selectedSalesRepId).toList();
    }

    emit(state.copyWith(filteredCommissions: listToProcess, status: AdminCommissionsStatus.success));
  }

  void filterByStatus(String filter) {
    emit(state.copyWith(currentFilter: filter));
    _applyFilters();
  }

  void filterBySalesRep(String? salesRepId) {
    emit(state.copyWith(selectedSalesRepId: salesRepId, forceSalesRepToNull: salesRepId == null));
    _applyFilters();
  }

  Future<void> setDateRange(DateTimeRange? dateRange) async {
    emit(state.copyWith(
      forceStartDateToNull: dateRange == null,
      startDate: dateRange?.start,
      forceEndDateToNull: dateRange == null,
      endDate: dateRange?.end,
    ));
    await fetchAllData();
  }

  Future<void> markAsPaid(String commissionId) async {
    final authState = _authBloc.state;
    if (authState is! AuthAuthenticated) return;
    final adminId = authState.user.id;

    final result = await _orderRepository.updateCommissionStatus(commissionId, 'paid', adminId);
    if (result.isRight()) {
      fetchAllData();
    }
  }
}