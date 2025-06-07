import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/data/models/user_model.dart';
import 'package:piv_app/features/profile/domain/repositories/user_profile_repository.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart'; // Để lấy userId
import 'dart:async';
import 'dart:developer' as developer;

part 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final UserProfileRepository _userProfileRepository;
  final AuthBloc _authBloc; // Để lấy thông tin người dùng hiện tại
  StreamSubscription? _authSubscription;

  ProfileCubit({
    required UserProfileRepository userProfileRepository,
    required AuthBloc authBloc, // Inject AuthBloc
  })  : _userProfileRepository = userProfileRepository,
        _authBloc = authBloc,
        super(const ProfileState()) {
    // Lắng nghe trạng thái từ AuthBloc để tự động tải hồ sơ khi người dùng đăng nhập
    _authSubscription = _authBloc.stream.listen((authState) {
      if (authState is AuthAuthenticated && authState.user.isNotEmpty) {
        // Tải lại hồ sơ từ UserProfileRepository để đảm bảo dữ liệu mới nhất
        fetchUserProfile(authState.user.id);
      } else if (authState is AuthUnauthenticated) {
        // Nếu người dùng đăng xuất, reset ProfileState
        emit(const ProfileState(status: ProfileStatus.initial, user: UserModel.empty));
      }
    });
    // Tải hồ sơ lần đầu khi Cubit được tạo (nếu user đã đăng nhập)
    final currentAuthState = _authBloc.state;
    if (currentAuthState is AuthAuthenticated && currentAuthState.user.isNotEmpty) {
      fetchUserProfile(currentAuthState.user.id);
    }
  }

  /// Tải hồ sơ người dùng từ repository.
  Future<void> fetchUserProfile(String userId) async {
    if (userId.isEmpty) {
      emit(state.copyWith(status: ProfileStatus.error, errorMessage: "ID người dùng không hợp lệ."));
      return;
    }
    emit(state.copyWith(status: ProfileStatus.loading, clearErrorMessage: true));
    developer.log('ProfileCubit: Fetching profile for user ID: $userId', name: 'ProfileCubit');

    final result = await _userProfileRepository.getUserProfile(userId);
    result.fold(
          (failure) {
        developer.log('ProfileCubit: Failed to fetch profile - ${failure.message}', name: 'ProfileCubit');
        emit(state.copyWith(status: ProfileStatus.error, errorMessage: failure.message));
      },
          (user) {
        developer.log('ProfileCubit: Profile fetched successfully - ${user.email}', name: 'ProfileCubit');
        emit(state.copyWith(status: ProfileStatus.success, user: user, isEditing: false));
      },
    );
  }

  /// Bật hoặc tắt chế độ chỉnh sửa hồ sơ.
  void toggleEditMode(bool editing) {
    emit(state.copyWith(isEditing: editing, status: ProfileStatus.success));
  }

  /// Được gọi khi người dùng thay đổi một trường thông tin trên UI.
  /// Cập nhật state tạm thời, chưa lưu vào cơ sở dữ liệu.
  void profileFieldChanged({
    String? displayName,
    // Thêm các trường khác có thể chỉnh sửa ở đây:
    // String? phoneNumber,
  }) {
    if (!state.isEditing) return; // Chỉ cho phép thay đổi khi đang ở chế độ edit

    emit(state.copyWith(
      user: state.user.copyWith(
        displayName: displayName,
        // phoneNumber: phoneNumber,
      ),
      status: ProfileStatus.success,
    ));
  }

  /// Lưu các thay đổi trong hồ sơ người dùng vào Firestore.
  Future<void> saveUserProfile() async {
    if (!state.isEditing) return;

    emit(state.copyWith(status: ProfileStatus.updating, clearErrorMessage: true));
    developer.log('ProfileCubit: Saving profile for user: ${state.user.id}', name: 'ProfileCubit');

    final userToUpdate = state.user;

    final result = await _userProfileRepository.updateUserProfile(userToUpdate);
    result.fold(
          (failure) {
        developer.log('ProfileCubit: Failed to save profile - ${failure.message}', name: 'ProfileCubit');
        emit(state.copyWith(status: ProfileStatus.error, errorMessage: failure.message));
      },
          (_) {
        developer.log('ProfileCubit: Profile saved successfully.', name: 'ProfileCubit');
        // Tải lại hồ sơ để đảm bảo dữ liệu trên UI là mới nhất từ DB.
        fetchUserProfile(userToUpdate.id);
      },
    );
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
