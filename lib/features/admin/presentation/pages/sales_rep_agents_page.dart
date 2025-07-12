import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/data/models/user_model.dart';
import 'package:piv_app/features/admin/domain/repositories/admin_repository.dart';

class SalesRepAgentsPage extends StatelessWidget {
  final UserModel salesRep;

  const SalesRepAgentsPage({super.key, required this.salesRep});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Đại lý của ${salesRep.displayName ?? ''}'),
      ),
      // Dùng FutureBuilder để tải danh sách đại lý một lần khi mở trang
      body: FutureBuilder<List<UserModel>>(
        future: sl<AdminRepository>().getAgentsBySalesRepId(salesRep.id).then(
              (result) => result.fold((l) => [], (r) => r),
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('NVKD này chưa có đại lý nào.'));
          }

          final agents = snapshot.data!;
          return ListView.builder(
            itemCount: agents.length,
            itemBuilder: (context, index) {
              final agent = agents[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(child: Text(agent.displayName?[0] ?? 'Đ')),
                  title: Text(agent.displayName ?? 'Chưa có tên'),
                  subtitle: Text('Cấp: ${agent.role == 'agent_1' ? '1' : '2'} - Trạng thái: ${agent.status}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}