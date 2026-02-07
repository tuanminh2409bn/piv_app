import 'package:piv_app/data/models/user_model.dart';
import 'package:piv_app/features/admin/data/models/discount_policy_model.dart';
import 'package:piv_app/features/admin/data/models/discount_request_model.dart';

abstract class DiscountRepository {
  // Dành cho Admin cập nhật trực tiếp
  Future<void> updateDirectly({
    required String userId,
    required bool enabled,
    required AgentPolicy policy,
  });

  // Dành cho NVKD/Kế toán tạo yêu cầu
  Future<void> createRequest(DiscountRequestModel request);

  // Lấy danh sách yêu cầu chờ duyệt (cho Admin)
  Stream<List<DiscountRequestModel>> watchPendingRequests();

  // Kiểm tra xem đại lý này có yêu cầu nào đang chờ không (cho NVKD hiển thị)
  Stream<DiscountRequestModel?> watchPendingRequestForAgent(String agentId);

  // Admin duyệt (có thể ghi đè cấu hình)
  Future<void> approveRequest(DiscountRequestModel request, String adminId, {Map<String, dynamic>? modifiedDiscountConfig});

  // Admin từ chối
  Future<void> rejectRequest(String requestId, String reason);
}
