// lib/features/admin/presentation/pages/quick_order_agent_selection_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/features/admin/domain/repositories/admin_repository.dart';
import 'package:piv_app/features/admin/presentation/bloc/agent_selection_cubit.dart';
import 'package:piv_app/features/admin/presentation/pages/manage_quick_order_list_page.dart';

class QuickOrderAgentSelectionPage extends StatelessWidget {
  const QuickOrderAgentSelectionPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(
      builder: (_) => BlocProvider(
        create: (context) => AgentSelectionCubit(
          adminRepository: sl<AdminRepository>(),
        )..fetchAllAgents(),
        child: const QuickOrderAgentSelectionPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chọn Đại lý'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Tìm kiếm đại lý...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                context.read<AgentSelectionCubit>().searchAgents(value);
              },
            ),
          ),
          Expanded(
            child: BlocBuilder<AgentSelectionCubit, AgentSelectionState>(
              builder: (context, state) {
                if (state.status == AgentSelectionStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.filteredAgents.isEmpty) {
                  return const Center(child: Text('Không tìm thấy đại lý.'));
                }
                return ListView.builder(
                  itemCount: state.filteredAgents.length,
                  itemBuilder: (context, index) {
                    final agent = state.filteredAgents[index];
                    return ListTile(
                      title: Text(agent.displayName ?? 'N/A'),
                      subtitle: Text(agent.email ?? 'N/A'),
                      onTap: () {
                        Navigator.of(context).push(ManageQuickOrderListPage.route(agent));
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}