import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  AgentSpecialPriceCubit({
    required this.specialPriceRepository,
    required this.homeRepository,
    required this.authBloc,
    required this.targetUser,
  }) : super(const AgentSpecialPriceState());

  Future<void> loadData() async {
    emit(state.copyWith(status: AgentSpecialPriceStatus.loading));
    
    // Subscribe to real-time updates for useGeneralPrice
    _userSubscription?.cancel();
    _userSubscription = specialPriceRepository.watchUseGeneralPrice(targetUser.id).listen((useGeneral) {
      if (!isClosed) {
        emit(state.copyWith(useGeneralPrice: useGeneral));
      }
    });

    try {
      // 2. Fetch all products
      final productsResult = await homeRepository.getAllProductsForAdmin();
      
      productsResult.fold(
        (failure) => emit(state.copyWith(
          status: AgentSpecialPriceStatus.error,
          errorMessage: failure.message,
        )),
        (allProducts) async {
          // Filter products logic:
          // Show public products (isPrivate == false) OR products owned by this specific agent
          // Do NOT show private products owned by OTHER agents
          final filteredProducts = allProducts.where((p) {
            if (!p.isPrivate) return true;
            return p.ownerAgentId == targetUser.id;
          }).toList();

          // 3. Fetch existing special prices
          final specialPricesList = await specialPriceRepository.getSpecialPrices(targetUser.id);
          final specialPricesMap = {
            for (var sp in specialPricesList) sp.productId: sp.price
          };

          emit(state.copyWith(
            status: AgentSpecialPriceStatus.success,
            products: filteredProducts,
            specialPrices: specialPricesMap,
            // useGeneralPrice is now handled by the stream, but we can set initial value from targetUser just in case
            // though the stream will emit almost immediately.
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

  Future<void> toggleGeneralPrice(bool value) async {
    try {
      // Optimistic update is not strictly needed as stream will update UI, 
      // but keeps UI responsive.
      emit(state.copyWith(useGeneralPrice: value)); 
      await specialPriceRepository.toggleUseGeneralPrice(targetUser.id, value);
    } catch (e) {
      // Revert is handled by stream or next fetch, but we show error
      emit(state.copyWith(
        status: AgentSpecialPriceStatus.error,
        errorMessage: 'Không thể cập nhật trạng thái giá chung: $e',
      ));
    }
  }

  Future<void> updateSpecialPrice(String productId, double price) async {
    // Optimistic update
    final newMap = Map<String, double>.from(state.specialPrices);
    if (price <= 0) {
       newMap.remove(productId);
    } else {
       newMap[productId] = price;
    }
    emit(state.copyWith(specialPrices: newMap));

    try {
      final currentUser = (authBloc.state as AuthAuthenticated).user;
      if (price <= 0) {
        await specialPriceRepository.removeSpecialPrice(targetUser.id, productId);
      } else {
        await specialPriceRepository.setSpecialPrice(targetUser.id, productId, price, currentUser.id);
      }
    } catch (e) {
      // Revert on error could be implemented here
      emit(state.copyWith(
          status: AgentSpecialPriceStatus.error,
          errorMessage: 'Lỗi lưu giá: $e'
      ));
    }
  }

  @override
  Future<void> close() {
    _userSubscription?.cancel();
    return super.close();
  }
}
