import 'package:flutter/material.dart';

import '../../../../../core/theme/colors.dart';
import '../../../../../core/theme/typography_extension.dart';
import '../../../../../models/maintenance_request_response_dto.dart';

class OrderSummaryScreen extends StatelessWidget {
  final MaintenanceRequestResponseDto? order;
  final String? orderNumber;

  const OrderSummaryScreen({
    super.key,
    this.order,
    this.orderNumber,
  });

  String get _title {
    if (orderNumber != null && orderNumber!.isNotEmpty) return orderNumber!;
    if (order != null) {
      return 'Заявка №${order!.requestId}';
    }
    return 'Заказ';
  }

  @override
  Widget build(BuildContext context) {
    final t = context.typo;
    final request = order;

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
                  Text('Сводка', style: t.mainWelcomeTitle.copyWith(fontSize: 24)),
                  const SizedBox(height: 8),
                  if (request != null && request.clubName != null)
                    Text(request.clubName!, style: t.formInput),
                  if (request != null && request.laneNumber != null) ...[
                    const SizedBox(height: 4),
                    Text('Дорожка ${request.laneNumber}', style: t.formInput),
                  ],
                  if (request != null && request.status != null) ...[
                    const SizedBox(height: 4),
                    Text('Статус: ${_statusName(request.status!)}', style: t.formInput),
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
        ],
      ),
    );
  }

  static String _statusName(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return 'Одобрено';
      case 'REJECTED':
        return 'Отклонено';
      case 'IN_PROGRESS':
        return 'В работе';
      case 'COMPLETED':
        return 'Завершено';
      default:
        return status;
    }
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
