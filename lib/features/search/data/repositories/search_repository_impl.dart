// lib/features/search/data/repositories/search_repository_impl.dart

import 'package:piv_app/features/search/domain/repositories/search_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchRepositoryImpl implements SearchRepository {
  final SharedPreferences _prefs;
  static const String _searchHistoryKey = 'search_history';

  SearchRepositoryImpl({required SharedPreferences prefs}) : _prefs = prefs;

  @override
  Future<List<String>> getSearchHistory() async {
    return _prefs.getStringList(_searchHistoryKey) ?? [];
  }

  @override
  Future<void> saveSearchTerm(String term) async {
    final cleanTerm = term.trim();
    if (cleanTerm.isEmpty) return;

    final history = await getSearchHistory();
    // Xóa từ khóa cũ nếu đã tồn tại để đưa nó lên đầu danh sách
    history.removeWhere((item) => item.toLowerCase() == cleanTerm.toLowerCase());
    // Thêm từ khóa mới vào đầu danh sách
    history.insert(0, cleanTerm);
    // Giới hạn lịch sử chỉ lưu 15 từ khóa gần nhất
    if (history.length > 15) {
      history.removeRange(15, history.length);
    }
    await _prefs.setStringList(_searchHistoryKey, history);
  }

  @override
  Future<void> removeSearchTerm(String term) async {
    final history = await getSearchHistory();
    history.removeWhere((item) => item.toLowerCase() == term.toLowerCase());
    await _prefs.setStringList(_searchHistoryKey, history);
  }

  @override
  Future<void> clearSearchHistory() async {
    await _prefs.remove(_searchHistoryKey);
  }
}