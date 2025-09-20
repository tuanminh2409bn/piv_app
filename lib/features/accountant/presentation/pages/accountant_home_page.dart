// lib/features/accountant/presentation/pages/accountant_home_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/features/accountant/presentation/bloc/accountant_agents_cubit.dart';
import 'package:piv_app/features/admin/presentation/pages/admin_orders_page.dart';
import 'package:piv_app/features/admin/presentation/pages/admin_users_page.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:piv_app/features/sales_rep/presentation/pages/create_agent_order_page.dart';
import 'package:piv_app/features/sales_commitment/presentation/bloc/admin/sales_commitment_admin_cubit.dart';
import 'package:piv_app/features/sales_commitment/presentation/pages/admin_commitments_page.dart';
import 'package:piv_app/features/admin/presentation/pages/quick_order_agent_selection_page.dart';


class AccountantHomePage extends StatelessWidget {
  const AccountantHomePage({super.key});

  static PageRoute<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const AccountantHomePage());
  }

  @override
  Widget build(BuildContext context) {
    final user = (context.read<AuthBloc>().state as AuthAuthenticated).user;

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Kế toán: ${user.displayName ?? ''}'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Đăng xuất',
              onPressed: () => context.read<AuthBloc>().add(AuthLogoutRequested()),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(icon: Icon(Icons.people_outline), text: 'Người dùng'),
              Tab(icon: Icon(Icons.receipt_long_outlined), text: 'Đơn hàng'),
              Tab(icon: Icon(Icons.workspace_premium_outlined), text: 'Cam kết'),
              Tab(icon: Icon(Icons.add_shopping_cart), text: 'Đặt hàng hộ'),
              Tab(icon: Icon(Icons.playlist_add_check_rounded), text: 'Cài đặt Đặt nhanh'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            AdminUsersPage(),
            AdminOrdersPage(),
            CommitmentManagementPageWrapper(),
            AllAgentsViewForAccountant(),
            QuickOrderAgentSelectionPage(),
          ],
        ),
      ),
    );
  }
}

class CommitmentManagementPageWrapper extends StatelessWidget {
  const CommitmentManagementPageWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<SalesCommitmentAdminCubit>()..watchAllCommitments(),
      child: const AdminCommitmentsPage(),
    );
  }
}

class AllAgentsViewForAccountant extends StatelessWidget {
  const AllAgentsViewForAccountant({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<AccountantAgentsCubit>()..fetchAllAgents(),
      child: BlocBuilder<AccountantAgentsCubit, AccountantAgentsState>(
        builder: (context, state) {
          if (state.status == AccountantAgentsStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.agents.isEmpty) {
            return const Center(child: Text('Không có đại lý nào đang hoạt động.'));
          }
          return RefreshIndicator(
            onRefresh: () async => context.read<AccountantAgentsCubit>().fetchAllAgents(),
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: state.agents.length,
              itemBuilder: (context, index) {
                final agent = state.agents[index];
                return Card(
                  child: ListTile(
                    title: Text(agent.displayName ?? 'Chưa có tên', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(agent.email ?? 'Không có email'),
                    trailing: const Icon(Icons.shopping_cart_checkout),
                    onTap: () {
                      Navigator.of(context).push(CreateAgentOrderPage.route(agent));
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}