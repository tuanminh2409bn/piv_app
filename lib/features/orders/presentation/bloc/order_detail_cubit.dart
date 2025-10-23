// lib/features/orders/presentation/bloc/order_detail_cubit.dart

import 'dart:async';
import 'dart:developer' as developer;
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/data/models/order_model.dart';
import 'package:piv_app/data/models/payment_info_model.dart';
import 'package:piv_app/data/models/user_model.dart';
// +++ THÊM IMPORT VOUCHER +++
import 'package:piv_app/features/vouchers/data/models/voucher_model.dart';
import 'package:piv_app/features/vouchers/domain/repositories/voucher_repository.dart';
// +++ KẾT THÚC THÊM +++
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart'; // Cần để lấy user info
import 'package:piv_app/features/orders/domain/repositories/order_repository.dart';
import 'package:piv_app/features/profile/domain/repositories/user_profile_repository.dart';
import 'package:piv_app/features/returns/data/models/return_request_model.dart';
import 'package:piv_app/features/returns/domain/repositories/return_repository.dart';

part 'order_detail_state.dart';

class OrderDetailCubit extends Cubit<OrderDetailState> {
  final OrderRepository _orderRepository;
  final UserProfileRepository _userProfileRepository;
  final ReturnRepository _returnRepository;
  // +++ THÊM DEPENDENCY +++
  final VoucherRepository _voucherRepository;
  final AuthBloc _authBloc; // Cần AuthBloc để lấy userId và userRole khi apply voucher
  // +++ KẾT THÚC THÊM +++
  StreamSubscription<OrderModel>? _orderSubscription;
  StreamSubscription<ReturnRequestModel>? _returnRequestSubscription;

  OrderDetailCubit({
    required OrderRepository orderRepository,
    required UserProfileRepository userProfileRepository,
    required ReturnRepository returnRepository,
    // +++ THÊM VÀO CONSTRUCTOR +++
    required VoucherRepository voucherRepository,
    required AuthBloc authBloc,
    // +++ KẾT THÚC THÊM +++
  })  : _orderRepository = orderRepository,
        _userProfileRepository = userProfileRepository,
        _returnRepository = returnRepository,
  // +++ GÁN DEPENDENCY +++
        _voucherRepository = voucherRepository,
        _authBloc = authBloc,
  // +++ KẾT THÚC GÁN +++
        super(const OrderDetailState());

