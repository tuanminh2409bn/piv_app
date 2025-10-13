// lib/features/lucky_wheel/presentation/pages/campaign_form_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/data/models/lucky_wheel_campaign_model.dart';
import 'package:piv_app/features/lucky_wheel/presentation/bloc/admin/campaign_form_cubit.dart';

class CampaignFormPage extends StatelessWidget {
  final LuckyWheelCampaignModel? campaign;

  const CampaignFormPage({super.key, this.campaign});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<CampaignFormCubit>()..init(campaign),
      child: const CampaignFormView(),
    );
  }
}

class CampaignFormView extends StatelessWidget {
  const CampaignFormView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CampaignFormCubit>();
    final isEditing = cubit.state.isEditing;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Sửa Chiến dịch' : 'Tạo Chiến dịch Mới'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              cubit.saveCampaign();
            },
          )
        ],
      ),
      body: BlocConsumer<CampaignFormCubit, CampaignFormState>(
        listener: (context, state) {
          if (state.status == CampaignFormStatus.success) {
            Navigator.of(context).pop();
          }
          if (state.status == CampaignFormStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage ?? 'Lỗi'), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          if (state.status == CampaignFormStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          return _buildForm(context, state);
        },
      ),
    );
  }

  Widget _buildForm(BuildContext context, CampaignFormState state) {
    final cubit = context.read<CampaignFormCubit>();
    final dateFormatter = DateFormat('dd/MM/yyyy');

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        TextFormField(
          initialValue: state.campaign.name,
          decoration: const InputDecoration(labelText: 'Tên chiến dịch', border: OutlineInputBorder()),
          onChanged: (value) => cubit.updateField(name: value),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Kích hoạt chiến dịch'),
          value: state.campaign.isActive,
          onChanged: (value) => cubit.updateField(isActive: value),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () async {
                  final newDate = await showDatePicker(
                    context: context,
                    initialDate: state.campaign.startDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (newDate != null) cubit.updateField(startDate: newDate);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Ngày bắt đầu', border: OutlineInputBorder()),
                  child: Text(dateFormatter.format(state.campaign.startDate)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: InkWell(
                onTap: () async {
                  final newDate = await showDatePicker(
                    context: context,
                    initialDate: state.campaign.endDate,
                    firstDate: state.campaign.startDate,
                    lastDate: DateTime(2100),
                  );
                  if (newDate != null) cubit.updateField(endDate: newDate);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Ngày kết thúc', border: OutlineInputBorder()),
                  child: Text(dateFormatter.format(state.campaign.endDate)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text('Phần thưởng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ...state.campaign.rewards.asMap().entries.map((entry) {
          int index = entry.key;
          RewardModel reward = entry.value;
          return RewardInputTile(
            key: ValueKey(index),
            reward: reward,
            onChanged: (newReward) => cubit.updateReward(index, newReward),
            onRemove: () => cubit.removeReward(index),
          );
        }).toList(),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Thêm phần thưởng'),
            onPressed: () => cubit.addReward(),
          ),
        ),
      ],
    );
  }
}

class RewardInputTile extends StatefulWidget {
  final RewardModel reward;
  final ValueChanged<RewardModel> onChanged;
  final VoidCallback onRemove;

  const RewardInputTile({
    super.key,
    required this.reward,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  State<RewardInputTile> createState() => _RewardInputTileState();
}

class _RewardInputTileState extends State<RewardInputTile> {
  late final TextEditingController _nameController;
  late final TextEditingController _probController;
  late final TextEditingController _limitController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.reward.name);
    _probController = TextEditingController(text: widget.reward.probability.toString());
    _limitController = TextEditingController(text: widget.reward.limit?.toString() ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _probController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  void _update() {
    widget.onChanged(
      widget.reward.copyWith(
        name: _nameController.text,
        probability: int.tryParse(_probController.text) ?? 0,
        limit: int.tryParse(_limitController.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Tên phần thưởng'),
              onChanged: (_) => _update(),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _probController,
                    decoration: const InputDecoration(labelText: 'Tỷ lệ (%)'),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _update(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _limitController,
                    decoration: const InputDecoration(labelText: 'Giới hạn (bỏ trống nếu vô hạn)'),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _update(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: widget.onRemove,
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}

extension RewardModelCopyWith on RewardModel {
  RewardModel copyWith({String? name, int? probability, int? limit}) {
    return RewardModel(
      name: name ?? this.name,
      probability: probability ?? this.probability,
      limit: limit ?? this.limit,
    );
  }
}