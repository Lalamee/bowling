import 'package:flutter/material.dart';

import '../../../../../core/repositories/user_repository.dart';
import '../../../../../core/services/authz/acl.dart';
import '../../../../../core/theme/colors.dart';
import '../../../../../core/theme/typography_extension.dart';
import '../../../../../models/maintenance_request_response_dto.dart';
import '../../domain/order_status.dart';
import '../widgets/order_status_badge.dart';

class OrderSummaryScreen extends StatefulWidget {
  final MaintenanceRequestResponseDto? order;
  final String? orderNumber;
  final bool canConfirm;
  final bool canComplete;
  final bool? initialAvailability;
  final Future<bool> Function({required Map<int, bool> availability, String? comment})? onConfirm;
  final Future<bool> Function()? onComplete;

  const OrderSummaryScreen({
    super.key,
    this.order,
    this.orderNumber,
    this.canConfirm = false,
    this.canComplete = false,
    this.initialAvailability,
    this.onConfirm,
    this.onComplete,
  });

  @override
  State<OrderSummaryScreen> createState() => _OrderSummaryScreenState();
}

class _OrderSummaryScreenState extends State<OrderSummaryScreen> {
  final _userRepository = UserRepository();
  bool _isSubmitting = false;
  bool _isCompleting = false;
  late final TextEditingController _commentController;
  bool _accessCheckInProgress = true;
  bool _accessDenied = false;
  final Map<int, bool> _availabilityDecisions = {};

  String get _title {
    if (widget.orderNumber != null && widget.orderNumber!.isNotEmpty) return widget.orderNumber!;
    if (widget.order != null) {
      return 'Заявка №${widget.order!.requestId}';
    }
    return 'Заказ';
  }

  MaintenanceRequestResponseDto? get _request => widget.order;

  List<int> get _partIds {
    final request = _request;
    if (request == null) return const [];
    return request.requestedParts.map((part) => part.partId).toList();
  }

  void _prefillAvailability() {
    final request = _request;
    if (request != null) {
      for (final part in request.requestedParts) {
        final decision = part.available;
        if (decision != null) {
          _availabilityDecisions[part.partId] = decision;
        }
      }
      if (_availabilityDecisions.isEmpty && widget.initialAvailability != null) {
        for (final part in request.requestedParts) {
          _availabilityDecisions[part.partId] = widget.initialAvailability!;
        }
      }
    }
  }

  bool? _decisionForPart(int partId) => _availabilityDecisions[partId];

  bool get _allDecisionsMade {
    if (!widget.canConfirm) return true;
    final ids = _partIds;
    if (ids.isEmpty) return true;
    return ids.every(_availabilityDecisions.containsKey);
  }

  String _availabilityLabel(bool? value) {
    if (value == null) return 'не указано';
    return value ? 'есть в наличии' : 'нет в наличии';
  }

  void _setDecisionForPart(int partId, bool value) {
    setState(() {
      _availabilityDecisions[partId] = value;
    });
  }

