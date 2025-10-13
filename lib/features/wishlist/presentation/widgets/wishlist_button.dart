// lib/features/wishlist/presentation/widgets/wishlist_button.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:piv_app/features/wishlist/presentation/bloc/wishlist_cubit.dart';

class WishlistButton extends StatelessWidget {
  final String productId;
  final Color? color; // Cho phép tùy chỉnh màu sắc

  const WishlistButton({
    super.key,
    required this.productId,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WishlistCubit, WishlistState>(
      builder: (context, state) {
        final isWishlisted = state.productIds.contains(productId);

        return IconButton(
          icon: Icon(
            isWishlisted ? Icons.favorite : Icons.favorite_border,
            color: isWishlisted ? Colors.red : color,
          ),
          onPressed: () {
            context.read<WishlistCubit>().toggleWishlist(productId);
          },
        );
      },
    );
  }
}