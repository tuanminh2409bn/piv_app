import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:piv_app/data/models/price_request_model.dart';
import 'package:piv_app/data/models/user_model.dart';
import 'package:piv_app/features/admin/domain/repositories/special_price_repository.dart';
import 'package:piv_app/features/admin/presentation/bloc/agent_special_price_state.dart';
import 'package:piv_app/features/home/domain/repositories/home_repository.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';

class AgentSpecialPriceCubit extends Cubit<AgentSpecialPriceState> {
  final SpecialPriceRepository specialPriceRepository;
  final HomeRepository homeRepository;
  final AuthBloc authBloc;
  final UserModel targetUser;
  StreamSubscription? _userSubscription;
  StreamSubscription? _requestSubscription;

  AgentSpecialPriceCubit({
    required this.specialPriceRepository,
    required this.homeRepository,
    required this.authBloc,
    required this.targetUser,
  }) : super(const AgentSpecialPriceState());

  Future<void> loadData() async {
    emit(state.copyWith(status: AgentSpecialPriceStatus.loading));
    
    // 1. Watch useGeneralPrice
    _userSubscription?.cancel();
    _userSubscription = specialPriceRepository.watchUseGeneralPrice(targetUser.id).listen((useGeneral) {
      if (!isClosed) emit(state.copyWith(useGeneralPrice: useGeneral));
    });

    // 2. Watch pending request (To lock UI)
    _requestSubscription?.cancel();
    _requestSubscription = specialPriceRepository.watchPendingRequestForAgent(targetUser.id).listen((request) {
      if (!isClosed) {
        emit(state.copyWith(
          pendingRequest: request,
          clearPendingRequest: request == null,
        ));
      }
    });

    try {
      // 3. Fetch products
      final productsResult = await homeRepository.getAllProductsForAdmin();
      
      productsResult.fold(
        (failure) => emit(state.copyWith(
          status: AgentSpecialPriceStatus.error,
          errorMessage: failure.message,
        )),
        (allProducts) async {
          final filteredProducts = allProducts.where((p) {
            if (!p.isPrivate) return true;
            return p.ownerAgentId == targetUser.id;
          }).toList();

          // 4. Fetch existing special prices (Database)
          final specialPricesList = await specialPriceRepository.getSpecialPrices(targetUser.id);
          final specialPricesMap = {
            for (var sp in specialPricesList) sp.productId: sp.price
          };

          emit(state.copyWith(
            status: AgentSpecialPriceStatus.success,
            products: filteredProducts,
            specialPrices: specialPricesMap,
            // Clear unsaved changes on reload
            unsavedChanges: const {}, 
          ));
        },
      );
    } catch (e) {
      emit(state.copyWith(
        status: AgentSpecialPriceStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  // Toggle is now direct for everyone
  Future<void> toggleGeneralPrice(bool value) async {
    try {
      // Optimistic update handled by stream, but we can set it locally too
      emit(state.copyWith(useGeneralPrice: value));
      await specialPriceRepository.toggleUseGeneralPrice(targetUser.id, value);
    } catch (e) {
      emit(state.copyWith(status: AgentSpecialPriceStatus.error, errorMessage: 'Lỗi: $e'));
    }
  }

  void updateSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
  }
  // Only updates local state
  void updateSpecialPriceLocal(String productId, double price) {
    final newUnsaved = Map<String, double>.from(state.unsavedChanges);
    // Check if this matches DB price. If so, remove from unsaved.
    final dbPrice = state.specialPrices[productId] ?? 0.0;
    
    if (price == dbPrice) {
      newUnsaved.remove(productId);
    } else {
      newUnsaved[productId] = price;
    }
    emit(state.copyWith(unsavedChanges: newUnsaved));
  }

  Future<void> saveChanges() async {
    if (state.unsavedChanges.isEmpty) return;
    
    try {
      emit(state.copyWith(status: AgentSpecialPriceStatus.saving));
      final currentUser = (authBloc.state as AuthAuthenticated).user;
      final isStaff = currentUser.role == 'accountant' || currentUser.role == 'sales_rep';

      if (isStaff) {
        // Create BATCH Request
        List<PriceChangeItem> items = [];
        state.unsavedChanges.forEach((productId, newPrice) {
          final product = state.products.firstWhere((p) => p.id == productId, orElse: () => state.products.first);
          final oldPrice = state.specialPrices[productId] ?? 0.0;
          final generalPrice = product.getPriceForRole(targetUser.role); // Lấy giá niêm yết theo cấp đại lý

          items.add(PriceChangeItem(
            productId: productId,
            productName: product.name,
            productImageUrl: product.imageUrl,
            generalPrice: generalPrice,
            oldPrice: oldPrice,
            newPrice: newPrice,
          ));
        });

        final request = PriceRequestModel(
          id: '',
          agentId: targetUser.id,
          agentName: targetUser.displayName ?? targetUser.email ?? 'Unknown',
          requesterId: currentUser.id,
          requesterName: currentUser.displayName ?? currentUser.email ?? 'Unknown',
          requesterRole: currentUser.role,
          type: 'update_price_batch',
          items: items,
          status: 'pending',
          createdAt: Timestamp.now(),
        );

        await specialPriceRepository.createPriceRequest(request);
        emit(state.copyWith(
          status: AgentSpecialPriceStatus.success,
          unsavedChanges: const {}, // Clear unsaved
          errorMessage: 'Đã gửi yêu cầu thay đổi giá. Vui lòng chờ duyệt.', // Info message
        ));
      } else {
        // Admin: Save directly
        for (var entry in state.unsavedChanges.entries) {
          final productId = entry.key;
          final price = entry.value;
          if (price <= 0) {
            await specialPriceRepository.removeSpecialPrice(targetUser.id, productId);
          } else {
            await specialPriceRepository.setSpecialPrice(targetUser.id, productId, price, currentUser.id);
          }
        }
        // Refresh data to sync
        await loadData();
        emit(state.copyWith(status: AgentSpecialPriceStatus.success, errorMessage: 'Đã lưu thay đổi.'));
      }
    } catch (e) {
      emit(state.copyWith(status: AgentSpecialPriceStatus.error, errorMessage: 'Lỗi lưu: $e'));
    }
  }

  Future<void> cancelRequest() async {
    if (state.pendingRequest == null) return;
    try {
      await specialPriceRepository.cancelRequest(state.pendingRequest!.id);
      // UI will unlock via stream
    } catch (e) {
      emit(state.copyWith(status: AgentSpecialPriceStatus.error, errorMessage: 'Lỗi hủy: $e'));
    }
  }

  @override
  Future<void> close() {
    _userSubscription?.cancel();
    _requestSubscription?.cancel();
    return super.close();
  }
}
