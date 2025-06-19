// lib/features/wishlist/presentation/bloc/wishlist_cubit.dart
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:piv_app/features/profile/domain/repositories/user_profile_repository.dart';

part 'wishlist_state.dart';

class WishlistCubit extends Cubit<WishlistState> {
  final UserProfileRepository _userProfileRepository;
  final AuthBloc _authBloc;
  StreamSubscription? _authSubscription;

  WishlistCubit({
    required UserProfileRepository userProfileRepository,
    required AuthBloc authBloc,
  })  : _userProfileRepository = userProfileRepository,
        _authBloc = authBloc,
        super(const WishlistState()) {
    // Lắng nghe sự thay đổi trạng thái đăng nhập từ AuthBloc
    _authSubscription = _authBloc.stream.listen((authState) {
      if (authState is AuthAuthenticated) {
        // Khi người dùng đăng nhập, cập nhật wishlist từ thông tin user
        emit(state.copyWith(
            status: WishlistStatus.success,
            productIds: authState.user.wishlist.toSet()));
      } else {
        // Khi người dùng đăng xuất, xóa sạch wishlist
        emit(state.copyWith(status: WishlistStatus.initial, productIds: {}));
      }
    });
  }

  /// Thêm hoặc xóa một sản phẩm khỏi Wishlist
  Future<void> toggleWishlist(String productId) async {
    final authState = _authBloc.state;
    if (authState is! AuthAuthenticated) return; // Chỉ xử lý khi đã đăng nhập

    final currentWishlist = state.productIds;
    final isInWishlist = currentWishlist.contains(productId);

    // Cập nhật giao diện ngay lập tức để người dùng thấy phản hồi
    if (isInWishlist) {
      emit(state.copyWith(productIds: {...currentWishlist}..remove(productId)));
    } else {
      emit(state.copyWith(productIds: {...currentWishlist, productId}));
    }

    // Gọi lên server để cập nhật
    final result = isInWishlist
        ? await _userProfileRepository.removeFromWishlist(authState.user.id, productId)
        : await _userProfileRepository.addToWishlist(authState.user.id, productId);

    result.fold(
          (failure) {
        // Nếu có lỗi, trả lại trạng thái cũ và báo lỗi
        emit(state.copyWith(
          status: WishlistStatus.error,
          productIds: currentWishlist, // Hoàn tác lại thay đổi trên UI
          errorMessage: failure.message,
        ));
      },
          (_) {
        // Nếu thành công, yêu cầu AuthBloc tải lại thông tin user để đồng bộ
        _authBloc.add(AuthUserRefreshRequested());
      },
    );
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}