  // --- listenToOrderDetail giữ nguyên logic load order ban đầu ---
  void listenToOrderDetail(String orderId) {
    if (orderId.isEmpty) {
      emit(state.copyWith(status: OrderDetailStatus.error, errorMessage: 'ID đơn hàng không hợp lệ.'));
      return;
    }
    // Chỉ set loading nếu đang là initial
    if (state.status == OrderDetailStatus.initial) {
      emit(state.copyWith(status: OrderDetailStatus.loading));
    }
    _orderSubscription?.cancel();

    _orderSubscription = _orderRepository.getOrderStreamById(orderId).listen(
          (order) async {
        developer.log("Received update for order ${order.id}. Status: ${order.status}", name: "OrderDetailCubit");

        UserModel? placedByUser;
        if (order.placedBy != null && order.placedBy!.userId.isNotEmpty) {
          // Chỉ fetch lại placedByUser nếu chưa có hoặc ID thay đổi (hiếm)
          if (state.placedByUser == null || state.placedByUser!.id != order.placedBy!.userId) {
            final userResult = await _userProfileRepository.getUserProfile(order.placedBy!.userId);
            userResult.fold(
                  (failure) => placedByUser = null,
                  (user) => placedByUser = user,
            );
          } else {
            placedByUser = state.placedByUser;
          }
        }

        // --- QUAN TRỌNG: Giữ lại voucher state hiện tại nếu có ---
        // Tránh việc reset voucher mỗi khi order stream update (ví dụ khi admin xem)
        VoucherModel? currentAppliedVoucher = state.appliedVoucher;
        double currentVoucherDiscount = state.voucherDiscount;
        // Nếu order update từ Firestore có discount > 0 và cubit chưa có voucher,
        // có thể thử load lại voucher nếu cần (ít xảy ra)
        if (order.discount > 0 && currentAppliedVoucher == null) {
          // Tạm thời bỏ qua việc load lại voucher khi stream update,
          // tập trung vào việc user tự apply/remove
          currentVoucherDiscount = order.discount; // Lấy discount từ order nếu chưa có voucher
        }


        _returnRequestSubscription?.cancel();
        if (order.returnInfo?.returnRequestId != null && order.returnInfo!.returnRequestId.isNotEmpty) {
          // Chỉ listen lại nếu ID thay đổi hoặc chưa có subscription
          if (state.returnRequest == null || state.returnRequest!.id != order.returnInfo!.returnRequestId) {
            _returnRequestSubscription = _returnRepository
                .watchReturnRequestById(order.returnInfo!.returnRequestId)
                .listen((returnRequest) {
              emit(state.copyWith(returnRequest: returnRequest));
            }, onError: (e) {
              developer.log("Error watching return request: $e", name: "OrderDetailCubit");
              // Có thể emit lỗi nhẹ ở đây nếu cần
            });
          }
        } else {
          // Nếu order không còn return info, đảm bảo state returnRequest là null
          if (state.returnRequest != null) {
            emit(state.copyWith(returnRequest: null)); // Cần định nghĩa copyWith cho phép set null
          }
        }

        emit(state.copyWith(
          // Chỉ set status thành success nếu đang loading hoặc initial
          status: (state.status == OrderDetailStatus.loading || state.status == OrderDetailStatus.initial)
              ? OrderDetailStatus.success
              : state.status, // Giữ status hiện tại (ví dụ: applyingVoucher, error...)
          order: order,
          placedByUser: placedByUser, // Đã lấy ở trên
          // Giữ lại voucher state
          appliedVoucher: currentAppliedVoucher,
          voucherDiscount: currentVoucherDiscount,
        ));

        // Chỉ fetch payment info lần đầu hoặc khi cần
        if (order.paymentStatus == 'unpaid' && state.paymentInfo == null) {
          _fetchPaymentInfo();
        }
      },
      onError: (error) {
        developer.log("Error listening to order: $error", name: "OrderDetailCubit");
        emit(state.copyWith(status: OrderDetailStatus.error, errorMessage: 'Lỗi lắng nghe đơn hàng: $error'));
      },
    );
  }


  Future<void> _fetchPaymentInfo() async {
    // ... (hàm này giữ nguyên) ...
    if (state.paymentInfo != null) return;
    final result = await _orderRepository.getPaymentInfo();
    result.fold(
          (failure) => developer.log("Could not fetch payment info: ${failure.message}", name: "OrderDetailCubit"),
          (info) => emit(state.copyWith(paymentInfo: info)),
    );
  }

  // +++ HÀM MỚI: applyVoucher +++
  Future<void> applyVoucher(String code) async {
    if (code.isEmpty || state.order == null) return;
    // Chỉ cho phép áp dụng voucher khi đang chờ duyệt
    if (state.order!.status != 'pending_approval') {
      emit(state.copyWith(status: OrderDetailStatus.voucherError, errorMessage: 'Không thể áp dụng voucher cho đơn hàng này.', clearError: false));
      emit(state.copyWith(status: OrderDetailStatus.success, clearError: true)); // Reset status về success
      return;
    }

    emit(state.copyWith(status: OrderDetailStatus.applyingVoucher));

    final authState = _authBloc.state;
    if (authState is! AuthAuthenticated) {
      emit(state.copyWith(status: OrderDetailStatus.error, errorMessage: 'Lỗi xác thực người dùng.'));
      return;
    }
    // Cần userId và userRole để kiểm tra điều kiện voucher
    final userId = authState.user.id;
    final userRole = authState.user.role;
    // Cần subtotal của đơn hàng để tính toán giảm giá
    final subtotal = state.order!.subtotal;

    final result = await _voucherRepository.applyVoucher(
      code: code.toUpperCase(),
      userId: userId,
      userRole: userRole,
      // CÓ THỂ cần truyền thêm subtotal vào đây nếu repository cần để kiểm tra minSpend
    );

    result.fold(
          (failure) {
        emit(state.copyWith(status: OrderDetailStatus.voucherError, errorMessage: failure.message, clearError: false));
        emit(state.copyWith(status: OrderDetailStatus.success, clearError: true)); // Reset status về success
      },
          (voucher) {
        final discountAmount = voucher.calculateDiscount(subtotal);
        emit(state.copyWith(
          status: OrderDetailStatus.success,
          appliedVoucher: voucher,
          voucherDiscount: discountAmount,
        ));
        developer.log("Applied voucher ${voucher.id}, discount: $discountAmount", name: "OrderDetailCubit");
      },
    );
  }
  // +++ KẾT THÚC HÀM MỚI +++

