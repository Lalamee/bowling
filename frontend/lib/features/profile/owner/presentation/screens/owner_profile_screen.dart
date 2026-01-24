import 'dart:developer';

import 'package:flutter/material.dart';

import '../../../../../core/repositories/user_repository.dart';
import '../../../../../core/routing/routes.dart';
import '../../../../../core/services/auth_service.dart';
import '../../../../../core/services/authz/acl.dart';
import '../../../../../core/services/local_auth_storage.dart';
import '../../../../../api/api_core.dart';
import '../../../../../core/theme/colors.dart';
import '../../../../../shared/widgets/nav/app_bottom_nav.dart';
import '../../../../../shared/widgets/tiles/profile_tile.dart';
import '../../../../knowledge_base/presentation/screens/knowledge_base_screen.dart';
import '../../../../../core/utils/bottom_nav.dart';
import '../../domain/owner_profile.dart';
import 'edit_owner_profile_screen.dart';
import '../../../../orders/notifications/notifications_badge_controller.dart';

enum OwnerEditFocus { none, name, phone, address }

class OwnerProfileScreen extends StatefulWidget {
  const OwnerProfileScreen({Key? key}) : super(key: key);

  @override
  State<OwnerProfileScreen> createState() => _OwnerProfileScreenState();
}

class _OwnerProfileScreenState extends State<OwnerProfileScreen> {
  final UserRepository _repo = UserRepository();
  final NotificationsBadgeController _notificationsController = NotificationsBadgeController();
  late OwnerProfile profile;
  static const String _ownerStatusLabel = 'Владелец';
  bool _isLoading = true;
  bool _hasError = false;
  String? email;
  String? inn;
  int _notificationsCount = 0;

  @override
  void initState() {
    super.initState();
    _notificationsController.addListener(_handleNotificationsUpdate);
    profile = OwnerProfile(
      fullName: 'Владелец клуба/сети клубов',
      phone: '—',
      clubName: '—',
      clubs: const [],
      address: '—',
      workplaceVerified: false,
      birthDate: DateTime(1989, 1, 1),
      status: _ownerStatusLabel,
    );
    _loadLocalProfile();
    _load();
  }

  @override
  void dispose() {
    _notificationsController.removeListener(_handleNotificationsUpdate);
    super.dispose();
  }

  Future<void> _loadLocalProfile() async {
    final stored = await LocalAuthStorage.loadOwnerProfile();
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
      final cache = _mapApiToCache(me);
      await LocalAuthStorage.saveOwnerProfile(cache);
      if (!mounted) return;
      _applyProfile(cache);

      final scope = await UserAccessScope.fromProfile(me);
      await _notificationsController.ensureInitialized(scope);
      if (mounted) {
        setState(() {
          _notificationsCount = _notificationsController.badgeCount;
        });
      }
    } catch (e, s) {
      log('Failed to load owner profile: $e', stackTrace: s);
      if (e is ApiException &&
          (e.statusCode == 401 || e.statusCode == 403) &&
          e.errorType != 'missing_token') {
        await AuthService.logout();
        await LocalAuthStorage.clearOwnerState();
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, Routes.welcome, (route) => false);
        return;
      }
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
    final clubs = <String>[];
    String? clubName;
    String? address;
    String? contactEmail;
    String? contactInn;
    String? contactPerson;
    String? contactPhone;

    if (ownerProfile is Map) {
      final map = Map<String, dynamic>.from(ownerProfile);

      void addClubName(dynamic value) {
        final resolved = asString(value);
        if (resolved != null && !clubs.contains(resolved)) {
          clubs.add(resolved);
        }
      }

      final detailed = map['clubsDetailed'];
      if (detailed is Iterable) {
        for (final item in detailed) {
          if (item is Map) {
            final entry = Map<String, dynamic>.from(item);
            addClubName(entry['name']);
            if (address == null) {
              final entryAddress = asString(entry['address']);
              if (entryAddress != null) {
                address = entryAddress;
              }
            }
          }
        }
      }

      if (clubs.isEmpty) {
        final rawClubs = map['clubs'];
        if (rawClubs is Iterable) {
          for (final item in rawClubs) {
            addClubName(item);
          }
        } else {
          addClubName(rawClubs);
        }
      }

      final mapClubName = asString(map['clubName']);
      if (mapClubName != null) {
        clubName = mapClubName;
        addClubName(mapClubName);
      } else if (clubName == null && clubs.isNotEmpty) {
        clubName = clubs.first;
      }

      final legalName = asString(map['legalName']);
      if (legalName != null) {
        if (clubName == null) {
          clubName = legalName;
        }
        if (clubs.isEmpty) {
          clubs.add(legalName);
        }
      }

      if (address == null) {
        final legalAddress = asString(map['address'] ?? map['legalAddress']);
        if (legalAddress != null) {
          address = legalAddress;
        }
      }

      contactPerson = asString(map['contactPerson']);
      contactPhone = asString(map['contactPhone']);
      contactEmail = asString(map['contactEmail']);
      contactInn = asString(map['inn']);
    }

