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
        create: (context) =>
            sl<CheckoutCubit>()..loadCheckoutDataForAgent(agent),
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
        } else if (state.status == CheckoutStatus.error &&
            state.errorMessage != null) {
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
      final cartItem =
          await _showPackagingOptionsDialog(context, result, agentRole);
      if (cartItem != null) {
        checkoutCubit.addItemToOnBehalfCart(cartItem);
      }
    }
  }

  Future<CartItemModel?> _showPackagingOptionsDialog(
      BuildContext context, ProductModel product, String agentRole) {
    final currencyFormatter =
        NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final quantityController = TextEditingController(text: '1');

    // --- TỰ ĐỘNG THÊM QUY CÁCH LẺ NẾU CHƯA CÓ ---
    List<PackagingOptionModel> finalOptions = List.from(product.packingOptions);
    bool hasRetail = finalOptions.any((opt) => opt.quantityPerPackage == 1);

    if (!hasRetail && finalOptions.isNotEmpty) {
      final caseOption = finalOptions.first;
      final retailOption = PackagingOptionModel(
        name: 'Lẻ ${caseOption.unit}',
        quantityPerPackage: 1,
        unit: caseOption.unit,
        prices: caseOption.prices,
      );
      finalOptions.insert(0, retailOption);
    }

    return showDialog<CartItemModel>(
      context: context,
      builder: (dialogContext) {
        PackagingOptionModel selectedOption = finalOptions.first;
        return StatefulBuilder(
          builder: (stfContext, stfSetState) {
            final hasZeroPrice =
                finalOptions.any((opt) => opt.getPriceForRole(agentRole) <= 0);
            final currentSelectedPrice =
                selectedOption.getPriceForRole(agentRole);

            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Text('Chọn mua ${product.name}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasZeroPrice) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.shade300),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                color: Colors.orange.shade800, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Một số quy cách chưa có giá. Vui lòng cấu hình giá riêng cho đại lý trước khi đặt mua quy cách này.',
                                style: TextStyle(
                                    color: Colors.orange.shade900,
                                    fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const Text('Quy cách đóng gói:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 12),
                    ...finalOptions.map((option) {
                      final bool isRetail = option.quantityPerPackage == 1;
                      final String typeLabel =
                          isRetail ? 'MUA LẺ' : 'MUA THÙNG';
                      final String subLabel = isRetail
                          ? 'Đơn vị: ${option.unit}'
                          : 'Quy cách: ${option.name} (${option.quantityPerPackage} ${option.unit})';
                      final price = option.getPriceForRole(agentRole);
                      final bool isSelectable = price > 0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selectedOption == option
                                ? Colors.green
                                : Colors.grey.shade300,
                            width: selectedOption == option ? 2 : 1,
                          ),
                          color: selectedOption == option
                              ? Colors.green.withOpacity(0.05)
                              : (isSelectable
                                  ? Colors.transparent
                                  : Colors.grey.shade100),
                        ),
                        child: RadioListTile<PackagingOptionModel>(
                          value: option,
                          groupValue: selectedOption,
                          activeColor: Colors.green,
                          onChanged: isSelectable
                              ? (value) {
                                  if (value != null)
                                    stfSetState(() => selectedOption = value);
                                }
                              : null,
                          title: Text(typeLabel,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: selectedOption == option
                                      ? Colors.green
                                      : Colors.black87,
                                  fontSize: 14)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(subLabel,
                                  style: const TextStyle(fontSize: 12)),
                              Text(
                                  price > 0
                                      ? currencyFormatter.format(price)
                                      : 'Liên hệ',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: price > 0
                                          ? Colors.orange
                                          : Colors.grey,
                                      fontSize: 13)),
                            ],
                          ),
                          isThreeLine: true,
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    const Text('Số lượng đặt:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: quantityController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        prefixIcon: IconButton(
                            onPressed: () {
                              int current =
                                  int.tryParse(quantityController.text) ?? 0;
                              if (current > 1)
                                stfSetState(() => quantityController.text =
                                    (current - 1).toString());
                            },
                            icon: const Icon(Icons.remove_circle_outline)),
                        suffixIcon: IconButton(
                            onPressed: () {
                              int current =
                                  int.tryParse(quantityController.text) ?? 0;
                              stfSetState(() => quantityController.text =
                                  (current + 1).toString());
                            },
                            icon: const Icon(Icons.add_circle_outline)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child:
                      const Text('HỦY', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        currentSelectedPrice > 0 ? Colors.green : Colors.grey,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: currentSelectedPrice > 0
                      ? () {
                          final quantity =
                              int.tryParse(quantityController.text) ?? 0;
                          if (quantity > 0) {
                            final price =
                                selectedOption.getPriceForRole(agentRole);
                            final cartItem = CartItemModel(
                              productId: product.id,
                              productName: product.name,
                              imageUrl: product.imageUrl,
                              price: price,
                              itemUnitName: selectedOption.unit,
                              quantity: quantity,
                              quantityPerPackage:
                                  selectedOption.quantityPerPackage,
                              caseUnitName: selectedOption.name,
                              categoryId: product.categoryId,
                            );
                            Navigator.of(dialogContext).pop(cartItem);
                          }
                        }
                      : null,
                  child: const Text('XÁC NHẬN',
                      style: TextStyle(fontWeight: FontWeight.bold)),
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
    final currencyFormatter =
        NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return BlocBuilder<CheckoutCubit, CheckoutState>(
      builder: (context, state) {
        if (state.status == CheckoutStatus.loading &&
            state.checkoutItems.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            _buildAddressSection(context, state.selectedAddress),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.add_shopping_cart, color: Colors.green),
              title: const Text('Thêm sản phẩm vào đơn hàng',
                  style: TextStyle(
                      color: Colors.green, fontWeight: FontWeight.bold)),
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
          final selected = await Navigator.of(context).push<AddressModel?>(
              AddressSelectionPage.route(
                  addresses: agent.addresses, selectedAddress: address));
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
                  ? const Text('Chưa có địa chỉ giao hàng.',
                      style: TextStyle(color: Colors.red))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            '${address.recipientName} | ${address.phoneNumber}',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(address.fullAddress,
                            style: TextStyle(color: Colors.grey.shade700)),
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

  Widget _buildCartItem(
      BuildContext context, CartItemModel item, NumberFormat formatter) {
    return ListTile(
      leading: Image.network(item.imageUrl,
          width: 50, height: 50, fit: BoxFit.cover),
      title: Text(item.productName),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.caseUnitName,
              style: TextStyle(color: Colors.grey.shade600)),
          Text(formatter.format(item.price),
              style: TextStyle(color: Theme.of(context).colorScheme.primary)),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: () {
              context.read<CheckoutCubit>().updateItemQuantityInOnBehalfCart(
                  item.productId, item.caseUnitName, item.quantity - 1);
            },
          ),
          Text(item.quantity.toString(),
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {
              context.read<CheckoutCubit>().updateItemQuantityInOnBehalfCart(
                  item.productId, item.caseUnitName, item.quantity + 1);
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
    final currencyFormatter =
        NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return BlocBuilder<CheckoutCubit, CheckoutState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.all(16.0)
              .copyWith(bottom: 16.0 + MediaQuery.of(context).padding.bottom),
          decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                )
              ]),
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
                      textStyle: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  onPressed: (state.checkoutItems.isEmpty ||
                          state.selectedAddress == null ||
                          state.status == CheckoutStatus.placingOrder)
                      ? null
                      : () {
                          context.read<CheckoutCubit>().placeOrderOnBehalfOf();
                        },
                  child: state.status == CheckoutStatus.placingOrder
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 3))
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
