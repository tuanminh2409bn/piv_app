// lib/features/search/presentation/bloc/search_cubit.dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/features/home/data/models/product_model.dart';
import 'package:piv_app/features/home/domain/repositories/home_repository.dart';
import 'package:piv_app/features/search/domain/repositories/search_repository.dart';

part 'search_state.dart';

String _removeDiacritics(String str) {
  var withDia = 'áàảãạăắằẳẵặâấầẩẫậéèẻẽẹêếềểễệíìỉĩịóòỏõọôốồổỗộơớờởỡợúùủũụưứừửữựýỳỷỹỵđ';
  var withoutDia = 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';
  for (int i = 0; i < withDia.length; i++) {
    str = str.replaceAll(withDia[i], withoutDia[i]);
  }
  return str;
}

class SearchCubit extends Cubit<SearchState> {
  final SearchRepository _searchRepository;
  final HomeRepository _homeRepository;

  SearchCubit({
    required SearchRepository searchRepository,
    required HomeRepository homeRepository,
  })  : _searchRepository = searchRepository,
        _homeRepository = homeRepository,
        super(const SearchState());

  Future<void> loadSearchHistory() async {
    final history = await _searchRepository.getSearchHistory();
    emit(state.copyWith(status: SearchStatus.success, searchHistory: history));
  }

  Future<void> searchProducts(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      // Nếu query rỗng, chỉ cần tải lại lịch sử và xóa kết quả
      final history = await _searchRepository.getSearchHistory();
      emit(state.copyWith(status: SearchStatus.success, searchResults: [], searchHistory: history));
      return;
    }

    emit(state.copyWith(status: SearchStatus.loading));

    // Lưu từ khóa vào lịch sử
    await _searchRepository.saveSearchTerm(cleanQuery);

    // Tải toàn bộ sản phẩm để tìm kiếm
    final productsResult = await _homeRepository.getAllProducts();

    productsResult.fold(
          (failure) => emit(state.copyWith(status: SearchStatus.error, errorMessage: failure.message)),
          (allProducts) {
        final normalizedQuery = _removeDiacritics(cleanQuery.toLowerCase());
        final filtered = allProducts.where((product) {
          final normalizedProductName = _removeDiacritics(product.name.toLowerCase());
          final normalizedProductDesc = _removeDiacritics(product.description.toLowerCase());
          return normalizedProductName.contains(normalizedQuery) || normalizedProductDesc.contains(normalizedQuery);
        }).toList();

        emit(state.copyWith(status: SearchStatus.success, searchResults: filtered));
      },
    );
  }

  Future<void> removeSearchTerm(String term) async {
    await _searchRepository.removeSearchTerm(term);
    await loadSearchHistory(); // Tải lại lịch sử sau khi xóa
  }

  Future<void> clearHistory() async {
    await _searchRepository.clearSearchHistory();
    emit(state.copyWith(status: SearchStatus.success, searchHistory: []));
  }
}