    var fullName = asString(me['fullName']) ?? contactPerson ?? profile.fullName;
    var phone = asString(me['phone']) ?? contactPhone ?? profile.phone;
    final verified = me['isVerified'] is bool ? me['isVerified'] as bool : profile.workplaceVerified;

    if (clubName == null && clubs.isEmpty) {
      final fallbackClub = asString(me['company']) ?? asString(me['clubName']);
      if (fallbackClub != null) {
        clubName = fallbackClub;
        clubs.add(fallbackClub);
      }
    }

    if (address == null) {
      address = asString(me['address']);
    }

    return {
      'fullName': fullName,
      'phone': phone,
      'clubName': clubName ?? (clubs.isNotEmpty ? clubs.first : profile.clubName),
      'address': address ?? profile.address,
      'status': _ownerStatusLabel,
      'clubs': clubs,
      'workplaceVerified': verified,
      'email': contactEmail ?? asString(me['email']),
      'inn': contactInn,
    };
  }

  void _applyProfile(Map<String, dynamic> raw) {
    String? asString(dynamic value) {
      if (value == null) return null;
      final str = value.toString().trim();
      return str.isEmpty ? null : str;
    }

    final clubs = <String>[];
    final rawClubs = raw['clubs'];
    if (rawClubs is Iterable) {
      clubs.addAll(rawClubs.map((e) => e.toString().trim()).where((e) => e.isNotEmpty));
    } else if (rawClubs is String && rawClubs.isNotEmpty) {
      clubs.addAll(rawClubs.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty));
    }

    final updatedProfile = profile.copyWith(
      fullName: asString(raw['fullName']) ?? profile.fullName,
      phone: asString(raw['phone']) ?? profile.phone,
      clubName: asString(raw['clubName']) ?? (clubs.isNotEmpty ? clubs.first : profile.clubName),
      address: asString(raw['address']) ?? profile.address,
      status: _ownerStatusLabel,
      clubs: clubs.isNotEmpty ? clubs : profile.clubs,
      workplaceVerified: raw['workplaceVerified'] as bool? ?? profile.workplaceVerified,
    );

    setState(() {
      profile = updatedProfile;
      email = asString(raw['email']) ?? email;
      inn = asString(raw['inn']) ?? inn;
      _isLoading = false;
      _hasError = false;
    });
  }

  Future<void> _openEdit(OwnerEditFocus focus) async {
    final updated = await Navigator.push<OwnerProfile>(
      context,
      MaterialPageRoute(builder: (_) => EditOwnerProfileScreen(initial: profile, focus: focus)),
    );
    if (updated != null) setState(() => profile = updated);
  }

  Future<void> _logout() async {
    await AuthService.logout();
    await LocalAuthStorage.clearOwnerState();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, Routes.welcome, (route) => false);
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Не удалось загрузить профиль',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _isLoading = true;
                              _hasError = false;
                            });
                            _load();
                          },
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Повторить'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: [
                    ProfileTile(icon: Icons.person, text: profile.fullName, onEdit: () => _openEdit(OwnerEditFocus.name)),
                    const SizedBox(height: 10),
                    ProfileTile(icon: Icons.phone, text: profile.phone, onEdit: () => _openEdit(OwnerEditFocus.phone)),
                    if (email != null && email!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      ProfileTile(icon: Icons.email_outlined, text: email!),
                    ],
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
                          Expanded(
                            child: Text(
                              profile.status,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (inn != null && inn!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      ProfileTile(icon: Icons.numbers_rounded, text: 'ИНН: $inn'),
                    ],
                    const SizedBox(height: 10),
                    ProfileTile(
                      icon: Icons.menu_book_rounded,
                      text: 'База знаний',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KnowledgeBaseScreen())),
                    ),
                    const SizedBox(height: 10),
                    if (profile.clubs.isNotEmpty)
                      ...List.generate(profile.clubs.length, (i) {
                        final club = profile.clubs[i];
                        return Padding(
                          padding: EdgeInsets.only(bottom: i == profile.clubs.length - 1 ? 0 : 10),
                          child: ProfileTile(
                            icon: Icons.location_searching_rounded,
                            text: club,
                            showAlertBadge: false,
                            onTap: () => _openEdit(OwnerEditFocus.none),
                          ),
                        );
                      }),
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
                ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 3,
        onTap: (i) => BottomNavDirect.go(context, 3, i),
      ),
    );
  }
}