  void _applyBulkDecision(bool value) {
    final ids = _partIds;
    if (ids.isEmpty) return;
    setState(() {
      for (final id in ids) {
        _availabilityDecisions[id] = value;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController();
    _prefillAvailability();
    _guardAccess();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.typo;
    final request = _request;
    final orderStatus = request != null ? mapOrderStatus(request.status) : OrderStatusCategory.pending;

    if (_accessCheckInProgress) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_accessDenied) {
      return Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          title: Text(_title, style: t.sectionTitle),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 56, color: AppColors.darkGray),
                const SizedBox(height: 16),
                const Text(
                  'У вас нет доступа к этой заявке',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.darkGray, fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Вернуться'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(_title, style: t.sectionTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Text('Сводка', style: t.mainWelcomeTitle.copyWith(fontSize: 24))),
                      OrderStatusBadge(category: orderStatus),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (request != null && request.clubName != null)
                    Text(request.clubName!, style: t.formInput),
                  if (request != null && request.laneNumber != null) ...[
                    const SizedBox(height: 4),
                    Text('Дорожка ${request.laneNumber}', style: t.formInput),
                  ],
                  if (request != null && request.status != null) ...[
                    const SizedBox(height: 4),
                    Text('Текущий статус: ${describeOrderStatus(request.status)}', style: t.formInput),
                  ],
                  if (request != null && request.managerNotes != null && request.managerNotes!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text('Заметки менеджера', style: t.formLabel),
                    const SizedBox(height: 4),
                    Text(request.managerNotes!, style: t.formInput),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Детали заказа', style: t.sectionTitle),
          const SizedBox(height: 12),
          if (request == null || request.requestedParts.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: const Text('Нет деталей', style: TextStyle(color: AppColors.darkGray)),
            )
          else
            ...request.requestedParts.map(
              (part) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      part.partName ?? part.catalogNumber ?? 'Неизвестная деталь',
                      style: t.formLabel,
                    ),
                    if (part.catalogNumber != null && part.catalogNumber!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('Каталожный номер: ${part.catalogNumber}', style: t.formInput),
                      ),
                    if (part.inventoryLocation != null && part.inventoryLocation!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('Локация: ${part.inventoryLocation}', style: t.formInput),
                      ),
                    if (part.quantity != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('Количество: ${part.quantity}', style: t.formInput),
                      ),
                    if (part.status != null && part.status!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('Статус: ${describeOrderStatus(part.status)}', style: t.formInput),
                      ),
                    if (widget.canConfirm && widget.onConfirm != null) ...[
                      const SizedBox(height: 12),
                      Text('Наличие детали', style: t.formLabel),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Есть в наличии'),
                            selected: _decisionForPart(part.partId) == true,
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: _decisionForPart(part.partId) == true
                                  ? Colors.white
                                  : AppColors.textDark,
                            ),
                            onSelected: (_) => _setDecisionForPart(part.partId, true),
                          ),
                          ChoiceChip(
                            label: const Text('Нет в наличии'),
                            selected: _decisionForPart(part.partId) == false,
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: _decisionForPart(part.partId) == false
                                  ? Colors.white
                                  : AppColors.textDark,
                            ),
                            onSelected: (_) => _setDecisionForPart(part.partId, false),
                          ),
                        ],
                      ),
                    ] else ...[
                      const SizedBox(height: 12),
                      Text('Наличие: ${_availabilityLabel(part.available)}', style: t.formInput),
                    ],
                    if (part.rejectionReason != null && part.rejectionReason!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('Причина отказа: ${part.rejectionReason}', style: t.formInput),
                      ),
                    if (part.orderDate != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('Заказано: ${_formatDate(part.orderDate!)}', style: t.formInput),
                      ),
                    if (part.deliveryDate != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('Доставка: ${_formatDate(part.deliveryDate!)}', style: t.formInput),
                      ),
                    if (part.issueDate != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('Выдача: ${_formatDate(part.issueDate!)}', style: t.formInput),
                      ),
                  ],
                ),
              ),
            ),
          if (widget.canConfirm && widget.onConfirm != null) ...[
            const SizedBox(height: 24),
            Text('Подтверждение заказа', style: t.sectionTitle),
            const SizedBox(height: 12),
            if (_partIds.isNotEmpty) ...[
              Text('Отметьте наличие для каждой детали', style: t.formLabel),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _applyBulkDecision(true),
                    icon: const Icon(Icons.check_circle_outline, color: AppColors.primary),
                    label: const Text('Все есть в наличии'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _applyBulkDecision(false),
                    icon: const Icon(Icons.remove_circle_outline, color: AppColors.primary),
                    label: const Text('Ничего нет в наличии'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Комментарий для механика',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: (!_allDecisionsMade || _isSubmitting || _isCompleting)
                    ? null
                    : () => _handleConfirm(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Подтвердить заказ'),
              ),
            ),
          ],
          if (widget.canComplete && widget.onComplete != null) ...[
            const SizedBox(height: 24),
            Text('Завершение заказа', style: t.sectionTitle),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: (_isSubmitting || _isCompleting)
                    ? null
                    : () => _handleComplete(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isCompleting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Завершить заказ'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _guardAccess() async {
    final order = widget.order;
    if (order == null) {
      setState(() {
        _accessCheckInProgress = false;
      });
      return;
    }

    try {
      final me = await _userRepository.me();
      final scope = await UserAccessScope.fromProfile(me);
      final allowed = scope.canViewOrder(order);
      if (!mounted) return;
      setState(() {
        _accessDenied = !allowed;
        _accessCheckInProgress = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _accessDenied = true;
        _accessCheckInProgress = false;
      });
    }
  }

  Future<void> _handleComplete() async {
    if (widget.onComplete == null) return;
    setState(() => _isCompleting = true);
    final success = await widget.onComplete!.call();
    if (!mounted) return;
    setState(() => _isCompleting = false);
    if (success) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _handleConfirm() async {
    if (widget.onConfirm == null || !_allDecisionsMade) return;
    setState(() => _isSubmitting = true);
    final comment = _commentController.text.trim();
    final success = await widget.onConfirm!(
      availability: Map<int, bool>.from(_availabilityDecisions),
      comment: comment.isEmpty ? null : comment,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (success) {
      Navigator.pop(context, true);
    }
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
