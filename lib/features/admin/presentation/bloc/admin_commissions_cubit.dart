import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/data/models/commission_model.dart';
import 'package:piv_app/data/models/commission_with_details.dart';
import 'package:piv_app/data/models/user_model.dart';
import 'package:piv_app/features/admin/domain/repositories/admin_repository.dart';
import 'package:piv_app/features/orders/domain/repositories/order_repository.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';

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

  // --- VIẾT LẠI HOÀN TOÀN HÀM NÀY ---
  Future<void> fetchAllCommissions() async {
    emit(state.copyWith(status: AdminCommissionsStatus.loading));

    // 1. Lấy tất cả các bản ghi hoa hồng
    final commissionsResult = await _orderRepository.getAllCommissions();

    await commissionsResult.fold(
          (failure) async => emit(state.copyWith(status: AdminCommissionsStatus.error, errorMessage: failure.message)),
          (commissions) async {
        if (commissions.isEmpty) {
          emit(state.copyWith(status: AdminCommissionsStatus.success, allCommissions: [], filteredCommissions: []));
          return;
        }

        // 2. Từ danh sách hoa hồng, lấy ra các ID của NVKD (loại bỏ trùng lặp)
        final salesRepIds = commissions.map((c) => c.salesRepId).toSet().toList();

        // 3. Lấy thông tin (tên) của các NVKD đó
        final usersResult = await _adminRepository.getUsersByIds(salesRepIds);

        await usersResult.fold(
              (failure) async => emit(state.copyWith(status: AdminCommissionsStatus.error, errorMessage: failure.message)),
              (users) async {
            // 4. Tạo một map để dễ dàng tra cứu tên từ ID
            final salesRepNames = {for (var user in users) user.id: user.displayName ?? 'N/A'};

            // 5. Kết hợp dữ liệu lại
            final commissionsWithDetails = commissions.map((commission) {
              return CommissionWithDetails(
                commission: commission,
                salesRepName: salesRepNames[commission.salesRepId] ?? 'Không rõ',
              );
            }).toList();

            emit(state.copyWith(
              status: AdminCommissionsStatus.success,
              allCommissions: commissionsWithDetails,
            ));
            filterCommissions(state.currentFilter); // Áp dụng bộ lọc
          },
        );
      },
    );
  }

  void filterCommissions(String filter) {
    List<CommissionWithDetails> filtered;
    if (filter == 'all') {
      filtered = state.allCommissions;
    } else {
      filtered = state.allCommissions.where((c) => c.commission.statusString == filter).toList();
    }
    emit(state.copyWith(filteredCommissions: filtered, currentFilter: filter));
  }

  Future<void> markAsPaid(String commissionId) async {
    final authState = _authBloc.state;
    if (authState is! AuthAuthenticated) return;

    // Lấy ID của Admin đang đăng nhập
    final adminId = authState.user.id;

    final result = await _orderRepository.updateCommissionStatus(commissionId, 'paid', adminId);
    if (result.isRight()) {
      fetchAllCommissions();
    } else {
      // Xử lý lỗi nếu cần
    }
  }
}