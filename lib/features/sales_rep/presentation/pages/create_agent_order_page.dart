// lib/features/sales_rep/presentation/pages/create_agent_order_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/data/models/address_model.dart';
import 'package:piv_app/data/models/cart_item_model.dart';
import 'package:piv_app/data/models/packaging_option_model.dart';
import 'package:piv_app/data/models/user_model.dart';
import 'package:piv_app/features/checkout/presentation/bloc/checkout_cubit.dart';
import 'package:piv_app/features/checkout/presentation/pages/address_selection_page.dart';
import 'package:piv_app/features/home/data/models/product_model.dart';
import 'package:piv_app/features/products/presentation/pages/search_page.dart';

class CreateAgentOrderPage extends StatelessWidget {
  final UserModel agent;

  const CreateAgentOrderPage({super.key, required this.agent});

  static Route<void> route(UserModel agent) {
    return MaterialPageRoute<void>(
      builder: (_) => BlocProvider(
        create: (context) => sl<CheckoutCubit>()..loadCheckoutDataForAgent(agent),
        child: CreateAgentOrderPage(agent: agent),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CheckoutCubit, CheckoutState>(
      listener: (context, state) {
        if (state.status == CheckoutStatus.orderSuccess) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                content: Text('Đã gửi yêu cầu đặt hàng đến đại lý!'),
                backgroundColor: Colors.green,
              ),
            );
          Navigator.of(context).pop();
        } else if (state.status == CheckoutStatus.error && state.errorMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Colors.red,
              ),
            );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Đặt hàng cho ${agent.displayName ?? 'N/A'}'),
        ),
        body: const _CreateAgentOrderView(),
        bottomNavigationBar: const _CheckoutBottomBar(),
      ),
    );
  }
}

class _CreateAgentOrderView extends StatelessWidget {
  const _CreateAgentOrderView();

  Future<void> _onAddProduct(BuildContext context) async {
    final checkoutCubit = context.read<CheckoutCubit>();
    final agent = checkoutCubit.state.placeOrderForAgent;
    final agentRole = agent?.role;
    final agentId = agent?.id;
    if (agentRole == null) return;

    final result = await Navigator.of(context).push(SearchPage.route(
      isSelectionMode: true,
      targetUserRole: agentRole,
      targetAgentId: agentId,
    ));

    if (result != null && result is ProductModel && context.mounted) {
      final cartItem = await _showPackagingOptionsDialog(context, result, agentRole);
      if (cartItem != null) {
        checkoutCubit.addItemToOnBehalfCart(cartItem);
      }
    }
  }

  Future<CartItemModel?> _showPackagingOptionsDialog(BuildContext context, ProductModel product, String agentRole) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final quantityController = TextEditingController(text: '1');

    return showDialog<CartItemModel>(
      context: context,
      builder: (dialogContext) {
        PackagingOptionModel selectedOption = product.packingOptions.first;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Chọn quy cách cho ${product.name}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<PackagingOptionModel>(
                      value: selectedOption,
                      isExpanded: true,
                      items: product.packingOptions.map((option) {
                        final price = option.getPriceForRole(agentRole);
                        return DropdownMenuItem(
                          value: option,
                            child: Text(
                              '${option.name} - ${currencyFormatter.format(price)}',
                              overflow: TextOverflow.ellipsis,
                            ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => selectedOption = value);
                        }
                      },
                      decoration: const InputDecoration(
                        labelText: 'Quy cách',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Số lượng',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('HỦY'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final quantity = int.tryParse(quantityController.text) ?? 0;
                    if (quantity > 0) {
                      final price = selectedOption.getPriceForRole(agentRole);
                      final cartItem = CartItemModel(
                        productId: product.id,
                        productName: product.name,
                        imageUrl: product.imageUrl,
                        price: price,
                        itemUnitName: selectedOption.unit,
                        quantity: quantity,
                        quantityPerPackage: selectedOption.quantityPerPackage,
                        caseUnitName: selectedOption.name,
                        categoryId: product.categoryId,
                      );
                      Navigator.of(dialogContext).pop(cartItem);
                    }
                  },
                  child: const Text('THÊM'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return BlocBuilder<CheckoutCubit, CheckoutState>(
      builder: (context, state) {
        if (state.status == CheckoutStatus.loading && state.checkoutItems.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            _buildAddressSection(context, state.selectedAddress),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.add_shopping_cart, color: Colors.green),
              title: const Text('Thêm sản phẩm vào đơn hàng', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              onTap: () => _onAddProduct(context),
            ),
            const Divider(height: 1),
            if (state.checkoutItems.isEmpty)
              const Expanded(
                child: Center(
                  child: Text('Đơn hàng chưa có sản phẩm nào.'),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: state.checkoutItems.length,
                  itemBuilder: (context, index) {
                    final item = state.checkoutItems[index];
                    return _buildCartItem(context, item, currencyFormatter);
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildAddressSection(BuildContext context, AddressModel? address) {
    final agent = context.read<CheckoutCubit>().state.placeOrderForAgent;
    return InkWell(
      onTap: () async {
        if (agent != null && agent.addresses.isNotEmpty) {
          final selected = await Navigator.of(context).push(
              AddressSelectionPage.route(
                  addresses: agent.addresses,
                  selectedAddressId: address?.id
              )
          );
          if (selected != null && selected is AddressModel && context.mounted) {
            context.read<CheckoutCubit>().selectAddress(selected);
          }
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.location_on_outlined, color: Colors.blue),
            const SizedBox(width: 16),
            Expanded(
              child: address == null
                  ? const Text('Chưa có địa chỉ giao hàng.', style: TextStyle(color: Colors.red))
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${address.recipientName} | ${address.phoneNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(address.fullAddress, style: TextStyle(color: Colors.grey.shade700)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItem(BuildContext context, CartItemModel item, NumberFormat formatter) {
    return ListTile(
      leading: Image.network(item.imageUrl, width: 50, height: 50, fit: BoxFit.cover),
      title: Text(item.productName),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.caseUnitName, style: TextStyle(color: Colors.grey.shade600)),
          Text(formatter.format(item.price), style: TextStyle(color: Theme.of(context).colorScheme.primary)),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: () {
              context.read<CheckoutCubit>().updateItemQuantityInOnBehalfCart(item.productId, item.caseUnitName, item.quantity - 1);
            },
          ),
          Text(item.quantity.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {
              context.read<CheckoutCubit>().updateItemQuantityInOnBehalfCart(item.productId, item.caseUnitName, item.quantity + 1);
            },
          ),
        ],
      ),
    );
  }
}

class _CheckoutBottomBar extends StatelessWidget {
  const _CheckoutBottomBar();
  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return BlocBuilder<CheckoutCubit, CheckoutState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.all(16.0).copyWith(bottom: 16.0 + MediaQuery.of(context).padding.bottom),
          decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                )
              ]
          ),
          // --- SỬA LỖI OVERFLOW VÀ TỐI ƯU GIAO DIỆN ---
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tổng cộng:', style: TextStyle(fontSize: 16)),
                  Text(
                    currencyFormatter.format(state.finalTotal),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                  ),
                  onPressed: (state.checkoutItems.isEmpty || state.selectedAddress == null || state.status == CheckoutStatus.placingOrder)
                      ? null
                      : () {
                    context.read<CheckoutCubit>().placeOrderOnBehalfOf();
                  },
                  child: state.status == CheckoutStatus.placingOrder
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                      : const Text('GỬI YÊU CẦU'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}