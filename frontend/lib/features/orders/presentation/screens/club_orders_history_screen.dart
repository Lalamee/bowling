import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';

class ClubOrdersHistoryScreen extends StatefulWidget {
  const ClubOrdersHistoryScreen({super.key});
  @override
  State<ClubOrdersHistoryScreen> createState() => _ClubOrdersHistoryScreenState();
}

class _ClubOrdersHistoryScreenState extends State<ClubOrdersHistoryScreen> {
  final List<_Order> orders = const [
    _Order('Заказ №25', true),
    _Order('Заказ №26', false),
    _Order('Заказ №27', false),
    _Order('Заказ №28', false),
  ];

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
          child: Material(
            color: Colors.white,
            shape: const CircleBorder(),
            elevation: 2,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.pop(context),
              child: const SizedBox(width: 40, height: 40, child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textDark)),
            ),
          ),
        ),
        title: const Text('Все заказы клуба', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        centerTitle: false,
        actions: const [
          Padding(padding: EdgeInsets.only(right: 12), child: _SquareIcon(icon: Icons.info_outline)),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        itemCount: orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final o = orders[i];
          return Row(
            children: [
              Expanded(child: _FlatTile(height: 52, child: Text(o.title, style: const TextStyle(fontSize: 16, color: AppColors.textDark)))),
              const SizedBox(width: 8),
              const _SquareIcon(icon: Icons.keyboard_arrow_down_rounded),
              const SizedBox(width: 8),
              _SquareBadge(icon: o.hasIssue ? Icons.error_outline : Icons.check, color: AppColors.primary),
            ],
          );
        },
      ),
    );
  }
}

class _Order {
  final String title;
  final bool hasIssue;
  const _Order(this.title, this.hasIssue);
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
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.lightGray), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))]),
      child: child,
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
