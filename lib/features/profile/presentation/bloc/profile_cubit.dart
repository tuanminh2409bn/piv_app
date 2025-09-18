//lib/features/profile/presentation/bloc/profile_cubit.dart

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/data/models/user_model.dart';
import 'package:piv_app/data/models/address_model.dart'; // Import AddressModel
import 'package:piv_app/features/profile/domain/repositories/user_profile_repository.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'dart:async';
import 'dart:developer' as developer;

part 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final UserProfileRepository _userProfileRepository;
  final AuthBloc _authBloc;
  StreamSubscription? _authSubscription;

  ProfileCubit({
    required UserProfileRepository userProfileRepository,
    required AuthBloc authBloc,
  })  : _userProfileRepository = userProfileRepository,
        _authBloc = authBloc,
        super(const ProfileState()) {
    _authSubscription = _authBloc.stream.listen((authState) {
      if (authState is AuthAuthenticated && authState.user.isNotEmpty) {
        fetchUserProfile(authState.user.id);
      } else if (authState is AuthUnauthenticated) {
        emit(const ProfileState(status: ProfileStatus.initial, user: UserModel.empty));
      }
    });

    final currentAuthState = _authBloc.state;
    if (currentAuthState is AuthAuthenticated && currentAuthState.user.isNotEmpty) {
      fetchUserProfile(currentAuthState.user.id);
    }
  }

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

  void toggleEditMode(bool editing) {
    emit(state.copyWith(isEditing: editing, status: ProfileStatus.success));
  }

  void profileFieldChanged({String? displayName}) {
    if (!state.isEditing) return;

    emit(state.copyWith(
      user: state.user.copyWith(displayName: displayName),
      status: ProfileStatus.success,
    ));
  }

  Future<void> saveUserProfile() async {
    if (!state.isEditing) return;

    emit(state.copyWith(status: ProfileStatus.updating, clearErrorMessage: true));
    final userToUpdate = state.user;
    final result = await _userProfileRepository.updateUserProfile(userToUpdate);
    result.fold(
          (failure) {
        developer.log('ProfileCubit: Failed to save profile - ${failure.message}', name: 'ProfileCubit');
        emit(state.copyWith(status: ProfileStatus.error, errorMessage: failure.message));
      },
          (_) {
        developer.log('ProfileCubit: Profile saved successfully.', name: 'ProfileCubit');
        fetchUserProfile(userToUpdate.id);
      },
    );
  }

  // --- CÁC PHƯƠNG THỨC ĐỊA CHỈ ---
  Future<void> addAddress(AddressModel address) async {
    emit(state.copyWith(status: ProfileStatus.updating));
    final result = await _userProfileRepository.addAddress(state.user.id, address);
    result.fold(
          (failure) => emit(state.copyWith(status: ProfileStatus.error, errorMessage: failure.message)),
          (_) => fetchUserProfile(state.user.id),
    );
  }

  Future<void> updateAddress(AddressModel address) async {
    emit(state.copyWith(status: ProfileStatus.updating));
    final result = await _userProfileRepository.updateAddress(state.user.id, address);
    result.fold(
          (failure) => emit(state.copyWith(status: ProfileStatus.error, errorMessage: failure.message)),
          (_) => fetchUserProfile(state.user.id),
    );
  }

  Future<void> deleteAddress(String addressId) async {
    emit(state.copyWith(status: ProfileStatus.updating));
    final result = await _userProfileRepository.deleteAddress(state.user.id, addressId);
    result.fold(
          (failure) => emit(state.copyWith(status: ProfileStatus.error, errorMessage: failure.message)),
          (_) => fetchUserProfile(state.user.id),
    );
  }

  Future<void> setDefaultAddress(String addressId) async {
    emit(state.copyWith(status: ProfileStatus.updating));
    final result = await _userProfileRepository.setDefaultAddress(state.user.id, addressId);
    result.fold(
          (failure) => emit(state.copyWith(status: ProfileStatus.error, errorMessage: failure.message)),
          (_) => fetchUserProfile(state.user.id),
    );
  }

  // --- CÁC PHƯƠNG THỨC MỚI CHO LỜI NHẮC GIỚI THIỆU ---

  /// Gửi mã giới thiệu và cập nhật thông tin người dùng.
  Future<void> submitReferralCode(String referralCode) async {
    emit(state.copyWith(status: ProfileStatus.updating));
    final result = await _userProfileRepository.submitReferralCode(state.user.id, referralCode);

    result.fold(
          (failure) {
        // Nếu có lỗi (ví dụ: mã không hợp lệ), phát ra lỗi để UI có thể hiển thị
        emit(state.copyWith(status: ProfileStatus.error, errorMessage: failure.message));
        // Sau đó quay lại trạng thái success để người dùng có thể thử lại
        emit(state.copyWith(status: ProfileStatus.success));
      },
          (_) {
        // Thành công, tải lại hồ sơ để nhận cờ referralPromptPending: false mới
        fetchUserProfile(state.user.id);
      },
    );
  }

  /// Bỏ qua lời nhắc và cập nhật cờ trên Firestore.
  Future<void> dismissReferralPrompt() async {
    emit(state.copyWith(status: ProfileStatus.updating));
    final result = await _userProfileRepository.dismissReferralPrompt(state.user.id);

    result.fold(
          (failure) => emit(state.copyWith(status: ProfileStatus.error, errorMessage: failure.message)),
          (_) => fetchUserProfile(state.user.id),
    );
  }

  Future<void> deleteAccount() async {
    // Phát ra trạng thái đang cập nhật để UI có thể hiển thị loading
    emit(state.copyWith(status: ProfileStatus.updating, clearErrorMessage: true));

    final result = await _userProfileRepository.deleteAccount();

    result.fold(
          (failure) {
        // Nếu có lỗi, phát ra trạng thái lỗi với thông điệp
        developer.log('ProfileCubit: Failed to delete account - ${failure.message}', name: 'ProfileCubit');
        emit(state.copyWith(status: ProfileStatus.error, errorMessage: failure.message));
      },
          (_) {
        // Nếu thành công, không cần làm gì ở đây.
        // AuthBloc sẽ tự động xử lý việc đăng xuất và điều hướng người dùng.
        developer.log('ProfileCubit: Account deletion process initiated successfully.', name: 'ProfileCubit');
      },
    );
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
