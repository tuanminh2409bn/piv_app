// lib/features/lucky_wheel/domain/repositories/lucky_wheel_repository.dart

import 'package:dartz/dartz.dart';
import 'package:piv_app/core/error/failure.dart';
import 'package:piv_app/data/models/lucky_wheel_campaign_model.dart';
import 'package:piv_app/data/models/spin_history_model.dart';

abstract class LuckyWheelRepository {
  /// Lấy lượt quay miễn phí khi đăng nhập hàng ngày.
  Future<Either<Failure, String>> grantDailyLoginSpin();

  /// Thực hiện quay thưởng.
  /// Trả về `RewardModel` của phần thưởng trúng.
  Future<Either<Failure, RewardModel>> spinTheWheel();

  /// Lắng nghe chiến dịch vòng quay đang hoạt động cho một vai trò người dùng cụ thể.
  Stream<LuckyWheelCampaignModel?> watchActiveCampaign(String userRole);

  /// Lắng nghe lịch sử quay thưởng của người dùng hiện tại.
  Stream<List<SpinHistoryModel>> watchMySpinHistory();

  /// Lắng nghe toàn bộ lịch sử quay thưởng (cho Admin/Nhân viên).
  Stream<List<SpinHistoryModel>> watchAllSpinHistory();

  // Thêm các hàm quản lý cho Admin
  Future<Either<Failure, void>> createOrUpdateCampaign(LuckyWheelCampaignModel campaign);

  Stream<List<LuckyWheelCampaignModel>> watchAllCampaigns();

}