  // +++ HÀM MỚI: removeVoucher +++
  void removeVoucher() {
    // Chỉ cho phép xóa voucher khi đang chờ duyệt
    if (state.order?.status != 'pending_approval') return;

    emit(state.copyWith(
      status: OrderDetailStatus.success,
      forceVoucherToNull: true, // Sử dụng flag để xóa voucher và discount
      voucherDiscount: 0.0,
    ));
    developer.log("Removed voucher", name: "OrderDetailCubit");
  }
  // +++ KẾT THÚC HÀM MỚI +++

  // --- SỬA HÀM approveOrder ---
  Future<void> approveOrder({required double paidAmount}) async {
    if (state.order?.id == null) return;
    // Chỉ cho phép duyệt khi đang chờ duyệt
    if (state.order!.status != 'pending_approval') return;

    emit(state.copyWith(status: OrderDetailStatus.updating));

    // Lấy thông tin voucher từ state
    final voucherCode = state.appliedVoucher?.id;
    final voucherDiscount = state.voucherDiscount;

    final result = await _orderRepository.approveOrder(
      state.order!.id!,
      paidAmount: paidAmount,
      // Truyền thông tin voucher
      voucherDiscount: voucherDiscount,
      appliedVoucherCode: voucherCode,
    );

    result.fold(
          (failure) => emit(state.copyWith(
          status: OrderDetailStatus.error, errorMessage: failure.message)),
          (_) {
        // Stream tự cập nhật, không cần emit gì ở đây
        // Quan trọng: Sau khi duyệt thành công, nên reset voucher state của cubit
        // vì voucher đã được lưu vào order trên Firestore rồi.
        emit(state.copyWith(forceVoucherToNull: true, voucherDiscount: 0.0));
      },
    );
  }
  // --- KẾT THÚC SỬA ---


  Future<void> rejectOrder(String reason) async {
    // ... (hàm này giữ nguyên) ...
    if (state.order?.id == null) return;
    // Chỉ cho phép từ chối khi đang chờ duyệt
    if (state.order!.status != 'pending_approval') return;

    emit(state.copyWith(status: OrderDetailStatus.updating));
    final result = await _orderRepository.rejectOrder(orderId: state.order!.id!, reason: reason);
    result.fold(
          (failure) => emit(state.copyWith(status: OrderDetailStatus.error, errorMessage: failure.message)),
          (_) {
        // Stream tự cập nhật, nhưng có thể reset voucher state ở đây nếu cần
        emit(state.copyWith(forceVoucherToNull: true, voucherDiscount: 0.0));
      },
    );
  }

  Future<void> notifyPaymentMade() async {
    // ... (hàm này giữ nguyên) ...
    if (state.order?.id == null) return;
    emit(state.copyWith(status: OrderDetailStatus.updatingPaymentStatus));
    final result = await _orderRepository.notifyPaymentMade(state.order!.id!);
    result.fold(
          (failure) => emit(state.copyWith(status: OrderDetailStatus.error, errorMessage: failure.message)),
          (_) { /* Stream tự cập nhật */ },
    );
  }

  @override
  Future<void> close() {
    _orderSubscription?.cancel();
    _returnRequestSubscription?.cancel();
    return super.close();
  }
}