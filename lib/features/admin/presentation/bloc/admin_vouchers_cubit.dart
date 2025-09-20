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
          await voucherRef.delete();
          return;
        } else {
          newStatus = VoucherStatus.active;
          historyAction = 'deletion_rejected';
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