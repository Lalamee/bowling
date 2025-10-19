import 'package:flutter/material.dart';
import '../../../../../core/theme/colors.dart';
import '../../../../../core/routing/routes.dart';

class AdminClubsScreen extends StatefulWidget {
  const AdminClubsScreen({super.key});
  @override
  State<AdminClubsScreen> createState() => _AdminClubsScreenState();
}

class _AdminClubsScreenState extends State<AdminClubsScreen> {
  final clubs = const ['Боулинг клуб "Адреналин"', 'Боулинг клуб "Кегли"', 'Боулинг клуб "Шары"'];
  int? open;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark), onPressed: () => Navigator.pop(context)),
        title: const Text('Боулинг клубы', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textDark)),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        itemCount: clubs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final isOpen = open == i;
          if (!isOpen) {
            return _clubRow(clubs[i], onTap: () => setState(() => open = i));
          }
          return _clubCard(
            title: clubs[i],
            onCollapse: () => setState(() => open = null),
            onGoHistory: () => Navigator.pushNamed(context, Routes.adminOrders),
          );
        },
      ),
    );
  }

  Widget _clubRow(String title, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        height: 56,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.lightGray), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 3))]),
        child: Row(children: [
          Expanded(child: Text(title, style: const TextStyle(fontSize: 16, color: AppColors.textDark))),
          const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.darkGray),
        ]),
      ),
    );
  }

  Widget _clubCard({required String title, required VoidCallback onCollapse, required VoidCallback onGoHistory}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.primary), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))]),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(children: [
        Row(children: [
          Expanded(child: Container(height: 52, alignment: Alignment.centerLeft, padding: const EdgeInsets.symmetric(horizontal: 14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.lightGray)), child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark)))),
          const SizedBox(width: 8),
          _squareButton(Icons.keyboard_arrow_up_rounded, onTap: onCollapse),
        ]),
        const SizedBox(height: 12),
        _infoTile(Icons.person, 'Собственник ФИО'),
        const SizedBox(height: 10),
        _infoTile(Icons.phone, '+7 (980) 001 01 01'),
        const SizedBox(height: 10),
        _infoTile(Icons.assignment_ind_outlined, 'ИНН: 360 8954 3354'),
        const SizedBox(height: 10),
        _infoTile(Icons.house_outlined, 'Название клуба'),
        const SizedBox(height: 10),
        _infoTile(Icons.place_outlined, 'Адрес клуба'),
        const SizedBox(height: 10),
        _infoTile(Icons.engineering_outlined, 'Иванов Иван Иванович (механик)'),
        const SizedBox(height: 16),
        SizedBox(
          height: 54,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onGoHistory,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: const Text('Перейти в историю заказов клуба', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }

  Widget _infoTile(IconData icon, String text) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.lightGray)),
      child: Row(children: [
        Container(width: 34, height: 34, alignment: Alignment.center, decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 18, color: AppColors.primary)),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
      ]),
    );
  }

  Widget _squareButton(IconData icon, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(width: 40, height: 40, alignment: Alignment.center, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 3))]), child: Icon(icon, color: AppColors.darkGray)),
    );
  }
}
