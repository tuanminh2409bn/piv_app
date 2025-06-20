// lib/features/search/presentation/bloc/search_state.dart
part of 'search_cubit.dart';

enum SearchStatus { initial, loading, success, error }

class SearchState extends Equatable {
  final SearchStatus status;
  final List<String> searchHistory;
  final List<ProductModel> searchResults;
  final String? errorMessage;

  const SearchState({
    this.status = SearchStatus.initial,
    this.searchHistory = const [],
    this.searchResults = const [],
    this.errorMessage,
  });

  @override
  List<Object?> get props => [status, searchHistory, searchResults, errorMessage];

  SearchState copyWith({
    SearchStatus? status,
    List<String>? searchHistory,
    List<ProductModel>? searchResults,
    String? errorMessage,
  }) {
    return SearchState(
      status: status ?? this.status,
      searchHistory: searchHistory ?? this.searchHistory,
      searchResults: searchResults ?? this.searchResults,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}