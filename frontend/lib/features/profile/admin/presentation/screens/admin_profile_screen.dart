import '../../../../../core/repositories/user_repository.dart';
import 'package:flutter/material.dart';
import '../../../../../core/theme/colors.dart';
import '../../../../../shared/widgets/tiles/profile_tile.dart';
import '../../../../../shared/widgets/nav/app_bottom_nav.dart';
import '../../../../../core/utils/bottom_nav.dart';
import '../../../../../core/routing/routes.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final UserRepository _repo = UserRepository();
  String fullName = '—';
  String phone = '—';
  String email = '';

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
        title: const Text(
          'Личный кабинет',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textDark),
        ),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.sync), color: AppColors.primary),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          const ProfileTile(icon: Icons.badge_outlined, text: 'Администрация'),
          const SizedBox(height: 10),

          // Тайл «Боулинг клубы» c красной рамкой — отдельный локальный виджет,
          // чтобы не менять общий ProfileTile.
          _OutlinedActionTile(
            icon: Icons.search,
            text: 'Боулинг клубы',
            onTap: () => Navigator.pushNamed(context, Routes.adminClubs),
          ),

          const SizedBox(height: 10),
          ProfileTile(
            icon: Icons.handyman_outlined,
            text: 'Механики',
            onTap: () => Navigator.pushNamed(context, Routes.adminMechanics),
          ),
          const SizedBox(height: 10),
          ProfileTile(
            icon: Icons.history_rounded,
            text: 'История заказов',
            onTap: () => Navigator.pushNamed(context, Routes.adminOrders),
          ),
          const SizedBox(height: 10),
          ProfileTile(
            icon: Icons.notifications_active_outlined,
            text: 'Оповещения',
            onTap: () => Navigator.pushNamed(context, Routes.managerNotifications),
          ),
          const SizedBox(height: 24),
          ProfileTile(
            icon: Icons.exit_to_app_rounded,
            text: 'Выход',
            danger: true,
            onTap: () {},
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 3,
        onTap: (i) => BottomNavDirect.go(context, 3, i),
      ),
    );
  }
}

/// Локальный тайл с красной рамкой под макет (не меняет общий ProfileTile).
class _OutlinedActionTile extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onTap;

  const _OutlinedActionTile({
    required this.icon,
    required this.text,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary), // та самая красная рамка
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(fontSize: 16, color: AppColors.textDark),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.darkGray),
            ],
          ),
        ),
      ),
    );
  }
}
