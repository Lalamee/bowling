import '../../../../../core/repositories/user_repository.dart';
import 'package:flutter/material.dart';
import '../../../../../core/theme/colors.dart';
import '../../../../../shared/widgets/tiles/profile_tile.dart';
import '../../../../knowledge_base/presentation/screens/knowledge_base_screen.dart';
import '../../../../../shared/widgets/nav/app_bottom_nav.dart';
import '../../../../../core/utils/bottom_nav.dart';
import '../../../../../core/routing/routes.dart';

class ManagerProfileScreen extends StatefulWidget {
  const ManagerProfileScreen({Key? key}) : super(key: key);

  @override
  State<ManagerProfileScreen> createState() => _ManagerProfileScreenState();
}

class _ManagerProfileScreenState extends State<ManagerProfileScreen> {
  final UserRepository _repo = UserRepository();
  String fullName = 'Менеджер Иван Иванович';
  String phone = '+7 (980) 001 01 01';
  String email = '';
  String clubName = 'Боулинг клуб "Кегли"';
  String address = 'г. Воронеж, ул. Тверская, д. 45';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final me = await _repo.me();
    if (mounted) {
      setState(() {
        fullName = (me?['fullName'] ?? me?['phone'] ?? 'Профиль').toString();
        phone = (me?['phone'] ?? '—').toString();
        email = (me?['email'] ?? '').toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Личный кабинет', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textDark)),
        centerTitle: false,
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.sync), color: AppColors.primary)],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          ProfileTile(icon: Icons.person, text: fullName, onEdit: () {}),
          const SizedBox(height: 10),
          ProfileTile(icon: Icons.phone, text: phone, onEdit: () {}),
          const SizedBox(height: 10),
          ProfileTile(icon: Icons.menu_book_rounded, text: 'База знаний', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KnowledgeBaseScreen()))),
          const SizedBox(height: 10),
          ProfileTile(icon: Icons.location_searching_rounded, text: clubName, onTap: () {}),
          const SizedBox(height: 10),
          ProfileTile(icon: Icons.location_on_rounded, text: address, onEdit: () {}),
          const SizedBox(height: 10),
          ProfileTile(icon: Icons.history_rounded, text: 'История заказов', onTap: () => Navigator.pushNamed(context, Routes.managerOrdersHistory)),
          const SizedBox(height: 10),
          ProfileTile(icon: Icons.notifications_active_outlined, text: 'Оповещения', onTap: () => Navigator.pushNamed(context, Routes.managerNotifications)),
          const SizedBox(height: 10),
          ProfileTile(icon: Icons.exit_to_app_rounded, text: 'Выход', danger: true, onTap: () {}),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 3,
        onTap: (i) => BottomNavDirect.go(context, 3, i),
      ),
    );
  }
}
