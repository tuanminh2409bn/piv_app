// lib/features/cart/presentation/bloc/cart_suggestions_state.dart
part of 'cart_suggestions_cubit.dart';

enum SuggestionsStatus { initial, loading, success, error }

class CartSuggestionsState extends Equatable {
  final SuggestionsStatus status;
  final List<ProductModel> suggestedProducts;
  final String? errorMessage;

  const CartSuggestionsState({
    this.status = SuggestionsStatus.initial,
    this.suggestedProducts = const [],
    this.errorMessage,
  });

  @override
  List<Object?> get props => [status, suggestedProducts, errorMessage];

  CartSuggestionsState copyWith({
    SuggestionsStatus? status,
    List<ProductModel>? suggestedProducts,
    String? errorMessage,
  }) {
    return CartSuggestionsState(
      status: status ?? this.status,
      suggestedProducts: suggestedProducts ?? this.suggestedProducts,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}