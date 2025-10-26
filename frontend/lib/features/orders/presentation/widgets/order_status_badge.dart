import 'package:flutter/material.dart';

import '../../../../core/theme/colors.dart';
import '../../domain/order_status.dart';

class OrderStatusBadge extends StatelessWidget {
  final OrderStatusCategory category;
  final EdgeInsetsGeometry padding;

  const OrderStatusBadge({
    super.key,
    required this.category,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  });

  factory OrderStatusBadge.fromRaw(String? rawStatus, {Key? key}) {
    return OrderStatusBadge(
      key: key,
      category: mapOrderStatus(rawStatus),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = _palette(category);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        orderStatusLabel(category),
        style: TextStyle(
          color: palette.text,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  _StatusPalette _palette(OrderStatusCategory category) {
    switch (category) {
      case OrderStatusCategory.confirmed:
        return const _StatusPalette(
          background: Color(0xFFE6F5ED),
          text: Color(0xFF1B7345),
        );
      case OrderStatusCategory.archived:
        return const _StatusPalette(
          background: Color(0xFFF4F4F6),
          text: AppColors.darkGray,
        );
      case OrderStatusCategory.pending:
      default:
        return const _StatusPalette(
          background: Color(0xFFFFF5E5),
          text: Color(0xFFAD6200),
        );
    }
  }
}

class _StatusPalette {
  final Color background;
  final Color text;

  const _StatusPalette({required this.background, required this.text});
}
