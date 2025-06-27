import 'package:flutter/material.dart';
import 'package:piv_app/data/models/address_model.dart';

class AddressSelectionPage extends StatelessWidget {
  // --- SỬA LỖI 1: THÊM CONSTRUCTOR ĐỂ NHẬN DANH SÁCH ĐỊA CHỈ ---
  final List<AddressModel> addresses;

  const AddressSelectionPage({super.key, required this.addresses});
  // -----------------------------------------------------------

  // --- SỬA LỖI 2: ĐỊNH NGHĨA ROUTE ĐỂ NHẬN THAM SỐ VÀ TRẢ VỀ GIÁ TRỊ ---
  static PageRoute<AddressModel?> route({required List<AddressModel> addresses}) {
    return MaterialPageRoute<AddressModel?>(
      builder: (_) => AddressSelectionPage(addresses: addresses),
    );
  }
  // --------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chọn địa chỉ giao hàng'),
      ),
      body: addresses.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Bạn chưa có địa chỉ nào.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // TODO: Điều hướng đến trang thêm địa chỉ mới
              },
              child: const Text('Thêm địa chỉ mới'),
            ),
          ],
        ),
      )
          : ListView.separated(
        itemCount: addresses.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final address = addresses[index];
          return ListTile(
            leading: Icon(
              address.isDefault ? Icons.star : Icons.location_on_outlined,
              color: address.isDefault ? Colors.amber : Colors.grey,
            ),
            title: Text(address.recipientName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(address.fullAddress),
            // --- KHI NHẤN VÀO, TRẢ VỀ ĐỊA CHỈ ĐÃ CHỌN ---
            onTap: () {
              Navigator.of(context).pop(address);
            },
          );
        },
      ),
    );
  }
}