import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:piv_app/features/sales_rep/presentation/bloc/sales_rep_cubit.dart';
import 'package:piv_app/data/models/user_model.dart';

class SalesRepHomePage extends StatelessWidget {
  const SalesRepHomePage({super.key});

  static PageRoute<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const SalesRepHomePage());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SalesRepCubit>(),
      child: const SalesRepView(),
    );
  }
}

class SalesRepView extends StatelessWidget {
  const SalesRepView({super.key});

  (Color, String) _getStatusInfo(String status, BuildContext context) {
    switch (status) {
      case 'pending_approval':
        return (Colors.orange.shade700, 'Chờ duyệt');
      case 'active':
        return (Theme.of(context).colorScheme.primary, 'Hoạt động');
      case 'suspended':
        return (Colors.red.shade700, 'Bị khóa');
      default:
        return (Colors.grey.shade700, 'Không xác định');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = (context.read<AuthBloc>().state as AuthAuthenticated).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang Nhân viên Kinh doanh'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: () {
              context.read<AuthBloc>().add(AuthLogoutRequested());
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => context.read<SalesRepCubit>().fetchMyAgents(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chào mừng, ${user.displayName ?? user.email}!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Mã giới thiệu của bạn là: ${user.id}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 24),
              Text(
                'Danh sách đại lý của tôi',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Divider(),
              BlocBuilder<SalesRepCubit, SalesRepState>(
                builder: (context, state) {
                  if (state.status == SalesRepStatus.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state.status == SalesRepStatus.error) {
                    return Center(child: Text(state.errorMessage ?? 'Lỗi tải dữ liệu'));
                  }
                  if (state.myAgents.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40.0),
                        child: Text('Bạn chưa có đại lý nào.'),
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.myAgents.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final agent = state.myAgents[index];
                      final statusInfo = _getStatusInfo(agent.status, context);
                      return ListTile(
                        title: Text(agent.displayName ?? 'Chưa có tên', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(agent.email ?? 'Không có email'),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusInfo.$1.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            statusInfo.$2,
                            style: TextStyle(color: statusInfo.$1, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ),
                        onTap: () {
                          // TODO: Chuyển đến trang chi tiết đại lý
                        },
                      );
                    },
                  );
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}