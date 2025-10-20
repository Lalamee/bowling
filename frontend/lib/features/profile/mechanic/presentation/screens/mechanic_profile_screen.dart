import 'dart:developer';

import '../../../../../core/repositories/user_repository.dart';
import 'package:flutter/material.dart';

import '../../../../../core/repositories/user_repository.dart';
import '../../../../../core/routing/routes.dart';
import '../../../../../core/services/auth_service.dart';
import '../../../../../core/services/local_auth_storage.dart';
import '../../../../../core/theme/colors.dart';
import '../../../../../core/utils/bottom_nav.dart';
import '../../../../../shared/widgets/nav/app_bottom_nav.dart';
import '../../../../../shared/widgets/tiles/profile_tile.dart';
import '../../../../knowledge_base/presentation/screens/knowledge_base_screen.dart';
import '../../domain/mechanic_profile.dart';
import 'edit_mechanic_profile_screen.dart';
import '../../../../../shared/widgets/nav/app_bottom_nav.dart';
import '../../../../../core/utils/bottom_nav.dart';
import '../../../../knowledge_base/presentation/screens/knowledge_base_screen.dart';
import '../../../../../core/routing/routes.dart';
import '../../../../../core/services/auth_service.dart';
import '../../../../../core/services/local_auth_storage.dart';

enum EditFocus { none, name, phone, address }

class MechanicProfileScreen extends StatefulWidget {
  const MechanicProfileScreen({Key? key}) : super(key: key);

  @override
  State<MechanicProfileScreen> createState() => _MechanicProfileScreenState();
}

