import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/core/theme/app_theme.dart';
import 'package:piv_app/data/models/user_model.dart';
import 'package:piv_app/features/admin/presentation/bloc/agent_special_price_cubit.dart';
import 'package:piv_app/features/admin/presentation/bloc/agent_special_price_state.dart';

class AgentSpecialPricePage extends StatelessWidget {
  final UserModel user;

  const AgentSpecialPricePage({super.key, required this.user});

  static Route route({required UserModel user}) {
    return MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => AgentSpecialPriceCubit(
          specialPriceRepository: sl(),
          homeRepository: sl(),
          authBloc: sl(),
          targetUser: user,
        )..loadData(),
        child: AgentSpecialPricePage(user: user),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cấu hình giá: ${user.displayName}')),
      body: BlocConsumer<AgentSpecialPriceCubit, AgentSpecialPriceState>(
        listener: (context, state) {
          if (state.status == AgentSpecialPriceStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage ?? 'Lỗi không xác định')),
            );
          }
          if (state.status == AgentSpecialPriceStatus.success && state.errorMessage != null) {
             ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!), backgroundColor: Colors.green),
            );
          }
        },
        builder: (context, state) {
          if (state.status == AgentSpecialPriceStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          final bool isLocked = state.isLocked;

          return Stack(
            children: [
              Column(
                children: [
                  SwitchListTile(
                    title: const Text('Áp dụng giá chung',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text(
                        'Nếu tắt, đại lý sẽ chỉ thấy giá riêng được cấu hình bên dưới.'),
                    value: state.useGeneralPrice,
                    onChanged: (val) {
                      context.read<AgentSpecialPriceCubit>().toggleGeneralPrice(val);
                    },
                    activeColor: AppTheme.primaryGreen,
                  ),
                  const Divider(height: 1),
                  if (!state.useGeneralPrice)
                    Expanded(
                      child: ListView.separated(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 80 + MediaQuery.of(context).padding.bottom),
                        itemCount: state.products.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final product = state.products[index];
                          final originalPrice = product.getPriceForRole(user.role);
                          // Ưu tiên hiển thị giá local đang sửa, sau đó đến giá DB
                          final currentPrice = state.unsavedChanges[product.id] ?? state.specialPrices[product.id];
                          final hasPrice = currentPrice != null && currentPrice > 0;

                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      product.imageUrl,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                          width: 60,
                                          height: 60,
                                          color: Colors.grey.shade200),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(product.name,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15)),
                                        const SizedBox(height: 4),
                                        Text(
                                            'Giá niêm yết: ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(originalPrice)}',
                                            style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 13)),
                                        const SizedBox(height: 8),
                                        _PriceInputCell(
                                          productId: product.id,
                                          initialValue: currentPrice,
                                          enabled: !isLocked,
                                        ),
                                        if (!hasPrice)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4.0),
                                            child: Text(
                                              'Sẽ hiển thị: "Liên hệ"',
                                              style: TextStyle(
                                                  color: Colors.orange.shade800,
                                                  fontStyle: FontStyle.italic,
                                                  fontSize: 12),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Icon(Icons.public,
                              size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'Đại lý đang sử dụng bảng giá niêm yết chung.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              
              // Locked Overlay
              if (isLocked)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.lock_clock, size: 48, color: Colors.orange),
                          const SizedBox(height: 16),
                          const Text(
                            'Đang chờ duyệt',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Yêu cầu thay đổi giá của bạn đang chờ Admin phê duyệt. Bạn không thể chỉnh sửa trong lúc này.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 24),
                          OutlinedButton(
                            onPressed: () => context.read<AgentSpecialPriceCubit>().cancelRequest(),
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                            child: const Text('Hủy yêu cầu để sửa lại'),
                          )
                        ],
                      ),
                    ),
                  ),
                ),

              // Save Button Bar
              if (!isLocked && state.unsavedChanges.isNotEmpty)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -5))],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${state.unsavedChanges.length} thay đổi chưa lưu',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => context.read<AgentSpecialPriceCubit>().saveChanges(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(state.status == AgentSpecialPriceStatus.saving ? 'ĐANG LƯU...' : 'LƯU THAY ĐỔI'),
                        )
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _PriceInputCell extends StatefulWidget {
  final String productId;
  final double? initialValue;
  final bool enabled;

  const _PriceInputCell({required this.productId, this.initialValue, this.enabled = true});

  @override
  State<_PriceInputCell> createState() => _PriceInputCellState();
}

class _PriceInputCellState extends State<_PriceInputCell> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
        text: widget.initialValue != null && widget.initialValue! > 0
            ? widget.initialValue!.toInt().toString()
            : '');
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant _PriceInputCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync external changes (e.g. reset or load) ONLY if not focused
    if (widget.initialValue != oldWidget.initialValue && !_focusNode.hasFocus) {
       final newText = (widget.initialValue != null && widget.initialValue! > 0)
           ? widget.initialValue!.toInt().toString()
           : '';
       if (_controller.text != newText) {
         _controller.text = newText;
       }
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      _commitChange(_controller.text);
    }
  }

  void _commitChange(String value) {
    if (!widget.enabled) return;
    final price = double.tryParse(value.replaceAll('.', '')) ?? 0.0;
    context.read<AgentSpecialPriceCubit>().updateSpecialPriceLocal(widget.productId, price);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('Giá riêng: ',
            style: TextStyle(fontWeight: FontWeight.w500)),
        Expanded(
          child: SizedBox(
            height: 40,
            child: TextFormField(
              controller: _controller,
              focusNode: _focusNode,
              enabled: widget.enabled,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: 'Nhập giá (0 để xóa)',
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                suffixText: 'đ',
                fillColor: widget.enabled ? null : Colors.grey.shade100,
                filled: !widget.enabled,
              ),
              onFieldSubmitted: _commitChange,
            ),
          ),
        ),
      ],
    );
  }
}
