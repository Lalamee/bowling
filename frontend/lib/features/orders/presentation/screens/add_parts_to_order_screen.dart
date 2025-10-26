import 'package:flutter/material.dart';

import '../../../../core/repositories/maintenance_repository.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/net_ui.dart';
import '../../../../models/maintenance_request_response_dto.dart';
import '../../../../models/part_request_dto.dart';
import '../../../../shared/widgets/buttons/custom_button.dart';

class AddPartsToOrderScreen extends StatefulWidget {
  final MaintenanceRequestResponseDto order;

  const AddPartsToOrderScreen({super.key, required this.order});

  @override
  State<AddPartsToOrderScreen> createState() => _AddPartsToOrderScreenState();
}

class _AddPartsToOrderScreenState extends State<AddPartsToOrderScreen> {
  final _catalogController = TextEditingController();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _partFormKey = GlobalKey<FormState>();
  final _repository = MaintenanceRepository();

  final List<RequestedPartDto> _pendingParts = [];
  bool _isSubmitting = false;

  MaintenanceRequestResponseDto get order => widget.order;

  @override
  void dispose() {
    _catalogController.dispose();
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Добавить детали в заявку №${order.requestId}'),
      ),
      backgroundColor: AppColors.background,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _OrderSummaryCard(order: order),
          const SizedBox(height: 16),
          _ExistingPartsList(order: order),
          const SizedBox(height: 24),
          Text(
            'Новые детали',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark),
          ),
          const SizedBox(height: 12),
          Form(
            key: _partFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField(
                  label: 'Каталожный номер *',
                  hint: 'Введите каталожный номер',
                  controller: _catalogController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Укажите каталожный номер';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  label: 'Название детали *',
                  hint: 'Введите название',
                  controller: _nameController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Укажите название детали';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  label: 'Количество *',
                  hint: 'Введите количество',
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Укажите количество';
                    }
                    final parsed = int.tryParse(value.trim());
                    if (parsed == null || parsed <= 0) {
                      return 'Количество должно быть больше нуля';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _addPart,
                  icon: const Icon(Icons.add, color: AppColors.primary),
                  label: const Text('Добавить к списку', style: TextStyle(color: AppColors.primary)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_pendingParts.isNotEmpty) _PendingPartsList(parts: _pendingParts, onRemove: _removePart),
          if (_pendingParts.isNotEmpty) const SizedBox(height: 24),
          CustomButton(
            text: 'Сохранить изменения',
            onPressed: _isSubmitting ? null : _submit,
          ),
        ],
      ),
    );
  }

  void _addPart() {
    if (!_partFormKey.currentState!.validate()) {
      return;
    }

    final quantity = int.parse(_quantityController.text.trim());
    setState(() {
      _pendingParts.add(
        RequestedPartDto(
          catalogNumber: _catalogController.text.trim(),
          partName: _nameController.text.trim(),
          quantity: quantity,
        ),
      );
      _catalogController.clear();
      _nameController.clear();
      _quantityController.clear();
    });
  }

  void _removePart(int index) {
    setState(() {
      _pendingParts.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (order.requestId <= 0) {
      showSnack(context, 'Не удалось определить идентификатор заявки');
      return;
    }
    if (_pendingParts.isEmpty) {
      showSnack(context, 'Добавьте хотя бы одну деталь');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final updated = await handleApiCall(
        context,
        () => _repository.addPartsToRequest(order.requestId, _pendingParts),
        successMessage: 'Детали добавлены в заявку',
      );
      if (!mounted) return;
      if (updated != null) {
        Navigator.pop(context, updated);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.lightGray),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.lightGray),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}

class _OrderSummaryCard extends StatelessWidget {
  final MaintenanceRequestResponseDto order;

  const _OrderSummaryCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Заявка №${order.requestId}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            if (order.clubName != null && order.clubName!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(order.clubName!, style: const TextStyle(color: AppColors.darkGray)),
            ],
            if (order.laneNumber != null) ...[
              const SizedBox(height: 4),
              Text('Дорожка ${order.laneNumber}', style: const TextStyle(color: AppColors.darkGray)),
            ],
            if (order.status != null && order.status!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Статус: ${order.status}', style: const TextStyle(color: AppColors.darkGray)),
            ],
          ],
        ),
      ),
    );
  }
}

class _ExistingPartsList extends StatelessWidget {
  final MaintenanceRequestResponseDto order;

  const _ExistingPartsList({required this.order});

  @override
  Widget build(BuildContext context) {
    final parts = order.requestedParts;
    if (parts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: const Text('В заявке пока нет деталей', style: TextStyle(color: AppColors.darkGray)),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Текущий состав заявки',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark),
        ),
        const SizedBox(height: 12),
        ...parts.map(
          (part) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(part.partName ?? part.catalogNumber ?? 'Деталь', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark)),
                if (part.catalogNumber != null && part.catalogNumber!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Каталожный номер: ${part.catalogNumber}', style: const TextStyle(color: AppColors.darkGray)),
                  ),
                if (part.quantity != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Количество: ${part.quantity}', style: const TextStyle(color: AppColors.darkGray)),
                  ),
                if (part.status != null && part.status!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Статус: ${part.status}', style: const TextStyle(color: AppColors.darkGray)),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PendingPartsList extends StatelessWidget {
  final List<RequestedPartDto> parts;
  final void Function(int index) onRemove;

  const _PendingPartsList({required this.parts, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Добавляемые детали',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark),
        ),
        const SizedBox(height: 12),
        ...List.generate(parts.length, (index) {
          final part = parts[index];
          return Container(
            margin: EdgeInsets.only(bottom: index == parts.length - 1 ? 0 : 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(part.partName, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark)),
                      const SizedBox(height: 4),
                      Text('Каталожный номер: ${part.catalogNumber}', style: const TextStyle(color: AppColors.darkGray)),
                      const SizedBox(height: 4),
                      Text('Количество: ${part.quantity}', style: const TextStyle(color: AppColors.darkGray)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => onRemove(index),
                  icon: const Icon(Icons.delete_outline, color: AppColors.darkGray),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
