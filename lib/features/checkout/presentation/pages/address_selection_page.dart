// lib/features/checkout/presentation/pages/address_selection_page.dart

import 'package:flutter/material.dart';
import 'package:piv_app/data/models/address_model.dart';

class AddressSelectionPage extends StatelessWidget {
  final List<AddressModel> addresses;
  final String? selectedAddressId;

  const AddressSelectionPage({
    super.key,
    required this.addresses,
    this.selectedAddressId,
  });

  static PageRoute<AddressModel?> route({
    required List<AddressModel> addresses,
    String? selectedAddressId,
  }) {
    return MaterialPageRoute<AddressModel?>(
      builder: (_) => AddressSelectionPage(
        addresses: addresses,
        selectedAddressId: selectedAddressId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chọn địa chỉ giao hàng'),
      ),
      body: addresses.isEmpty
          ? const Center(
        child: Text('Đại lý này chưa có địa chỉ nào.'),
      )
          : ListView.separated(
        itemCount: addresses.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final address = addresses[index];
          final isSelected = address.id == selectedAddressId;

          return ListTile(
            leading: Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
            ),
            title: Text(address.recipientName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(address.fullAddress),
            onTap: () {
              Navigator.of(context).pop(address);
            },
          );
        },
      ),
    );
  }
}