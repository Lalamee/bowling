import 'package:flutter/material.dart';
import '../../../../../core/theme/colors.dart';
import '../../../../../core/theme/typography_extension.dart';

class OrderSummaryScreen extends StatelessWidget {
  final String? orderId;
  final String? orderNumber;
  final dynamic order;
  final dynamic initialItems;

  const OrderSummaryScreen({
    super.key,
    this.orderId,
    this.orderNumber,
    this.order,
    this.initialItems,
  });

  String get _resolvedTitle {
    if (orderNumber != null && orderNumber!.isNotEmpty) return orderNumber!;
    if (orderId != null && orderId!.isNotEmpty) return 'Заказ $orderId';
    try {
      final dynamic idVal = order?.id;
      if (idVal is String && idVal.isNotEmpty) return 'Заказ $idVal';
    } catch (_) {}
    return 'Заказ';
  }

  int? get _itemsCount {
    if (initialItems is List) return (initialItems as List).length;
    try {
      final dynamic items = order?.items;
      if (items is List) return items.length;
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.typo;
    final titleText = _resolvedTitle;
    final count = _itemsCount;

    return Scaffold(
      appBar: AppBar(
        title: Text(titleText, style: t.sectionTitle),
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
                  Text(
                    'Товары, количество, суммы и статус заказа.',
                    style: t.onboardingSubtitle.copyWith(fontSize: 14),
                  ),
                  if (count != null) ...[
                    const SizedBox(height: 8),
                    Text('Позиции: $count', style: t.formInput),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.assignment_turned_in, color: AppColors.primary),
            title: Text('Статус', style: t.formLabel),
            subtitle: Text('Ожидает подтверждения', style: t.formInput),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.payments, color: AppColors.primary),
            title: Text('Итого', style: t.formLabel),
            subtitle: Text('—', style: t.formInput),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              child: const Text('Подтвердить'),
            ),
          ),
        ],
      ),
    );
  }
}
