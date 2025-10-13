// lib/features/cart/presentation/bloc/cart_suggestions_cubit.dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/features/home/data/models/product_model.dart';
import 'package:piv_app/features/home/domain/repositories/home_repository.dart';

part 'cart_suggestions_state.dart';

class CartSuggestionsCubit extends Cubit<CartSuggestionsState> {
  final HomeRepository _homeRepository;

  CartSuggestionsCubit({required HomeRepository homeRepository})
      : _homeRepository = homeRepository,
        super(const CartSuggestionsState());

  Future<void> fetchSuggestions(String categoryId, {String? currentProductId}) async {
    if (categoryId.isEmpty) return;
    emit(state.copyWith(status: SuggestionsStatus.loading));

    final result = await _homeRepository.getProductsByCategoryId(categoryId);
    result.fold(
          (failure) => emit(state.copyWith(status: SuggestionsStatus.error, errorMessage: failure.message)),
          (products) {
        // Lọc ra sản phẩm hiện tại để không tự gợi ý chính nó
        final suggestions = products.where((p) => p.id != currentProductId).toList();
        emit(state.copyWith(status: SuggestionsStatus.success, suggestedProducts: suggestions));
      },
    );
  }
}