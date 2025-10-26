import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/repositories/inventory_repository.dart';
import '../../../../core/repositories/maintenance_repository.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/net_ui.dart';
import '../../../../models/maintenance_request_response_dto.dart';
import '../../../../models/part_request_dto.dart';
import '../../../../models/part_dto.dart';
import '../../../../shared/widgets/buttons/custom_button.dart';

class AddPartsToOrderScreen extends StatefulWidget {
  final MaintenanceRequestResponseDto order;

  const AddPartsToOrderScreen({super.key, required this.order});

  @override
  State<AddPartsToOrderScreen> createState() => _AddPartsToOrderScreenState();
}

class _AddPartsToOrderScreenState extends State<AddPartsToOrderScreen> {
  final _partNameController = TextEditingController();
  final _catalogController = TextEditingController();
  final _quantityController = TextEditingController();
  final _partFormKey = GlobalKey<FormState>();
  final _repository = MaintenanceRepository();
  final _inventoryRepository = InventoryRepository();

  final List<RequestedPartDto> _pendingParts = [];
  bool _isSubmitting = false;
  bool _isSearchingParts = false;
  List<PartDto> _partSuggestions = const [];
  PartDto? _selectedCatalogPart;
  Timer? _partsSearchDebounce;

  MaintenanceRequestResponseDto get order => widget.order;

  @override
  void dispose() {
    _catalogController.dispose();
    _partNameController.dispose();
    _quantityController.dispose();
    _partsSearchDebounce?.cancel();
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
                _buildPartNameSelector(),
                const SizedBox(height: 16),
                _buildTextField(
                  label: 'Каталожный номер',
                  hint: 'Будет заполнен автоматически',
                  controller: _catalogController,
                  readOnly: true,
                  validator: (value) {
                    if (_pendingParts.isNotEmpty) {
                      return null;
                    }
                    if (_selectedCatalogPart == null) {
                      return 'Выберите запчасть из каталога';
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

    final selected = _selectedCatalogPart;
    if (selected == null) {
      showSnack(context, 'Выберите запчасть из каталога');
      return;
    }

    final quantity = int.tryParse(_quantityController.text.trim());
    if (quantity == null || quantity <= 0) {
      showSnack(context, 'Количество должно быть больше нуля');
      return;
    }

    final available = selected.quantity;
    final alreadyRequested = _pendingParts
        .where((item) => item.inventoryId == selected.inventoryId)
        .fold<int>(0, (sum, item) => sum + item.quantity);
    final totalRequested = alreadyRequested + quantity;
    final shortage = available != null && totalRequested > available;

    setState(() {
      final existingIndex = _pendingParts.indexWhere((item) => item.inventoryId == selected.inventoryId);
      if (existingIndex >= 0) {
        final existing = _pendingParts[existingIndex];
        _pendingParts[existingIndex] = RequestedPartDto(
          inventoryId: existing.inventoryId,
          catalogId: existing.catalogId,
          catalogNumber: existing.catalogNumber,
          partName: existing.partName,
          quantity: totalRequested,
          warehouseId: existing.warehouseId,
          location: existing.location,
        );
      } else {
        _pendingParts.add(
          RequestedPartDto(
            inventoryId: selected.inventoryId,
            catalogId: selected.catalogId,
            catalogNumber: _resolveCatalogNumber(selected),
            partName: _resolvePartDisplayName(selected),
            quantity: quantity,
            warehouseId: selected.warehouseId ?? order.clubId,
            location: selected.location,
          ),
        );
      }

      _partNameController.clear();
      _catalogController.clear();
      _quantityController.clear();
      _selectedCatalogPart = null;
      _partSuggestions = const [];
    });

    if (shortage) {
      final availableText = available ?? 0;
      showSnack(context, 'На складе доступно только $availableText шт. Заявка отправлена на пополнение.');
    }
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
    bool readOnly = false,
    void Function(String)? onChanged,
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
          readOnly: readOnly,
          validator: validator,
          onChanged: onChanged,
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

  Widget _buildPartNameSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Название детали *',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _partNameController,
          decoration: InputDecoration(
            hintText: 'Начните вводить название запчасти',
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
          validator: (value) {
            if (_pendingParts.isNotEmpty) {
              return null;
            }
            if (_selectedCatalogPart == null) {
              return 'Выберите запчасть из каталога';
            }
            return null;
          },
          onChanged: _onPartNameChanged,
        ),
        if (_isSearchingParts)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        if (_partSuggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.lightGray),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final part = _partSuggestions[index];
                final quantity = part.quantity;
                final subtitleBuffer = StringBuffer(part.catalogNumber);
                if (quantity != null) {
                  subtitleBuffer.write(' · Остаток: $quantity');
                }
                if (part.location != null && part.location!.trim().isNotEmpty) {
                  subtitleBuffer.write(' · ${part.location!.trim()}');
                }
                return ListTile(
                  leading: const Icon(Icons.settings_suggest_rounded, color: AppColors.primary),
                  title: Text(_resolvePartDisplayName(part)),
                  subtitle: Text(subtitleBuffer.toString()),
                  onTap: () => _selectSuggestedPart(part),
                );
              },
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemCount: _partSuggestions.length,
            ),
          ),
      ],
    );
  }

  void _onPartNameChanged(String value) {
    _partsSearchDebounce?.cancel();
    _selectedCatalogPart = null;
    _catalogController.clear();
    final trimmed = value.trim();
    if (trimmed.length < 2) {
      setState(() {
        _partSuggestions = const [];
        _isSearchingParts = false;
      });
      return;
    }
    _partsSearchDebounce = Timer(const Duration(milliseconds: 350), () {
      _searchParts(trimmed);
    });
  }

  Future<void> _searchParts(String query) async {
    setState(() {
      _isSearchingParts = true;
    });
    try {
      final results = await _inventoryRepository.search(
        query,
        clubId: order.clubId,
      );
      if (!mounted) return;
      setState(() {
        _partSuggestions = results.take(10).toList();
        _isSearchingParts = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _partSuggestions = const [];
        _isSearchingParts = false;
      });
    }
  }

  void _selectSuggestedPart(PartDto part) {
    _partsSearchDebounce?.cancel();
    setState(() {
      _selectedCatalogPart = part;
      _partNameController.text = _resolvePartDisplayName(part);
      _catalogController.text = _resolveCatalogNumber(part);
      _partSuggestions = const [];
    });
  }

  String _resolvePartDisplayName(PartDto part) {
    final candidates = [part.commonName, part.officialNameRu, part.officialNameEn];
    for (final candidate in candidates) {
      if (candidate != null && candidate.trim().isNotEmpty) {
        return candidate.trim();
      }
    }
    return part.catalogNumber;
  }

  String _resolveCatalogNumber(PartDto part) {
    final candidate = part.catalogNumber.trim();
    if (candidate.isNotEmpty) {
      return candidate;
    }
    return part.catalogId.toString();
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
                if (part.inventoryLocation != null && part.inventoryLocation!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Локация: ${part.inventoryLocation}', style: const TextStyle(color: AppColors.darkGray)),
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
                      if (part.location != null && part.location!.isNotEmpty) ...[
                        Text('Локация: ${part.location}', style: const TextStyle(color: AppColors.darkGray)),
                        const SizedBox(height: 4),
                      ],
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
