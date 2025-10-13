// lib/features/search/domain/repositories/search_repository.dart

abstract class SearchRepository {
  /// Lấy danh sách các từ khóa đã tìm kiếm.
  Future<List<String>> getSearchHistory();

  /// Lưu một từ khóa mới vào lịch sử.
  Future<void> saveSearchTerm(String term);

  /// Xóa một từ khóa khỏi lịch sử.
  Future<void> removeSearchTerm(String term);

  /// Xóa toàn bộ lịch sử tìm kiếm.
  Future<void> clearSearchHistory();
}