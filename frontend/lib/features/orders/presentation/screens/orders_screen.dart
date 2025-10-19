import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../shared/widgets/buttons/custom_button.dart';
import '../widgets/flat_tile.dart';
import '../../../../shared/widgets/buttons/icon_square_button.dart';
import '../../../../shared/widgets/buttons/mini_add_button.dart';
import '../dialogs/quantity_dialog.dart';
import '../../../../shared/sheets/order_info_sheet.dart';
import '../dialogs/confirm_order_dialog.dart';
import '../../domain/order_item.dart';
import '../../../../shared/widgets/nav/app_bottom_nav.dart';
import '../../../../core/utils/bottom_nav.dart';
import 'order_summary_screen.dart';


class OrdersScreen extends StatefulWidget {
  const OrdersScreen({Key? key}) : super(key: key);
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final lanes = ['Дорожка 1', 'Дорожка 2', 'Дорожка 3'];
  String lane = 'Дорожка 1';
  final List<OrderItem> items = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Заказы', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                  ),
                  IconSquareButton(
                    icon: Icons.add,
                    onTap: () async {
                      await showDialog(context: context, builder: (_) => const ConfirmOrderDialog());
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Expanded(child: _laneDropdown()),
                  const SizedBox(width: 12),
                  IconSquareButton(
                    icon: Icons.help_outline,
                    onTap: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
                      builder: (_) => const OrderInfoSheet(),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const FlatTile(label: 'Оборудование 1'),
                  const SizedBox(height: 12),
                  const FlatTile(label: 'Модуль 2', trailing: Icons.expand_more),
                  const SizedBox(height: 12),
                  const FlatTile(label: 'Модуль 3', trailing: Icons.expand_more),
                  const SizedBox(height: 12),
                  const FlatTile(label: 'Модуль 4', trailing: Icons.expand_more),
                  const SizedBox(height: 12),
                  Stack(
                    alignment: Alignment.centerRight,
                    children: [
                      const FlatTile(label: 'Модуль 5', trailing: Icons.expand_more),
                      Positioned(right: 10, child: MiniAddButton(onTap: _openQuantity)),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Column(
                children: [
                  CustomButton(text: 'Добавить деталь в заказ', onPressed: _openQuantity),
                  const SizedBox(height: 12),
                  CustomButton(
                    text: 'Посмотреть заказ',
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => OrderSummaryScreen(orderNumber: 'Заказ №25', initialItems: items)),
                      );
                      setState(() {});
                    },
                    isOutlined: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 0,
        onTap: (i) => BottomNavDirect.go(context, 0, i),
      ),
    );
  }

  Widget _laneDropdown() {
    return Container(
      height: 48,
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.lightGray)),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: lane,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.darkGray),
          items: lanes.map((e) => DropdownMenuItem<String>(value: e, child: Text(e, style: const TextStyle(color: AppColors.textDark)))).toList(),
          onChanged: (v) => setState(() => lane = v ?? lane),
        ),
      ),
    );
  }

  void _openQuantity() async {
    final qty = await showDialog<int>(context: context, builder: (_) => const QuantityDialog());
    if (qty != null) {
      setState(() => items.add(OrderItem(title: 'Деталь №${items.length + 1}', qty: qty)));
    }
  }
}
