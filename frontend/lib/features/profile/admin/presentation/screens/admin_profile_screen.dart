import 'dart:developer';

import 'package:flutter/material.dart';

import '../../../../../core/repositories/user_repository.dart';
import '../../../../../core/routing/routes.dart';
import '../../../../../core/services/auth_service.dart';
import '../../../../../core/services/local_auth_storage.dart';
import '../../../../../core/theme/colors.dart';
import '../../../../../shared/widgets/nav/app_bottom_nav.dart';
import '../../../../../shared/widgets/tiles/profile_tile.dart';
import '../../../../../core/utils/bottom_nav.dart';

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

  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadLocalProfile();
    _load();
  }

  Future<void> _loadLocalProfile() async {
    final stored = await LocalAuthStorage.loadAdminProfile();
    if (!mounted || stored == null) return;
    _applyProfile(stored);
  }

  Future<void> _load() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _hasError = false;
        });
      }

      final me = await _repo.me();
      if (!mounted) return;
      if (me == null) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
        return;
      }

      final normalized = _mapApiToCache(me);
      await LocalAuthStorage.saveAdminProfile(normalized);
      if (!mounted) return;
      _applyProfile(normalized);
    } catch (e, s) {
      log('Failed to load admin profile: $e', stackTrace: s);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  Map<String, dynamic> _mapApiToCache(Map<String, dynamic> me) {
    String? asString(dynamic value) {
      if (value == null) return null;
      final str = value.toString().trim();
      return str.isEmpty ? null : str;
    }

    final resolvedPhone = asString(me['phone']) ?? phone;
    final resolvedFullName = asString(me['fullName']) ?? resolvedPhone ?? fullName;
    final resolvedEmail = asString(me['email']);

    return {
      'fullName': resolvedFullName,
      'phone': resolvedPhone,
      'email': resolvedEmail,
    };
  }

  void _applyProfile(Map<String, dynamic> raw) {
    String? asString(dynamic value) {
      if (value == null) return null;
      final str = value.toString().trim();
      return str.isEmpty ? null : str;
    }

    setState(() {
      fullName = asString(raw['fullName']) ?? fullName;
      phone = asString(raw['phone']) ?? phone;
      email = asString(raw['email']) ?? email;
      _isLoading = false;
      _hasError = false;
    });
  }

  Future<void> _logout() async {
    await AuthService.logout();
    await LocalAuthStorage.clearAdminState();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, Routes.welcome, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_hasError) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Не удалось загрузить профиль администратора',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Повторить'),
              ),
            ],
          ),
        ),
      );
    } else {
      body = ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          ProfileTile(icon: Icons.person, text: fullName),
          const SizedBox(height: 10),
          ProfileTile(icon: Icons.phone, text: phone),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 10),
            ProfileTile(icon: Icons.email_outlined, text: email),
          ],
          const SizedBox(height: 10),
          const ProfileTile(icon: Icons.badge_outlined, text: 'Администрация'),
          const SizedBox(height: 10),
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
          const SizedBox(height: 24),
          ProfileTile(
            icon: Icons.exit_to_app_rounded,
            text: 'Выход',
            danger: true,
            onTap: _logout,
          ),
        ],
      );
    }

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
      body: body,
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
            border: Border.all(color: AppColors.primary),
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
