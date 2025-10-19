import 'package:flutter/material.dart';
import '../../../../../core/theme/colors.dart';

class ManagerNotificationsScreen extends StatelessWidget {
  const ManagerNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _Notif(title: 'Новый заказ №25', highlighted: true),
      _Notif(title: 'Новый заказ №24'),
      _Notif(title: 'Новый заказ №23'),
      _Notif(title: 'Новый заказ №22'),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark), onPressed: () => Navigator.pop(context)),
        title: const Text('Оповещения', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        centerTitle: false,
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.sync), color: AppColors.primary)],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final n = items[i];
          return Container(
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14),
              border: n.highlighted ? Border.all(color: AppColors.primary) : Border.all(color: AppColors.lightGray),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                const SizedBox(width: 14),
                Expanded(child: Text(n.title, style: const TextStyle(fontSize: 16, color: AppColors.textDark))),
                const SizedBox(width: 14),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Notif {
  final String title;
  final bool highlighted;
  const _Notif({required this.title, this.highlighted = false});
}