class _MechanicProfileScreenState extends State<MechanicProfileScreen> {
  final UserRepository _repo = UserRepository();
  late MechanicProfile profile;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    profile = MechanicProfile(
      fullName: '',
      phone: '',
      clubName: '',
      clubs: const [],
      address: '',
      workplaceVerified: false,
      birthDate: DateTime.now(),
      status: '',
    );
    _loadLocalProfile();
    _load();
  }

  Future<void> _loadLocalProfile() async {
    final stored = await LocalAuthStorage.loadMechanicProfile();
    if (!mounted || stored == null) {
      return;
    }

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
      final cache = _mapApiToCache(me);
      await LocalAuthStorage.saveMechanicProfile(cache);
      if (!mounted) return;
      _applyProfile(cache);
    } catch (e, s) {
      log('Failed to load mechanic profile: $e', stackTrace: s);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  Map<String, dynamic> _mapApiToCache(Map<String, dynamic> me) {
    String? _asString(dynamic value) {
      if (value == null) return null;
      final str = value.toString().trim();
      return str.isEmpty ? null : str;
    }

    final profileData = me['mechanicProfile'];
    final clubs = <String>[];
    bool? workplaceVerified;
    DateTime? birthDate;
    String? status;
    String? clubName;
    String? address;

    if (profileData is Map) {
      final map = Map<String, dynamic>.from(profileData);
      final workPlaces = map['workPlaces'];
      if (workPlaces is String) {
        clubs.addAll(workPlaces
            .split(',')
            .map((e) => e.trim())
            .where((element) => element.isNotEmpty));
      } else if (workPlaces is Iterable) {
        clubs.addAll(workPlaces.map((e) => e.toString().trim()).where((e) => e.isNotEmpty));
      }

      final profileClub = _asString(map['clubName']);
      if (profileClub != null) {
        clubName = profileClub;
        if (!clubs.contains(profileClub)) {
          clubs.insert(0, profileClub);
        }
      }

      final profileAddress = _asString(map['address']);
      if (profileAddress != null) {
        address = profileAddress;
      }

      final birth = map['birthDate'];
      if (birth is String && birth.isNotEmpty) {
        birthDate = DateTime.tryParse(birth);
      }

      final profileStatus = _asString(map['status']);
      if (profileStatus != null) {
        status = profileStatus;
      } else {
        final isEntrepreneur = map['isEntrepreneur'];
        if (isEntrepreneur is bool && isEntrepreneur) {
          status = 'Самозанятый';
        } else if (isEntrepreneur is bool) {
          status = 'Штатный механик';
        }
      }

      final verified = map['isVerified'];
      if (verified is bool) {
        workplaceVerified = verified;
      }
    }

    if (workplaceVerified == null) {
      final verifiedUser = me['isVerified'];
      if (verifiedUser is bool) {
        workplaceVerified = verifiedUser;
      }
    }

    return {
      'fullName': _asString(me['fullName']) ?? _asString(me['phone']) ?? profile.fullName,
      'phone': _asString(me['phone']) ?? profile.phone,
      'status': status ?? profile.status,
      'clubs': clubs,
      'clubName': clubName ?? (clubs.isNotEmpty ? clubs.first : profile.clubName),
      'address': address ?? (clubs.isNotEmpty ? clubs.first : profile.address),
      'birthDate': birthDate?.toIso8601String(),
      'workplaceVerified': workplaceVerified ?? profile.workplaceVerified,
    };
  }

  void _applyProfile(Map<String, dynamic> raw) {
    String? _asString(dynamic value) {
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

    final birthRaw = raw['birthDate'];
    DateTime? birthDate;
    if (birthRaw is String && birthRaw.isNotEmpty) {
      birthDate = DateTime.tryParse(birthRaw);
    }

    setState(() {
      profile = profile.copyWith(
        fullName: _asString(raw['fullName']) ?? profile.fullName,
        phone: _asString(raw['phone']) ?? profile.phone,
        clubName: _asString(raw['clubName']) ?? (clubs.isNotEmpty ? clubs.first : profile.clubName),
        address: _asString(raw['address']) ?? (clubs.isNotEmpty ? clubs.first : profile.address),
        status: _asString(raw['status']) ?? profile.status,
        clubs: clubs.isNotEmpty ? clubs : null,
        workplaceVerified: raw['workplaceVerified'] as bool? ?? profile.workplaceVerified,
        birthDate: birthDate ?? profile.birthDate,
      );
      _isLoading = false;
      _hasError = false;
    });
  }

  Map<String, dynamic> _normalizeProfileData(Map<String, dynamic> raw) {
    String? _asString(dynamic value) {
      if (value == null) return null;
      final str = value.toString().trim();
      return str.isEmpty ? null : str;
    }

    Iterable<String> _extractClubs(dynamic value) {
      if (value is Iterable) {
        return value.map((e) => e.toString().trim()).where((e) => e.isNotEmpty);
      }
      if (value is String && value.isNotEmpty) {
        return value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty);
      }
      return const Iterable<String>.empty();
    }

    final previous = _cachedRawProfile;
    final fallback = profile;

    final resolvedPhone = _asString(raw['phone']) ?? _asString(previous?['phone']) ?? fallback.phone;

    bool _looksLikePhone(String? value) {
      if (value == null) return false;
      final digits = value.replaceAll(RegExp(r'\D'), '');
      final refDigits = resolvedPhone.replaceAll(RegExp(r'\D'), '');
      if (digits.length < 5 || refDigits.length < 5) return false;
      return digits == refDigits || digits.endsWith(refDigits) || refDigits.endsWith(digits);
    }

    bool _looksLikeTimeline(String value) {
      final lower = value.toLowerCase();
      if (!RegExp(r'\d{4}').hasMatch(lower)) return false;
      return RegExp(r'(?:[-–—]|\bс\b|\bпо\b|н\.в\.?|наст\.?|текущ)').hasMatch(lower);
    }

    String _stripTimeline(String value) {
      var result = value.trim();
      result = result.replaceAll(RegExp(r'\s+'), ' ');
      const timelineSuffix =
          r'(?:\d{1,2}\.\d{1,2}\.\d{4}|\d{1,2}\.\d{4}|[а-яa-z]+\s+\d{4}|\d{4}|н\.в\.?|наст\.?)';
      final parentheticalTimeline = RegExp(r'\s*\((?:[^()]*\d{4}[^()]*)\)\s*$');
      if (parentheticalTimeline.hasMatch(result)) {
        result = result.replaceFirst(parentheticalTimeline, '').trim();
      }
      final dashTimeline = RegExp(
        r'\s*[-–—]\s*(?:с\s*)?' + timelineSuffix + r'(?:\s*(?:[-–—]|\bпо\b)\s*' + timelineSuffix + r')?\s*$',
        caseSensitive: false,
      );
      if (dashTimeline.hasMatch(result)) {
        result = result.replaceFirst(dashTimeline, '').trim();
      }
      final commaTimeline = RegExp(
        r'\s*,\s*(?:с\s*)?' + timelineSuffix + r'(?:\s*(?:[-–—]|\bпо\b)\s*' + timelineSuffix + r')?\s*$',
        caseSensitive: false,
      );
      if (commaTimeline.hasMatch(result)) {
        result = result.replaceFirst(commaTimeline, '').trim();
      }
      return result.trim();
    }

    String? _sanitizeClubLabel(String? value) {
      final candidate = _asString(value);
      if (candidate == null || candidate.isEmpty) return null;
      final stripped = _stripTimeline(candidate);
      if (stripped.isEmpty) return null;
      return stripped;
    }

    String _resolveFullName() {
      final candidate = _asString(raw['fullName']);
      if (candidate != null && !_looksLikePhone(candidate)) {
        return candidate;
      }
      final previousName = _asString(previous?['fullName']);
      if (previousName != null && !_looksLikePhone(previousName)) {
        return previousName;
      }
      final fallbackName = fallback.fullName.trim();
      if (!_looksLikePhone(fallbackName)) {
        return fallbackName;
      }
      return fallbackName;
    }

    final rawClubs = _extractClubs(raw['clubs']);
    final previousClubs = _extractClubs(previous?['clubs']);
    final fallbackClubs = fallback.clubs;

    String _resolveClubName() {
      final rawName = _sanitizeClubLabel(raw['clubName']);
      if (rawName != null && rawName.isNotEmpty) {
        return rawName;
      }
      for (final value in rawClubs) {
        final sanitized = _sanitizeClubLabel(value);
        if (sanitized != null) {
          return sanitized;
        }
      }
      final previousName = _sanitizeClubLabel(previous?['clubName']);
      if (previousName != null && previousName.isNotEmpty) {
        return previousName;
      }
      for (final value in previousClubs) {
        final sanitized = _sanitizeClubLabel(value);
        if (sanitized != null) {
          return sanitized;
        }
      }
      final fallbackSanitized = _sanitizeClubLabel(fallback.clubName);
      if (fallbackSanitized != null) {
        return fallbackSanitized;
      }
      return fallback.clubName;
    }

    final resolvedClubName = _resolveClubName();

    List<String> _mergeClubs() {
      final result = <String>[];
      final seen = <String>{};

      void addValue(String? value, {bool prioritize = false}) {
        final sanitized = _sanitizeClubLabel(value);
        if (sanitized == null || sanitized.isEmpty) return;
        if (_looksLikeTimeline(sanitized)) return;
        if (seen.contains(sanitized)) {
          if (prioritize) {
            result
              ..remove(sanitized)
              ..insert(0, sanitized);
          }
          return;
        }
        if (prioritize) {
          result.insert(0, sanitized);
        } else {
          result.add(sanitized);
        }
        seen.add(sanitized);
      }

      addValue(resolvedClubName, prioritize: true);
      for (final value in rawClubs) {
        addValue(value);
      }
      for (final value in previousClubs) {
        addValue(value);
      }
      for (final value in fallbackClubs) {
        addValue(value);
      }
      addValue(resolvedClubName, prioritize: true);

      if (result.isEmpty) {
        addValue(resolvedClubName, prioritize: true);
      }

      return result;
    }

    final mergedClubs = _mergeClubs();

    DateTime? _parseDate(String? value) {
      if (value == null || value.isEmpty) return null;
      return DateTime.tryParse(value);
    }

    final resolvedBirth = _parseDate(_asString(raw['birthDate'])) ??
        _parseDate(_asString(previous?['birthDate'])) ??
        fallback.birthDate;

    String? _resolveAddress() {
      final candidates = <String?>[
        _asString(raw['address']),
        _asString(previous?['address']),
        fallback.address,
      ];
      for (final candidate in candidates) {
        final trimmed = candidate?.trim();
        if (trimmed == null || trimmed.isEmpty) continue;
        if (trimmed == resolvedClubName) continue;
        if (_looksLikeTimeline(trimmed)) continue;
        return trimmed;
      }
      return null;
    }

    final resolvedAddress = _resolveAddress() ?? '';

    final resolvedStatus = _asString(raw['status']) ??
        _asString(previous?['status']) ??
        fallback.status;

    final resolvedVerified = (raw['workplaceVerified'] is bool)
        ? raw['workplaceVerified'] as bool
        : (previous?['workplaceVerified'] as bool?) ?? fallback.workplaceVerified;

    return {
      'fullName': _resolveFullName(),
      'phone': resolvedPhone,
      'status': resolvedStatus,
      'clubs': mergedClubs,
      'clubName': resolvedClubName,
      'address': resolvedAddress,
      'birthDate': resolvedBirth.toIso8601String(),
      'workplaceVerified': resolvedVerified,
    };
  }
  Future<void> _openEdit(EditFocus focus) async {
    final updated = await Navigator.push<MechanicProfile>(
      context,
      MaterialPageRoute(builder: (_) => EditMechanicProfileScreen(initial: profile, focus: focus)),
    );
    if (updated != null) setState(() => profile = updated);
  }

  Future<void> _logout() async {
    await AuthService.logout();
    await LocalAuthStorage.clearMechanicState();
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
