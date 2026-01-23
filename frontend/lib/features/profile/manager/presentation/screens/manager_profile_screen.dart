import 'dart:developer';

import 'package:flutter/material.dart';

import '../../../../../core/models/user_club.dart';
import '../../../../../core/repositories/user_repository.dart';
import '../../../../../core/routing/routes.dart';
import '../../../../../core/services/auth_service.dart';
import '../../../../../core/services/authz/acl.dart';
import '../../../../../core/services/local_auth_storage.dart';
import '../../../../../core/theme/colors.dart';
import '../../../../../core/utils/bottom_nav.dart';
import '../../../../../core/utils/user_club_resolver.dart';
import '../../../../../shared/widgets/nav/app_bottom_nav.dart';
import '../../../../../shared/widgets/tiles/profile_tile.dart';
import '../../../../knowledge_base/presentation/screens/knowledge_base_screen.dart';
import '../../../../orders/notifications/notifications_badge_controller.dart';

class ManagerProfileScreen extends StatefulWidget {
  const ManagerProfileScreen({Key? key}) : super(key: key);

  @override
  State<ManagerProfileScreen> createState() => _ManagerProfileScreenState();
}

class _ManagerProfileScreenState extends State<ManagerProfileScreen> {
  final UserRepository _repo = UserRepository();
  final NotificationsBadgeController _notificationsController = NotificationsBadgeController();

  String fullName = '—';
  String phone = '—';
  String email = '';
  String clubName = '—';
  String address = '—';
  List<String> clubs = const [];

  bool _isLoading = true;
  bool _hasError = false;
  int _notificationsCount = 0;

  @override
  void initState() {
    super.initState();
    _notificationsController.addListener(_handleNotificationsUpdate);
    _loadLocalProfile();
    _load();
  }

  @override
  void dispose() {
    _notificationsController.removeListener(_handleNotificationsUpdate);
    super.dispose();
  }

