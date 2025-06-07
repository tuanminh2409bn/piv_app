import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:piv_app/features/checkout/presentation/bloc/checkout_cubit.dart';
import 'package:piv_app/data/models/address_model.dart';

class AddressSelectionPage extends StatelessWidget {
  const AddressSelectionPage({super.key});

  static PageRoute<void> route() {
    return MaterialPageRoute<void>(
      builder: (_) => const AddressSelectionPage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Không cần BlocProvider ở đây vì CheckoutCubit đã được cung cấp ở trang trước đó (CheckoutPage)
    // và chúng ta sẽ sử dụng context từ route đó.
    return const AddressSelectionView();
  }
}

class AddressSelectionView extends StatelessWidget {
  const AddressSelectionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chọn địa chỉ giao hàng'),
      ),
      body: BlocBuilder<CheckoutCubit, CheckoutState>(
        builder: (context, state) {
          if (state.addresses.isEmpty) {
            return const Center(
              child: Text('Bạn chưa có địa chỉ nào.\nVui lòng quay lại trang hồ sơ để thêm.'),
            );
          }

          return ListView.builder(
            itemCount: state.addresses.length,
            itemBuilder: (context, index) {
              final address = state.addresses[index];
              final isSelected = state.selectedAddress?.id == address.id;

              return RadioListTile<String>(
                value: address.id,
                groupValue: state.selectedAddress?.id,
                onChanged: (String? value) {
                  // Gọi cubit để cập nhật địa chỉ đã chọn
                  context.read<CheckoutCubit>().selectAddress(address);
                  // Quay lại trang thanh toán sau khi đã chọn
                  Navigator.of(context).pop();
                },
                title: Text(
                  address.recipientName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${address.phoneNumber}\n${address.fullAddress}',
                ),
                isThreeLine: true,
                secondary: isSelected
                    ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
                    : null,
                activeColor: Theme.of(context).colorScheme.primary,
              );
            },
          );
        },
      ),
      // TODO: Thêm nút "Thêm địa chỉ mới" ở đây để điều hướng sang form
    );
  }
}
