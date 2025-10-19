import '../../../../../core/repositories/user_repository.dart';
import 'package:flutter/material.dart';
import '../../../../../core/theme/colors.dart';
import '../../../../../shared/widgets/tiles/profile_tile.dart';
import '../../domain/mechanic_profile.dart';
import 'edit_mechanic_profile_screen.dart';
import '../../../../../shared/widgets/nav/app_bottom_nav.dart';
import '../../../../../core/utils/bottom_nav.dart';
import '../../../../knowledge_base/presentation/screens/knowledge_base_screen.dart';
import '../../../../../core/routing/routes.dart';

enum EditFocus { none, name, phone, address }

class MechanicProfileScreen extends StatefulWidget {
  const MechanicProfileScreen({Key? key}) : super(key: key);

  @override
  State<MechanicProfileScreen> createState() => _MechanicProfileScreenState();
}

class _MechanicProfileScreenState extends State<MechanicProfileScreen> {
  final UserRepository _repo = UserRepository();
  late MechanicProfile profile;
  String fullName = '—';
  String phone = '—';
  String email = '';

  @override
  void initState() {
    super.initState();
    profile = MechanicProfile(
      fullName: 'Механик Иван Иванович',
      phone: '+7 (980) 001-01-01',
      clubName: 'Боулинг клуб "Кегли"',
      clubs: ['Боулинг клуб "Кегли"'],
      address: 'г. Воронеж, ул. Тверская, д. 45',
      workplaceVerified: false,
      birthDate: DateTime(1989, 2, 24),
      status: 'Самозанятый',
    );
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

  Future<void> _openEdit(EditFocus focus) async {
    final updated = await Navigator.push<MechanicProfile>(
      context,
      MaterialPageRoute(builder: (_) => EditMechanicProfileScreen(initial: profile, focus: focus)),
    );
    if (updated != null) setState(() => profile = updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Личный кабинет',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textDark),
        ),
        centerTitle: false,
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.sync), color: AppColors.primary)],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          ProfileTile(icon: Icons.person, text: profile.fullName, onEdit: () => _openEdit(EditFocus.name)),
          const SizedBox(height: 10),
          ProfileTile(icon: Icons.phone, text: profile.phone, onEdit: () => _openEdit(EditFocus.phone)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(color: AppColors.white, border: Border.all(color: AppColors.lightGray), borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.badge_outlined, size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                const Text('Статус:', style: TextStyle(fontSize: 14, color: AppColors.darkGray)),
                const SizedBox(width: 8),
                Expanded(child: Text(profile.status, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ProfileTile(
            icon: Icons.menu_book_rounded,
            text: 'База знаний',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KnowledgeBaseScreen())),
          ),
          const SizedBox(height: 10),
          ...List.generate(profile.clubs.length, (i) {
            final club = profile.clubs[i];
            return Padding(
              padding: EdgeInsets.only(bottom: i == profile.clubs.length - 1 ? 0 : 10),
              child: ProfileTile(
                icon: Icons.location_searching_rounded,
                text: club,
                showAlertBadge: !profile.workplaceVerified && i == 0,
                onTap: () => _openEdit(EditFocus.none),
              ),
            );
          }),
          const SizedBox(height: 10),
          ProfileTile(icon: Icons.location_on_rounded, text: profile.address, onEdit: () => _openEdit(EditFocus.address)),
          const SizedBox(height: 10),
          ProfileTile(icon: Icons.history_rounded, text: 'История заказов', onTap: () => Navigator.pushNamed(context, Routes.ordersPersonalHistory)),
          const SizedBox(height: 10),
          ProfileTile(icon: Icons.notifications_active_outlined, text: 'Оповещения', onTap: () {}),
          const SizedBox(height: 10),
          ProfileTile(icon: Icons.star_border_rounded, text: 'Избранные заказы/детали', onTap: () {}),
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