  Future<void> _loadLocalProfile() async {
    final stored = await LocalAuthStorage.loadManagerProfile();
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
      await LocalAuthStorage.saveManagerProfile(normalized);
      if (!mounted) return;
      _applyProfile(normalized);

      final scope = await UserAccessScope.fromProfile(me);
      await _notificationsController.ensureInitialized(scope);
      if (mounted) {
        setState(() {
          _notificationsCount = _notificationsController.badgeCount;
        });
      }
    } catch (e, s) {
      log('Failed to load manager profile: $e', stackTrace: s);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  void _handleNotificationsUpdate() {
    if (!mounted) return;
    final current = _notificationsController.badgeCount;
    if (current != _notificationsCount) {
      setState(() {
        _notificationsCount = current;
      });
    }
  }

  Map<String, dynamic> _mapApiToCache(Map<String, dynamic> me) {
    String? asString(dynamic value) {
      if (value == null) return null;
      final str = value.toString().trim();
      return str.isEmpty ? null : str;
    }

    final ownerProfile = me['ownerProfile'];
    final mechanicProfile = me['mechanicProfile'];
    final managerProfile = me['managerProfile'];

    final List<UserClub> clubsDetailed = resolveUserClubs(me);
    final clubNames = <String>[];
    final seenNames = <String>{};
    String? resolvedAddress;
    bool ownerApprovalRequired = false;

    void addClubName(String? value, {bool prioritize = false}) {
      final name = asString(value);
      if (name == null) return;
      final wasAdded = seenNames.add(name);
      if (!wasAdded) return;
      if (prioritize) {
        clubNames.insert(0, name);
      } else {
        clubNames.add(name);
      }
    }

    for (final entry in clubsDetailed) {
      addClubName(entry.name);
      final address = asString(entry.address);
      if (address != null && (resolvedAddress == null || address.length > resolvedAddress.length)) {
        resolvedAddress = address;
      }
    }

    bool workplaceVerified = false;

    if (managerProfile is Map) {
      final map = Map<String, dynamic>.from(managerProfile);
      addClubName(map['clubName'], prioritize: true);
      if (map['club'] is Map) {
        final club = Map<String, dynamic>.from(map['club'] as Map);
        addClubName(club['name'], prioritize: true);
        final clubAddress = asString(club['address']);
        if (clubAddress != null) {
          resolvedAddress ??= clubAddress;
        }
      }
      resolvedAddress = asString(map['address']) ?? resolvedAddress;
      final rawVerified = map['workplaceVerified'] ?? map['isVerified'];
      if (rawVerified is bool) {
        workplaceVerified = workplaceVerified || rawVerified;
      }
      final rawOwnerApproval = map['ownerApprovalRequired'];
      if (rawOwnerApproval is bool) {
        ownerApprovalRequired = rawOwnerApproval;
      }
    }

    if (ownerProfile is Map) {
      final map = Map<String, dynamic>.from(ownerProfile);
      resolvedAddress = asString(map['address']) ?? resolvedAddress;
    }

    final emailSources = [me, managerProfile, ownerProfile];
    String? resolvedEmail;
    for (final source in emailSources) {
      if (source is Map) {
        final map = Map<String, dynamic>.from(source);
        resolvedEmail = asString(map['contactEmail']) ?? resolvedEmail;
        resolvedEmail = asString(map['email']) ?? resolvedEmail;
      }
    }

    resolvedEmail = asString(me['email']) ?? resolvedEmail;

    if (resolvedAddress == null) {
      resolvedAddress = _resolveAddress([managerProfile, ownerProfile, mechanicProfile, me]);
    }

    final resolvedPhone = asString(me['phone']) ?? phone;
    final resolvedFullName = asString(me['fullName']) ?? resolvedPhone ?? fullName;
    final resolvedClubName = clubNames.isNotEmpty ? clubNames.first : null;

    final rawVerified = me['workplaceVerified'] ?? me['isVerified'];
    if (rawVerified is bool) {
      workplaceVerified = workplaceVerified || rawVerified;
    }

    return {
      'fullName': resolvedFullName,
      'phone': resolvedPhone,
      'email': resolvedEmail,
      'clubName': resolvedClubName,
      'address': resolvedAddress,
      'clubs': clubNames,
      'workplaceVerified': workplaceVerified,
      'ownerApprovalRequired': ownerApprovalRequired,
    };
  }

  void _applyProfile(Map<String, dynamic> raw) {
    String? asString(dynamic value) {
      if (value == null) return null;
      final str = value.toString().trim();
      return str.isEmpty ? null : str;
    }

    final rawClubs = raw['clubs'];
    final parsedClubs = <String>[];
    if (rawClubs is Iterable) {
      parsedClubs.addAll(rawClubs.map((e) => asString(e)).whereType<String>());
    } else if (rawClubs is String && rawClubs.isNotEmpty) {
      parsedClubs.addAll(rawClubs.split(',').map((e) => asString(e)).whereType<String>());
    }

    setState(() {
      fullName = asString(raw['fullName']) ?? fullName;
      phone = asString(raw['phone']) ?? phone;
      email = asString(raw['email']) ?? email;
      clubs = parsedClubs.isNotEmpty ? parsedClubs : clubs;
      clubName = asString(raw['clubName']) ?? (clubs.isNotEmpty ? clubs.first : clubName);
      address = asString(raw['address']) ?? address;
      _isLoading = false;
      _hasError = false;
    });
  }

  String? _resolveAddress(List<dynamic> sources) {
    for (final source in sources) {
      if (source is Map) {
        final map = Map<String, dynamic>.from(source);
        final value = _asString(map['address']);
        if (value != null) {
          return value;
        }
      }
    }
    return null;
  }

  String? _asString(dynamic value) {
    if (value == null) return null;
    final str = value.toString().trim();
    return str.isEmpty ? null : str;
  }

  Future<void> _logout() async {
    await AuthService.logout();
    await LocalAuthStorage.clearManagerState();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, Routes.welcome, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (_isLoading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_hasError) {
      content = Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Не удалось загрузить профиль менеджера',
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
      content = ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          ProfileTile(icon: Icons.person, text: fullName, onEdit: () {}),
          const SizedBox(height: 10),
          ProfileTile(icon: Icons.phone, text: phone, onEdit: () {}),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 10),
            ProfileTile(icon: Icons.email_outlined, text: email, onEdit: () {}),
          ],
          const SizedBox(height: 10),
          ProfileTile(
            icon: Icons.menu_book_rounded,
            text: 'База знаний',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const KnowledgeBaseScreen()),
            ),
          ),
          const SizedBox(height: 10),
          ProfileTile(
            icon: Icons.support_agent_outlined,
            text: 'Обращение в администрацию',
            onTap: () => Navigator.pushNamed(context, Routes.supportAppeal),
          ),
          const SizedBox(height: 10),
          ProfileTile(icon: Icons.location_on_rounded, text: address, onEdit: () {}),
          const SizedBox(height: 10),
          ProfileTile(
            icon: Icons.inventory_2_outlined,
            text: 'Приёмка поставок',
            onTap: () => Navigator.pushNamed(context, Routes.supplyAcceptance),
          ),
          const SizedBox(height: 10),
          ProfileTile(
            icon: Icons.archive_outlined,
            text: 'Архив поставок и претензии',
            onTap: () => Navigator.pushNamed(context, Routes.supplyArchive),
          ),
          const SizedBox(height: 10),
          ProfileTile(
            icon: Icons.notifications_active_outlined,
            text: 'Оповещения',
            badgeCount: _notificationsCount,
            onTap: () async {
              await Navigator.pushNamed(context, Routes.managerNotifications);
              if (mounted) {
                setState(() {
                  _notificationsCount = _notificationsController.badgeCount;
                });
              }
            },
          ),
          const SizedBox(height: 10),
          ProfileTile(icon: Icons.exit_to_app_rounded, text: 'Выход', danger: true, onTap: _logout),
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
        centerTitle: false,
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.sync), color: AppColors.primary)],
      ),
      body: content,
      bottomNavigationBar: AppBottomNav(
        currentIndex: 3,
        onTap: (i) => BottomNavDirect.go(context, 3, i),
      ),
    );
  }
}
