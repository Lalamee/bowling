import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../shared/widgets/nav/app_bottom_nav.dart';
import '../../../../shared/widgets/layout/section_list.dart';
import '../../../../shared/widgets/buttons/custom_button.dart';
import '../../../../shared/widgets/layout/common_ui.dart';
import '../../../../core/utils/bottom_nav.dart';
import 'club_warehouse_screen.dart';

class ClubScreen extends StatefulWidget {
  const ClubScreen({Key? key}) : super(key: key);

  @override
  State<ClubScreen> createState() => _ClubScreenState();
}

class _ClubScreenState extends State<ClubScreen> {
  int _sectionIndex = -1;

  void _onSelect(int i) {
    setState(() => _sectionIndex = i);
    if (i == 1) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ClubWarehouseScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            CommonUI.card(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: const [
                  Text('Клуб', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                  Spacer(),
                  Icon(Icons.sync, color: AppColors.primary),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SectionList(
              items: const ['Оборудование', 'Склад', 'Модуль 2', 'Модуль 3', 'Модуль 4', 'Модуль 5'],
              selected: _sectionIndex,
              onSelect: _onSelect,
            ),
            const SizedBox(height: 16),
            Center(child: CustomButton(text: 'Добавить деталь в заказ', onPressed: () {})),
            const SizedBox(height: 12),
            Center(child: CustomButton(text: 'Посмотреть заказ', isOutlined: true, onPressed: () {})),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 2,
        onTap: (i) => BottomNavDirect.go(context, 2, i),
      ),
    );
  }
}
