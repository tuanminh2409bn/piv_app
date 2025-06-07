import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:piv_app/features/cart/presentation/bloc/cart_cubit.dart';

class CartIconWithBadge extends StatelessWidget {
  // Callback để xử lý khi người dùng nhấn vào icon
  final VoidCallback onPressed;
  // Màu sắc cho icon, để có thể tùy chỉnh theo AppBar
  final Color? iconColor;

  const CartIconWithBadge({
    super.key,
    required this.onPressed,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    // Sử dụng BlocBuilder để lắng nghe CartCubit và rebuild khi có thay đổi
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, state) {
        // Lấy tổng số lượng sản phẩm từ state
        final itemCount = state.totalItems;

        // Sử dụng Stack để đặt huy hiệu (badge) lên trên IconButton
        return Stack(
          alignment: Alignment.center,
          children: [
            // Icon giỏ hàng
            IconButton(
              icon: const Icon(Icons.shopping_cart_outlined),
              color: iconColor, // Sử dụng màu được truyền vào
              tooltip: 'Giỏ hàng',
              onPressed: onPressed,
            ),
            // Chỉ hiển thị huy hiệu nếu có sản phẩm trong giỏ
            if (itemCount > 0)
              Positioned(
                top: 6, // Điều chỉnh vị trí của huy hiệu theo chiều dọc
                right: 6, // Điều chỉnh vị trí của huy hiệu theo chiều ngang
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red, // Màu nền của huy hiệu
                    borderRadius: BorderRadius.circular(10), // Bo tròn huy hiệu
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    itemCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
