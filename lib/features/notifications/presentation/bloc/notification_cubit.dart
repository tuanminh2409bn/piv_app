import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:piv_app/features/notifications/domain/repositories/notification_repository.dart';
import 'notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  final NotificationRepository _notificationRepository;
  final AuthBloc _authBloc;
  StreamSubscription? _authSubscription;
  StreamSubscription? _notificationSubscription;
  String? _currentUserId;

  NotificationCubit({
    required NotificationRepository notificationRepository,
    required AuthBloc authBloc,
  })  : _notificationRepository = notificationRepository,
        _authBloc = authBloc,
        super(NotificationInitial()) {
    // Lắng nghe trạng thái đăng nhập từ AuthBloc
    _authSubscription = _authBloc.stream.listen((authState) {
      if (authState is AuthAuthenticated) {
        // Nếu người dùng đã đăng nhập và khác với người dùng hiện tại
        if (_currentUserId != authState.user.id) {
          _currentUserId = authState.user.id;
          fetchNotifications(); // Bắt đầu lấy thông báo
        }
      } else if (authState is AuthUnauthenticated) {
        // Nếu người dùng đăng xuất, hủy lắng nghe và reset state
        _notificationSubscription?.cancel();
        _currentUserId = null;
        emit(NotificationInitial());
      }
    });

    // Kiểm tra trạng thái đăng nhập ban đầu
    final initialState = _authBloc.state;
    if (initialState is AuthAuthenticated) {
      _currentUserId = initialState.user.id;
      fetchNotifications();
    }
  }

  /// Bắt đầu lắng nghe stream thông báo từ Firestore.
  void fetchNotifications() {
    if (_currentUserId == null) return;

    emit(NotificationLoading());
    // Hủy subscription cũ trước khi tạo mới
    _notificationSubscription?.cancel();

    _notificationSubscription = _notificationRepository
        .getUserNotifications(_currentUserId!)
        .listen((notifications) {
      // Đếm số thông báo chưa đọc
      final unreadCount = notifications.where((n) => !n.isRead).length;
      // Phát ra state mới với danh sách thông báo và số lượng chưa đọc
      emit(NotificationLoaded(notifications, unreadCount));
    }, onError: (error) {
      emit(NotificationError('Không thể tải thông báo: ${error.toString()}'));
    });
  }

  /// Đánh dấu một thông báo là đã đọc.
  Future<void> markAsRead(String notificationId) async {
    // Kiểm tra xem userId có tồn tại không trước khi thực hiện
    if (_currentUserId == null) {
      print('Lỗi: Không tìm thấy userId để đánh dấu đã đọc.');
      return;
    }
    try {
      // Tự động sử dụng _currentUserId đã được lưu
      await _notificationRepository.markAsRead(_currentUserId!, notificationId);
      // Giao diện sẽ tự động cập nhật nhờ Stream, không cần emit state ở đây.
    } catch (e) {
      // Có thể log lỗi hoặc hiển thị một thông báo nhỏ nếu cần
      print('Lỗi khi đánh dấu đã đọc: $e');
    }
  }

  @override
  Future<void> close() {
    // Đảm bảo hủy tất cả các stream subscriptions khi Cubit bị đóng
    _authSubscription?.cancel();
    _notificationSubscription?.cancel();
    return super.close();
  }
}