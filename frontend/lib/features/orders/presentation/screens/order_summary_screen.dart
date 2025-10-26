import 'package:flutter/material.dart';

import '../../../../../core/theme/colors.dart';
import '../../../../../core/theme/typography_extension.dart';
import '../../../../../models/maintenance_request_response_dto.dart';
import '../../domain/order_status.dart';
import '../widgets/order_status_badge.dart';

class OrderSummaryScreen extends StatefulWidget {
  final MaintenanceRequestResponseDto? order;
  final String? orderNumber;
  final bool canConfirm;
  final bool? initialAvailability;
  final Future<bool> Function({required bool partsAvailable, String? comment})? onConfirm;

  const OrderSummaryScreen({
    super.key,
    this.order,
    this.orderNumber,
    this.canConfirm = false,
    this.initialAvailability,
    this.onConfirm,
  });

  @override
  State<OrderSummaryScreen> createState() => _OrderSummaryScreenState();
}

class _OrderSummaryScreenState extends State<OrderSummaryScreen> {
  bool? _partsAvailable;
  bool _isSubmitting = false;
  late final TextEditingController _commentController;

  String get _title {
    if (widget.orderNumber != null && widget.orderNumber!.isNotEmpty) return widget.orderNumber!;
    if (widget.order != null) {
      return 'Заявка №${widget.order!.requestId}';
    }
    return 'Заказ';
  }

  MaintenanceRequestResponseDto? get _request => widget.order;

  @override
  void initState() {
    super.initState();
    _partsAvailable = widget.initialAvailability;
    _commentController = TextEditingController();
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

    return Scaffold(
      appBar: AppBar(
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
                    Text('Текущий статус: ${_statusName(request.status!)}', style: t.formInput),
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
                    if (part.quantity != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('Количество: ${part.quantity}', style: t.formInput),
                      ),
                    if (part.status != null && part.status!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('Статус: ${_statusName(part.status!)}', style: t.formInput),
                      ),
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
            Text('Отметьте наличие деталей', style: t.formLabel),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              children: [
                ChoiceChip(
                  label: const Text('Есть в наличии'),
                  selected: _partsAvailable == true,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(color: _partsAvailable == true ? Colors.white : AppColors.textDark),
                  onSelected: (_) => setState(() => _partsAvailable = true),
                ),
                ChoiceChip(
                  label: const Text('Нет в наличии'),
                  selected: _partsAvailable == false,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(color: _partsAvailable == false ? Colors.white : AppColors.textDark),
                  onSelected: (_) => setState(() => _partsAvailable = false),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
                onPressed: (_partsAvailable == null || _isSubmitting)
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
        ],
      ),
    );
  }

  Future<void> _handleConfirm() async {
    if (widget.onConfirm == null || _partsAvailable == null) return;
    setState(() => _isSubmitting = true);
    final comment = _commentController.text.trim();
    final success = await widget.onConfirm!(
      partsAvailable: _partsAvailable!,
      comment: comment.isEmpty ? null : comment,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (success) {
      Navigator.pop(context, true);
    }
  }

  static String _statusName(String status) {
    switch (status.toUpperCase()) {
      case 'NEW':
        return 'Новая заявка';
      case 'APPROVED':
        return 'Одобрено';
      case 'REJECTED':
        return 'Отклонено';
      case 'IN_PROGRESS':
        return 'В работе';
      case 'DONE':
        return 'Выполнено';
      case 'COMPLETED':
        return 'Завершено';
      case 'CLOSED':
        return 'Закрыто';
      case 'UNREPAIRABLE':
        return 'Неремонтопригодно';
      default:
        return status;
    }
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
