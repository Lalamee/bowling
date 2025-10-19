import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../shared/widgets/nav/app_bottom_nav.dart';
import '../../../../core/utils/bottom_nav.dart';
import '../../../../core/routing/routes.dart';
import 'order_summary_screen.dart';

class ManagerOrdersHistoryScreen extends StatefulWidget {
  const ManagerOrdersHistoryScreen({super.key});
  @override
  State<ManagerOrdersHistoryScreen> createState() => _ManagerOrdersHistoryScreenState();
}

class _ManagerOrdersHistoryScreenState extends State<ManagerOrdersHistoryScreen> {
  final List<_OrderRow> orders = const [
    _OrderRow(number: 'Заказ №25', hasIssue: true),
    _OrderRow(number: 'Заказ №26'),
    _OrderRow(number: 'Заказ №27'),
    _OrderRow(number: 'Заказ №28'),
  ];

  int? expanded;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: _CircleIcon(onTap: () => Navigator.pop(context), icon: Icons.arrow_back_ios_new_rounded),
        ),
        title: const Text('Заказы', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        centerTitle: false,
        actions: const [
          Padding(padding: EdgeInsets.only(right: 12), child: _SquareIcon(icon: Icons.info_outline)),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final item = orders[i];
                final isOpen = expanded == i;
                if (!isOpen) {
                  return _CollapsedRow(
                    title: item.number,
                    trailing: item.hasIssue
                        ? const _SquareBadge(icon: Icons.error_outline, color: AppColors.primary)
                        : const _SquareBadge(icon: Icons.check, color: AppColors.primary),
                    onTap: () => setState(() => expanded = i),
                  );
                }
                return _ExpandedCard(
                  number: item.number,
                  onCollapse: () => setState(() => expanded = null),
                  onConfirm: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => OrderSummaryScreen(orderNumber: item.number)),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              height: 48,
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pushNamed(context, Routes.clubOrdersHistory),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Посмотреть всю историю заказов', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 0,
        onTap: (i) => BottomNavDirect.go(context, 0, i),
      ),
    );
  }
}

class _CollapsedRow extends StatelessWidget {
  final String title;
  final Widget trailing;
  final VoidCallback onTap;

  const _CollapsedRow({required this.title, required this.trailing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Row(
        children: [
          Expanded(child: _FlatTile(height: 52, child: Text(title, style: const TextStyle(fontSize: 16, color: AppColors.textDark)))),
          const SizedBox(width: 8),
          const _SquareIcon(icon: Icons.keyboard_arrow_down_rounded),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }
}

class _ExpandedCard extends StatelessWidget {
  final String number;
  final VoidCallback onCollapse;
  final VoidCallback onConfirm;

  const _ExpandedCard({required this.number, required this.onCollapse, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))]),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _FlatTile(height: 52, child: Text(number, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark)))),
                const SizedBox(width: 8),
                _SquareButton(icon: Icons.keyboard_arrow_up_rounded, onTap: onCollapse),
                const SizedBox(width: 8),
                const _SquareBadge(icon: Icons.error_outline, color: AppColors.primary),
              ],
            ),
            const SizedBox(height: 12),
            const _DetailRow(name: 'Деталь №1', qty: '2 шт', withStatuses: true),
            const SizedBox(height: 8),
            const _DetailRow(name: 'Деталь №2', qty: '5 шт', withStatuses: true),
            const SizedBox(height: 8),
            const _DetailRow(name: 'Деталь №3', qty: '10 шт', withStatuses: true),
            const SizedBox(height: 8),
            const _DetailRow(name: 'Деталь №2', qty: '5 шт', withStatuses: true),
            const SizedBox(height: 14),
            Row(
              children: const [
                Expanded(child: _FilledPill(text: 'Принять в работу', color: AppColors.primary)),
                SizedBox(width: 10),
                Expanded(child: _FilledPill(text: 'Изменить', color: Color(0xFF666666))),
              ],
            ),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.upload_rounded, size: 16, color: AppColors.darkGray),
              const SizedBox(width: 6),
              TextButton(onPressed: () {}, child: const Text('Отправить себе на e-mail')),
            ]),
            const SizedBox(height: 6),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: onConfirm,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: const Text('Подтвердить заказ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String name;
  final String qty;
  final bool withStatuses;

  const _DetailRow({required this.name, required this.qty, this.withStatuses = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _FlatTile(height: 48, child: Text(name))),
            const SizedBox(width: 8),
            _FlatTile(width: 78, height: 48, child: Center(child: Text(qty))),
          ],
        ),
        if (withStatuses) ...[
          const SizedBox(height: 8),
          Row(
            children: const [
              Expanded(child: _StatusPill(text: 'Подтвердить', color: AppColors.primary)),
              SizedBox(width: 8),
              Expanded(child: _StatusPill(text: 'Нет в наличии', color: Color(0xFF7A7A7A))),
            ],
          ),
        ],
      ],
    );
  }
}

class _FlatTile extends StatelessWidget {
  final double? width;
  final double height;
  final Widget child;

  const _FlatTile({this.width, required this.height, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.lightGray)),
      child: child,
    );
  }
}

class _CircleIcon extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;

  const _CircleIcon({required this.onTap, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 40, height: 40, child: Icon(icon, size: 18, color: AppColors.textDark)),
      ),
    );
  }
}

class _SquareIcon extends StatelessWidget {
  final IconData icon;
  const _SquareIcon({required this.icon});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 3))]),
      child: Icon(icon, color: AppColors.darkGray),
    );
  }
}

class _SquareButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SquareButton({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 3))]),
        child: Icon(icon, color: AppColors.darkGray),
      ),
    );
  }
}

class _SquareBadge extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _SquareBadge({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.lightGray), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 3))]),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class _FilledPill extends StatelessWidget {
  final String text;
  final Color color;

  const _FilledPill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: EdgeInsets.zero, textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        child: Text(text),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusPill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
    );
  }
}

class _OrderRow {
  final String number;
  final bool hasIssue;
  const _OrderRow({required this.number, this.hasIssue = false});
}
