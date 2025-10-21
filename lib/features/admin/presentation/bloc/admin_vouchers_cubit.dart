//lib/features/admin/presentation/bloc/admin_vouchers_cubit.dart

import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:piv_app/data/models/user_model.dart';
import 'package:piv_app/data/models/voucher_with_details.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:piv_app/features/vouchers/data/models/voucher_model.dart';
import 'dart:developer' as developer;
import 'package:rxdart/rxdart.dart';

part 'admin_vouchers_state.dart';

class AdminVouchersCubit extends Cubit<AdminVouchersState> {
  final FirebaseFirestore _firestore;
  final AuthBloc _authBloc;
  StreamSubscription? _subscription;

  AdminVouchersCubit({
    required FirebaseFirestore firestore,
    required AuthBloc authBloc,
  })  : _firestore = firestore,
        _authBloc = authBloc,
        super(const AdminVouchersState());

  void fetchPendingVouchers() {
    emit(state.copyWith(status: AdminVoucherStatus.loading));
    _subscription?.cancel();

    final vouchersStream = _firestore
        .collection('vouchers')
        .where('status', whereIn: [VoucherStatus.pendingApproval, VoucherStatus.pendingDeletion])
        .snapshots();

    final usersStream = _firestore.collection('users').snapshots();

    _subscription = CombineLatestStream.combine2(
      vouchersStream,
      usersStream,
          (QuerySnapshot voucherSnapshot, QuerySnapshot userSnapshot) {
        final vouchers = voucherSnapshot.docs.map((doc) => VoucherModel.fromSnapshot(doc)).toList();

        // <<< SỬA LỖI Ở ĐÂY: DÙNG fromJson THEO ĐÚNG CẤU TRÚC CỦA BẠN >>>
        final userMap = {
          for (var doc in userSnapshot.docs)
            doc.id: (() {
              final data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id; // Thêm ID vào map
              return UserModel.fromJson(data);
            })()
        };

        return vouchers.map((voucher) {
          final creatorName = userMap[voucher.createdBy]?.displayName ?? voucher.createdBy;
          return VoucherWithDetails(voucher: voucher, createdByName: creatorName);
        }).toList();
      },
    ).listen((vouchersWithDetails) {
      final pendingCreation = vouchersWithDetails.where((v) => v.voucher.status == VoucherStatus.pendingApproval).toList();
      final pendingDeletion = vouchersWithDetails.where((v) => v.voucher.status == VoucherStatus.pendingDeletion).toList();

      emit(state.copyWith(
        status: AdminVoucherStatus.success,
        pendingCreationVouchers: pendingCreation,
        pendingDeletionVouchers: pendingDeletion,
      ));
    }, onError: (error) {
      emit(state.copyWith(status: AdminVoucherStatus.error, errorMessage: error.toString()));
    });
  }

  Future<void> reviewVoucher({
    required VoucherModel voucher,
    required String decision,
    String? notes,
  }) async {
    final authState = _authBloc.state;
    if (authState is! AuthAuthenticated) {
      developer.log("Attempted to review voucher without being authenticated.", name: "AdminVouchersCubit");
      return;
    }

    final adminId = authState.user.id;
    final voucherRef = _firestore.collection('vouchers').doc(voucher.id);

    try {
      final currentStatus = voucher.status;
      String newStatus = "";
      String historyAction = "";

      if (currentStatus == VoucherStatus.pendingApproval) {
        newStatus = decision == 'approve' ? VoucherStatus.active : VoucherStatus.rejected;
        historyAction = decision == 'approve' ? 'approved' : 'rejected';
      } else if (currentStatus == VoucherStatus.pendingDeletion) {
        if (decision == 'approve') {
          // *** THAY ĐỔI Ở ĐÂY ***
          // Bước 1: Ghi lại hành động duyệt xóa vào history
          final approveDeleteHistory = VoucherHistoryEntry(
            action: 'approved_deletion', // Hành động mới, khớp với backend check
            actorId: adminId,
            timestamp: Timestamp.now(),
            notes: notes, // Có thể thêm ghi chú nếu cần
          );
          try {
            await voucherRef.update({
              // Chỉ cần thêm history, không cần đổi status vì sắp xóa rồi
              'history': FieldValue.arrayUnion([approveDeleteHistory.toMap()]),
              'approvedBy': adminId, // Ghi lại ai duyệt xóa
            });
            // Bước 2: Xóa document sau khi đã ghi history thành công
            await voucherRef.delete();
            developer.log("Voucher ${voucher.id} deletion approved and deleted by admin $adminId.", name: "AdminVouchersCubit");
          } catch(e) {
            developer.log("Error during voucher deletion approval step: $e", name: "AdminVouchersCubit");
            // Có thể emit lỗi ở đây nếu muốn thông báo cho Admin biết update/delete thất bại
            emit(state.copyWith(status: AdminVoucherStatus.error, errorMessage: "Lỗi khi duyệt xóa voucher."));
          }
          // *** KẾT THÚC THAY ĐỔI ***
          return;
        } else {
          newStatus = voucher.statusBeforeDeletion ?? VoucherStatus.inactive;
          historyAction = 'deletion_rejected';
          developer.log("Rejecting deletion. Reverting status to '$newStatus' (from statusBeforeDeletion).", name: "AdminVouchersCubit");
        }
      } else {
        return;
      }

      final newHistoryEntry = VoucherHistoryEntry(
        action: historyAction,
        actorId: adminId,
        timestamp: Timestamp.now(),
        notes: notes,
      );

      await voucherRef.update({
        'status': newStatus,
        'approvedBy': adminId,
        'history': FieldValue.arrayUnion([newHistoryEntry.toMap()]),
        'statusBeforeDeletion': FieldValue.delete(),
      });
    } catch (e) {
      developer.log("Error reviewing voucher: $e", name: "AdminVouchersCubit");
      emit(state.copyWith(status: AdminVoucherStatus.error, errorMessage: "Đã có lỗi xảy ra khi duyệt."));
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}