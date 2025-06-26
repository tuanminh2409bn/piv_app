import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/features/admin/domain/repositories/settings_repository.dart';

part 'admin_settings_state.dart';

class AdminSettingsCubit extends Cubit<AdminSettingsState> {
  final SettingsRepository _settingsRepository;

  AdminSettingsCubit({required SettingsRepository settingsRepository})
      : _settingsRepository = settingsRepository,
        super(const AdminSettingsState());

  Future<void> loadSettings() async {
    emit(state.copyWith(status: AdminSettingsStatus.loading));
    final result = await _settingsRepository.getCommissionRate();
    result.fold(
          (failure) => emit(state.copyWith(status: AdminSettingsStatus.error)),
          (rate) => emit(state.copyWith(status: AdminSettingsStatus.success, commissionRate: rate)),
    );
  }

  Future<void> saveCommissionRate(String rateString) async {
    // Chuyển đổi và kiểm tra giá trị bên trong Cubit
    final rateValue = double.tryParse(rateString);
    if (rateValue == null || rateValue < 0 || rateValue > 100) {
      emit(state.copyWith(status: AdminSettingsStatus.error)); // Có thể thêm errorMessage nếu muốn
      // Tải lại giá trị cũ để người dùng thấy
      loadSettings();
      return;
    }
    // Chia cho 100 để lưu đúng định dạng (ví dụ: người dùng nhập 5.5 -> lưu 0.055)
    await _settingsRepository.updateCommissionRate(rateValue / 100);
    // Tải lại cài đặt sau khi lưu để cập nhật giao diện với giá trị mới nhất
    loadSettings();
  }
}