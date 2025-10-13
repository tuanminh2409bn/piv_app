import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/data/models/order_model.dart';
import 'package:piv_app/features/orders/presentation/pages/order_detail_page.dart';
import 'package:piv_app/features/sales_rep/presentation/bloc/agent_orders_cubit.dart';

class AgentOrderHistoryPage extends StatelessWidget {
  final String agentId;
  final String agentName;

  const AgentOrderHistoryPage({
    super.key,
    required this.agentId,
    required this.agentName,
  });

  static PageRoute<void> route({required String agentId, required String agentName}) {
    return MaterialPageRoute<void>(
      builder: (_) => AgentOrderHistoryPage(agentId: agentId, agentName: agentName),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AgentOrdersCubit>()..fetchOrders(agentId),
      child: Scaffold(
        appBar: AppBar(title: Text('Đơn hàng của $agentName')),
        body: const AgentOrderHistoryView(),
      ),
    );
  }
}

class AgentOrderHistoryView extends StatelessWidget {
  const AgentOrderHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AgentOrdersCubit, AgentOrdersState>(
      builder: (context, state) {
        if (state.status == AgentOrdersStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.orders.isEmpty) {
          return const Center(child: Text('Đại lý này chưa có đơn hàng nào.'));
        }
        return RefreshIndicator(
          onRefresh: () async {
            final agentId = context.read<AgentOrdersCubit>().state.orders.first.userId;
            context.read<AgentOrdersCubit>().fetchOrders(agentId);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: state.orders.length,
            itemBuilder: (context, index) {
              final order = state.orders[index];
              return _buildOrderCard(context, order);
            },
          ),
        );
      },
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderModel order) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: ListTile(
        title: Text('Mã đơn: #${order.id?.substring(0, 8).toUpperCase() ?? 'N/A'}', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Ngày đặt: ${dateFormat.format(order.createdAt!.toDate())}'),
        trailing: Text(currencyFormatter.format(order.total), style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
        onTap: () => Navigator.of(context).push(OrderDetailPage.route(order.id!)),
      ),
    );
  }
}