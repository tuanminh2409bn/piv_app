// lib/features/returns/presentation/pages/admin_return_requests_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/features/returns/data/models/return_request_model.dart';
import 'package:piv_app/features/returns/presentation/bloc/admin_returns_cubit.dart';
import 'package:piv_app/features/returns/presentation/pages/admin_return_request_detail_page.dart';


class AdminReturnRequestsPage extends StatelessWidget {
  const AdminReturnRequestsPage({super.key});

  static PageRoute<void> route() {
    return MaterialPageRoute<void>(
      builder: (_) => BlocProvider(
        create: (_) => sl<AdminReturnsCubit>()..watchAllRequests(),
        child: const AdminReturnRequestsPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quản lý Đổi/Trả'),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'CHỜ DUYỆT'),
              Tab(text: 'ĐÃ DUYỆT'),
              Tab(text: 'HOÀN THÀNH'),
              Tab(text: 'ĐÃ TỪ CHỐI'),
            ],
          ),
        ),
        body: BlocBuilder<AdminReturnsCubit, AdminReturnsState>(
          builder: (context, state) {
            if (state.status == AdminReturnsStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.status == AdminReturnsStatus.error) {
              return Center(child: Text(state.errorMessage ?? 'Đã có lỗi xảy ra'));
            }

            final pending = state.allRequests.where((r) => r.status == 'pending_approval').toList();
            final approved = state.allRequests.where((r) => r.status == 'approved').toList();
            final completed = state.allRequests.where((r) => r.status == 'completed').toList();
            final rejected = state.allRequests.where((r) => r.status == 'rejected').toList();

            return TabBarView(
              children: [
                _RequestListView(requests: pending, status: 'Chờ duyệt'),
                _RequestListView(requests: approved, status: 'Đã duyệt'),
                _RequestListView(requests: completed, status: 'Hoàn thành'),
                _RequestListView(requests: rejected, status: 'Đã từ chối'),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RequestListView extends StatelessWidget {
  final List<ReturnRequestModel> requests;
  final String status;
  const _RequestListView({required this.requests, required this.status});

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return Center(child: Text('Không có yêu cầu nào ở trạng thái "$status"'));
    }
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    // --- THAY ĐỔI: Lấy cubit từ context ---
    final cubit = context.read<AdminReturnsCubit>();
    return ListView.builder(
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            title: Text('ĐH: #${request.orderId.substring(0,8).toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Người yêu cầu: ${request.userDisplayName}\nNgày tạo: ${dateFormat.format(request.createdAt.toDate())}'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // --- THAY ĐỔI: Truyền cubit vào route ---
              Navigator.of(context).push(AdminReturnRequestDetailPage.route(
                request: request,
                cubit: cubit,
              ));
            },
          ),
        );
      },
    );
  }
}