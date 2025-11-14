import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/features/home/data/models/product_model.dart';
import 'package:piv_app/features/home/domain/repositories/home_repository.dart';
import 'package:piv_app/features/search/domain/repositories/search_repository.dart';

// --- THÊM CÁC IMPORT CẦN THIẾT ---
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:piv_app/data/models/user_model.dart'; // Cần để lấy AuthAuthenticated
// --- KẾT THÚC THÊM IMPORT ---


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
  final AuthBloc _authBloc; // <-- ĐÃ THÊM Ở BƯỚC TRƯỚC

  SearchCubit({
    required SearchRepository searchRepository,
    required HomeRepository homeRepository,
    required AuthBloc authBloc, // <-- ĐÃ THÊM Ở BƯỚC TRƯỚC
  })  : _searchRepository = searchRepository,
        _homeRepository = homeRepository,
        _authBloc = authBloc, // <-- ĐÃ THÊM Ở BƯỚC TRƯỚC
        super(const SearchState());

  Future<void> loadSearchHistory() async {
    final history = await _searchRepository.getSearchHistory();
    emit(state.copyWith(status: SearchStatus.success, searchHistory: history));
  }

  // --- SỬA ĐỔI HÀM searchProducts ---
  Future<void> searchProducts(String query, {String? targetAgentId}) async {
    final cleanQuery = query.trim();

    // Chỉ lưu vào lịch sử nếu *người dùng tự tìm kiếm* (không phải admin chọn)
    if (cleanQuery.isNotEmpty && targetAgentId == null) {
      await _searchRepository.saveSearchTerm(cleanQuery);
    }

    emit(state.copyWith(status: SearchStatus.loading));

    // --- LOGIC LỌC NGƯỜI DÙNG PHỨC TẠP ---
    String? currentUserId;
    final authState = _authBloc.state;

    if (targetAgentId != null) {
      // TRƯỜNG HỢP 1: Admin/NVKD đang tìm sản phẩm CHO MỘT ĐẠI LÝ
      // Chúng ta muốn thấy sản phẩm chung + sản phẩm riêng của đại lý đó
      currentUserId = targetAgentId;
    } else if (authState is AuthAuthenticated) {
      // TRƯỜNG HỢP 2: Người dùng tự tìm kiếm
      final user = authState.user;
      if (user.role == 'agent_1' || user.role == 'agent_2') {
        // Nếu là Đại lý, chỉ thấy sản phẩm chung + của riêng mình
        currentUserId = user.id;
      }
      // Nếu là Admin/NVKD/Kế toán (và targetAgentId == null)
      // chúng ta để currentUserId = null.
      // Hàm getAllProducts sẽ hiểu là chỉ lấy sản phẩm CHUNG (isPrivate == false)
      // (Vì Admin không nên thấy sản phẩm riêng của tất cả mọi người ở đây)
    }
    // --- KẾT THÚC LOGIC LỌC ---

    // Gọi hàm repository đã được nâng cấp
    final productsResult = await _homeRepository.getAllProducts(currentUserId: currentUserId);

    productsResult.fold(
          (failure) => emit(state.copyWith(status: SearchStatus.error, errorMessage: failure.message)),
          (allAllowedProducts) async { // Đây là danh sách đã được lọc bởi Repository

        final List<ProductModel> filteredProducts;

        if (cleanQuery.isEmpty) {
          filteredProducts = allAllowedProducts; // Hiển thị tất cả nếu query rỗng
        } else {
          // Lọc cục bộ trên danh sách đã được phép xem
          final normalizedQuery = _removeDiacritics(cleanQuery.toLowerCase());
          filteredProducts = allAllowedProducts.where((product) {
            final normalizedProductName = _removeDiacritics(product.name.toLowerCase());
            final normalizedProductDesc = _removeDiacritics(product.description.toLowerCase());
            return normalizedProductName.contains(normalizedQuery) || normalizedProductDesc.contains(normalizedQuery);
          }).toList();
        }

        // Tải lại lịch sử (chỉ ảnh hưởng nếu là người dùng tự tìm)
        final updatedHistory = await _searchRepository.getSearchHistory();

        emit(state.copyWith(
          status: SearchStatus.success,
          searchResults: filteredProducts,
          searchHistory: updatedHistory,
        ));
      },
    );
  }
  // --- KẾT THÚC SỬA ĐỔI ---

  Future<void> removeSearchTerm(String term) async {
    await _searchRepository.removeSearchTerm(term);
    await loadSearchHistory();
  }

  Future<void> clearHistory() async {
    await _searchRepository.clearSearchHistory();
    emit(state.copyWith(status: SearchStatus.success, searchHistory: []));
  }
}