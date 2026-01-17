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
        },
        builder: (context, state) {
          if (state.status == AgentSpecialPriceStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
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
                    padding: const EdgeInsets.all(16),
                    itemCount: state.products.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final product = state.products[index];
                      final originalPrice = product.getPriceForRole(user.role);
                      final specialPrice = state.specialPrices[product.id];
                      final hasSpecialPrice = specialPrice != null && specialPrice > 0;

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
                                        'Giá niêm yết (${user.role == 'agent_1' ? 'Cấp 1' : 'Cấp 2'}): ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(originalPrice)}',
                                        style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 13)),
                                    const SizedBox(height: 8),
                                    _PriceInputCell(
                                      productId: product.id,
                                      initialValue: hasSpecialPrice ? specialPrice : null,
                                    ),
                                    if (!hasSpecialPrice)
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
          );
        },
      ),
    );
  }
}

class _PriceInputCell extends StatefulWidget {
  final String productId;
  final double? initialValue;

  const _PriceInputCell({required this.productId, this.initialValue});

  @override
  State<_PriceInputCell> createState() => _PriceInputCellState();
}

class _PriceInputCellState extends State<_PriceInputCell> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
        text: widget.initialValue != null
            ? widget.initialValue!.toInt().toString()
            : '');
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant _PriceInputCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update text if the initialValue changes from outside AND field is not focused
    if (widget.initialValue != oldWidget.initialValue && !_focusNode.hasFocus) {
       final newText = widget.initialValue != null ? widget.initialValue!.toInt().toString() : '';
       if (_controller.text != newText) {
         _controller.text = newText;
       }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      _savePrice(_controller.text);
    }
  }

  void _onChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () {
      _savePrice(value);
    });
  }

  void _savePrice(String value) {
    final price = double.tryParse(value.replaceAll('.', '')) ?? 0.0;
    // Prevent unnecessary saves if value hasn't effectively changed
    // But since we don't have local state of 'lastSaved', we just call cubit.
    // Cubit handles update logic.
    if (mounted) {
        setState(() => _isSaving = true);
        context.read<AgentSpecialPriceCubit>().updateSpecialPrice(widget.productId, price).then((_) {
            if(mounted) setState(() => _isSaving = false);
        });
    }
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
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: 'Nhập giá (0 để xóa)',
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                suffixText: 'đ',
                suffixIcon: _isSaving
                    ? const Padding(
                        padding: EdgeInsets.all(10.0),
                        child: SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : null,
              ),
              onChanged: _onChanged,
              onFieldSubmitted: _savePrice,
            ),
          ),
        ),
      ],
    );
  }
}
