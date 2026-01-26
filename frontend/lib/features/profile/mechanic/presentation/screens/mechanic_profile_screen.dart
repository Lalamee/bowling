import 'dart:developer';

import '../../../../../api/api_core.dart';
import '../../../../../core/repositories/user_repository.dart';
import '../../../../../core/repositories/specialists_repository.dart';
import 'package:flutter/material.dart';

import '../../../../../core/routing/routes.dart';
import '../../../../../core/services/auth_service.dart';
import '../../../../../core/services/local_auth_storage.dart';
import '../../../../../core/theme/colors.dart';
import '../../../../../core/utils/bottom_nav.dart';
import '../../../../../core/utils/user_club_resolver.dart';
import '../../../../../shared/widgets/nav/app_bottom_nav.dart';
import '../../../../../shared/widgets/tiles/profile_tile.dart';
import '../../../../knowledge_base/presentation/screens/knowledge_base_screen.dart';
import '../../../../orders/notifications/notifications_badge_controller.dart';
import '../../../../orders/notifications/notifications_page.dart';
import '../../domain/mechanic_profile.dart';
import '../../../../../models/mechanic_directory_models.dart';
import '../../../../../core/models/user_club.dart';
import '../../../../../core/services/authz/acl.dart';
import 'edit_mechanic_profile_screen.dart';
import 'free_mechanic_questionnaire_screen.dart';

enum EditFocus { none, name, phone, address }

class MechanicProfileScreen extends StatefulWidget {
  const MechanicProfileScreen({Key? key}) : super(key: key);

  @override
  State<MechanicProfileScreen> createState() => _MechanicProfileScreenState();
}

class _MechanicProfileScreenState extends State<MechanicProfileScreen> {
  final UserRepository _repo = UserRepository();
  final SpecialistsRepository _specialistsRepository = SpecialistsRepository();
  late MechanicProfile profile;
  bool _isLoading = true;
  bool _hasError = false;
  Map<String, dynamic>? _cachedRawProfile;
  bool _canEditProfile = false;
  String? _localRole;
  String? _accountType;
  bool _isFreeMechanic = false;
  String? _applicationStatus;
  String? _applicationComment;
  String? _applicationAccountType;
  String? _region;
  bool _needsFreeMechanicQuestionnaire = false;
  bool _ownerApprovalRequired = false;
  List<UserClub> _clubAccesses = const [];
  final NotificationsBadgeController _notificationsController = NotificationsBadgeController();
  int _notificationsCount = 0;

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
    _resolveLocalRole();
    _notificationsController.addListener(_handleNotificationsUpdate);
    _load();
  }

  @override
  void dispose() {
    _notificationsController.removeListener(_handleNotificationsUpdate);
    super.dispose();
  }

  Future<void> _handleNotificationsUpdate() async {
    if (!mounted) return;
    setState(() {
      _notificationsCount = _notificationsController.badgeCount;
    });
  }

  Future<void> _resolveLocalRole() async {
    final role = await LocalAuthStorage.getRegisteredRole();
    final accountType = await LocalAuthStorage.getRegisteredAccountType();
    if (!mounted) return;
    setState(() {
      _localRole = role;
      _accountType = accountType;
      _canEditProfile = _roleAllowsEditing(role);
      _isFreeMechanic = _isFreeMechanicType(accountType);
      _needsFreeMechanicQuestionnaire = _computeFreeMechanicQuestionnaireNeeded(profile);
    });
  }

  bool _isFreeMechanicType(String? accountType) {
    if (accountType == null) return false;
    final normalized = accountType.trim().toUpperCase();
    return normalized.contains('FREE_MECHANIC');
  }

  bool _roleAllowsEditing(String? role) {
    if (role == null) return false;
    final normalized = role.trim().toUpperCase();
    return normalized.contains('OWNER') || normalized.contains('ADMIN');
  }

  Future<void> _loadLocalProfile() async {
    final stored = await LocalAuthStorage.loadMechanicProfile();
    final application = await LocalAuthStorage.loadMechanicApplication();
    if (!mounted || stored == null) {
      return;
    }

    final normalized = _normalizeProfileData(Map<String, dynamic>.from(stored));
    _applicationStatus = application?['status']?.toString() ?? stored['applicationStatus']?.toString();
    _applicationComment = application?['comment']?.toString() ?? stored['applicationComment']?.toString();
    _applicationAccountType = application?['accountType']?.toString() ?? stored['accountType']?.toString();
    _accountType ??= _applicationAccountType ?? stored['accountType']?.toString();
    _isFreeMechanic =
        _isFreeMechanic || _isFreeMechanicType(_accountType) || _isFreeMechanicType(_applicationAccountType);
    _applyProfile(normalized, _clubAccesses);
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
      final scope = await UserAccessScope.fromProfile(me);
      await _notificationsController.ensureInitialized(scope);
      String? attestationStatus;
      String? gradeLabel;
      if (scope.mechanicProfileId != null) {
        try {
          final detail = await _specialistsRepository.getDetail(scope.mechanicProfileId!);
          attestationStatus = detail?.attestationStatus;
        } catch (_) {
          // ignore attestation errors
        }
      }
      try {
        final applications = await _specialistsRepository.getAttestationApplications();
        final profileId = scope.mechanicProfileId;
        final userId = scope.userId;
        final matching = applications.where((app) {
          final matchesProfile = profileId != null && app.mechanicProfileId == profileId;
          final matchesUser = userId != null && app.userId == userId;
          return matchesProfile || matchesUser;
        }).toList();
        if (matching.isNotEmpty) {
          matching.sort((a, b) {
            final aDate = a.updatedAt ?? a.submittedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bDate = b.updatedAt ?? b.submittedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bDate.compareTo(aDate);
          });
          final latest = matching.first;
          if (latest.status == AttestationDecisionStatus.approved) {
            final grade = latest.approvedGrade ?? latest.requestedGrade;
            if (grade != null) {
              gradeLabel = _gradeLabel(grade);
            }
          }
        }
      } catch (_) {
        // ignore attestation lookup errors
      }
      final remoteRole = me['role']?.toString();
      final allowEditing = _roleAllowsEditing(remoteRole) || _roleAllowsEditing(_localRole);
      if (_canEditProfile != allowEditing) {
        setState(() {
          _canEditProfile = allowEditing;
        });
      }
      final accessClubs = resolveUserClubs(me);
      final cache = _mapApiToCache(me, attestationStatus: attestationStatus, gradeLabel: gradeLabel);
      final normalized = _normalizeProfileData(cache);
      await LocalAuthStorage.saveMechanicProfile(normalized);
      if (!mounted) return;
      _applyProfile(normalized, accessClubs);
    } catch (e, s) {
      log('Failed to load mechanic profile: $e', stackTrace: s);
      if (e is ApiException && e.statusCode == 401) {
        await AuthService.logout();
        await LocalAuthStorage.clearMechanicState();
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

  Map<String, dynamic> _mapApiToCache(
    Map<String, dynamic> me, {
    String? attestationStatus,
    String? gradeLabel,
  }) {
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
    String? region;

    if (profileData is Map) {
      final map = Map<String, dynamic>.from(profileData);
      final profileClub = _asString(map['clubName']);
      final hasClubContext = profileClub != null || map['clubId'] != null;
      final workPlaces = map['workPlaces'];
      if (hasClubContext) {
        if (workPlaces is String) {
          clubs.addAll(workPlaces
              .split(',')
              .map((e) => e.trim())
              .where((element) => element.isNotEmpty));
        } else if (workPlaces is Iterable) {
          clubs.addAll(workPlaces.map((e) => e.toString().trim()).where((e) => e.isNotEmpty));
        }
      }
      final normalizedAttestation = attestationStatus?.trim();
      final normalizedGrade = gradeLabel?.trim();
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

      final profileRegion = _asString(map['region']);
      if (profileRegion != null) {
        region = profileRegion;
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
          status = 'ИП';
        } else if (isEntrepreneur is bool) {
          status = 'Самозанятый';
        }
      }
      if (normalizedAttestation != null && normalizedAttestation.isNotEmpty) {
        if (status == null || status.trim().isEmpty) {
          status = normalizedAttestation;
        } else if (!status!.toLowerCase().contains(normalizedAttestation.toLowerCase())) {
          status = '${status!}, $normalizedAttestation';
        }
      }
      if (normalizedGrade != null && normalizedGrade.isNotEmpty) {
        final gradeValue = 'механик $normalizedGrade';
        if (status == null || status.trim().isEmpty) {
          status = gradeValue;
        } else if (!status!.toLowerCase().contains(gradeValue.toLowerCase())) {
          status = '${status!}, $gradeValue';
        }
      }

      final verified = map['isVerified'];
      if (verified is bool) {
        workplaceVerified = verified;
      }
      final ownerApproval = map['ownerApprovalRequired'];
      if (ownerApproval is bool) {
        _ownerApprovalRequired = ownerApproval;
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
      'region': region ?? _asString(me['region']) ?? _asString(me['city']),
      'birthDate': birthDate?.toIso8601String(),
      'workplaceVerified': workplaceVerified ?? profile.workplaceVerified,
      'ownerApprovalRequired': _ownerApprovalRequired,
    };
  }

  void _applyProfile(Map<String, dynamic> raw, [List<UserClub> accessClubs = const []]) {
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

    final rawOwnerApproval = raw['ownerApprovalRequired'];
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
      _region = _asString(raw['region']) ?? _region;
      _ownerApprovalRequired = rawOwnerApproval is bool ? rawOwnerApproval : _ownerApprovalRequired;
      _isLoading = false;
      _hasError = false;
      _clubAccesses = accessClubs;
      _needsFreeMechanicQuestionnaire = _computeFreeMechanicQuestionnaireNeeded(profile);
    });
  }

  bool _computeFreeMechanicQuestionnaireNeeded(MechanicProfile current) {
    if (!_isFreeMechanic || !current.workplaceVerified) return false;
    bool missing(String value) => value.trim().isEmpty || value.trim() == '—';
    var addressValue = current.address;
    if (addressValue.trim().isEmpty) {
      final regionValue = _region?.trim();
      if (regionValue != null && regionValue.isNotEmpty) {
        addressValue = regionValue;
      }
    }
    return missing(current.fullName) ||
        missing(current.phone) ||
        missing(addressValue) ||
        missing(current.status);
  }

  String _gradeLabel(MechanicGrade grade) {
    switch (grade) {
      case MechanicGrade.junior:
        return 'junior';
      case MechanicGrade.middle:
        return 'middle';
      case MechanicGrade.senior:
        return 'senior';
      case MechanicGrade.lead:
        return 'lead';
    }
    return '—';
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
    final resolvedRegion = _asString(raw['region']) ?? _asString(previous?['region']) ?? _region;

    final resolvedStatus = _asString(raw['status']) ??
        _asString(previous?['status']) ??
        fallback.status;

    final resolvedVerified = (raw['workplaceVerified'] is bool)
        ? raw['workplaceVerified'] as bool
        : (previous?['workplaceVerified'] as bool?) ?? fallback.workplaceVerified;

    final normalized = {
      'fullName': _resolveFullName(),
      'phone': resolvedPhone,
      'status': resolvedStatus,
      'clubs': mergedClubs,
      'clubName': resolvedClubName,
      'address': resolvedAddress,
      'region': resolvedRegion,
      'birthDate': resolvedBirth.toIso8601String(),
      'workplaceVerified': resolvedVerified,
    };

    _cachedRawProfile = Map<String, dynamic>.from(normalized);

    return normalized;
  }
  Future<void> _openEdit(EditFocus focus) async {
    if (!_canEditProfile) return;
    final updated = await Navigator.push<MechanicProfile>(
      context,
      MaterialPageRoute(builder: (_) => EditMechanicProfileScreen(initial: profile, focus: focus)),
    );
    if (updated != null) setState(() => profile = updated);
  }

  Future<void> _openQuestionnaire() async {
    final application = await LocalAuthStorage.loadMechanicApplication();
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => FreeMechanicQuestionnaireScreen(
          initial: profile,
          initialRegion: _region,
          initialApplication: application,
        ),
      ),
    );
    if (result == null) return;
    final profileData = Map<String, dynamic>.from(result['profile'] as Map);
    final applicationData = Map<String, dynamic>.from(result['application'] as Map);
    await LocalAuthStorage.saveMechanicProfile(profileData);
    await LocalAuthStorage.saveMechanicApplication(applicationData);
    if (!mounted) return;
    setState(() {
      final updated = profile.copyWith(
        fullName: profileData['fullName']?.toString() ?? profile.fullName,
        phone: profileData['phone']?.toString() ?? profile.phone,
        clubName: profileData['clubName']?.toString() ?? profile.clubName,
        address: profileData['address']?.toString() ?? profile.address,
        status: profileData['status']?.toString() ?? profile.status,
        birthDate: profileData['birthDate'] != null
            ? DateTime.tryParse(profileData['birthDate'].toString()) ?? profile.birthDate
            : profile.birthDate,
        clubs: (profileData['clubs'] as List?)?.map((e) => e.toString()).toList(),
      );
      profile = updated;
      _region = profileData['region']?.toString() ?? _region;
      _cachedRawProfile = Map<String, dynamic>.from(profileData);
      _needsFreeMechanicQuestionnaire = _computeFreeMechanicQuestionnaireNeeded(updated);
    });
  }

  Future<void> _logout() async {
    await AuthService.logout();
    await LocalAuthStorage.clearMechanicState();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, Routes.welcome, (route) => false);
  }

  Widget _buildApplicationBanner() {
    if (_applicationStatus == null) return const SizedBox.shrink();
    final status = _applicationStatus!.toUpperCase();
    String title;
    String? description;
    Color color = AppColors.primary;

    switch (status) {
      case 'APPROVED':
        title = 'Заявка одобрена';
        description = 'Тип аккаунта: ${_applicationAccountType ?? 'FREE_MECHANIC_BASIC'}';
        color = Colors.green.shade700;
        break;
      case 'REJECTED':
        title = 'Заявка отклонена';
        description = _applicationComment ?? 'Причина не указана';
        color = Colors.red.shade700;
        break;
      case 'IN_REVIEW':
      case 'NEW':
      default:
        title = 'Заявка на рассмотрении';
        description = 'Администрация проверяет ваши данные';
        color = AppColors.primary;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 15)),
                if (description != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(description, style: const TextStyle(fontSize: 13)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingApprovalNotice() {
    if (!_isFreeMechanic || profile.workplaceVerified) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_clock_rounded, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Ограниченный доступ',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark),
                ),
                SizedBox(height: 4),
                Text(
                  'Функционал будет расширен после подтверждения администрацией сервиса.',
                  style: TextStyle(fontSize: 13, color: AppColors.darkGray, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionnaireNotice() {
    if (!_needsFreeMechanicQuestionnaire) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.assignment_outlined, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Заполните анкету',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Администрация одобрила регистрацию. Заполните недостающие данные профиля.',
                      style: TextStyle(fontSize: 13, color: AppColors.darkGray, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _openQuestionnaire,
              child: const Text('Заполнить анкету'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionnaireEntry() {
    if (!_isFreeMechanic || _needsFreeMechanicQuestionnaire) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Анкета механика',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark),
          ),
          const SizedBox(height: 6),
          const Text(
            'Заполните анкету свободного механика со всеми обязательными полями.',
            style: TextStyle(fontSize: 13, color: AppColors.darkGray, height: 1.3),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openQuestionnaire,
              icon: const Icon(Icons.assignment_outlined),
              label: const Text('Заполнить анкету'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleClubs = profile.clubs.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final canShowClubs = _isFreeMechanic;
    final showClubPlaceholder = canShowClubs && _clubAccesses.isEmpty && visibleClubs.isEmpty;
    final clubsToDisplay = canShowClubs
        ? (visibleClubs.isNotEmpty ? visibleClubs : (showClubPlaceholder ? ['Клубы и доступы'] : []))
        : const <String>[];
    final region = _region?.trim();
    final resolvedAddress = profile.address.trim().isNotEmpty
        ? profile.address
        : (_isFreeMechanic && region != null && region.isNotEmpty ? region : profile.address);
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
                    _buildApplicationBanner(),
                    _buildPendingApprovalNotice(),
                    _buildQuestionnaireNotice(),
                    _buildQuestionnaireEntry(),
                    ProfileTile(
                      icon: Icons.person,
                      text: profile.fullName,
                      onEdit: _canEditProfile ? () => _openEdit(EditFocus.name) : null,
                    ),
                    const SizedBox(height: 10),
                    ProfileTile(
                      icon: Icons.phone,
                      text: profile.phone,
                      onEdit: _canEditProfile ? () => _openEdit(EditFocus.phone) : null,
                    ),
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
                    if (canShowClubs && (_clubAccesses.isNotEmpty || showClubPlaceholder))
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.lightGray),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Клубы и доступы',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark),
                            ),
                            const SizedBox(height: 6),
                            if (_clubAccesses.isNotEmpty)
                              ..._clubAccesses.map((club) => Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: _ClubAccessTile(club: club),
                                  ))
                            else if (showClubPlaceholder)
                              const Text(
                                'Временные доступы к клубам отсутствуют. Доступ появится после приглашения от клуба или менеджера.',
                                style: TextStyle(color: AppColors.darkGray, fontSize: 13),
                              ),
                          ],
                        ),
                      ),
                    if (canShowClubs && (_clubAccesses.isNotEmpty || showClubPlaceholder))
                      const SizedBox(height: 10),
                    ProfileTile(
                      icon: Icons.warehouse_outlined,
                      text: 'Личный ZIP-склад',
                      onTap: () => Navigator.pushNamed(context, Routes.personalWarehouse),
                    ),
                    const SizedBox(height: 10),
                    ProfileTile(
                      icon: Icons.verified_user_outlined,
                      text: 'Аттестация и грейд',
                      onTap: () => Navigator.pushNamed(context, Routes.attestationApplications),
                    ),
                    const SizedBox(height: 10),
                    ProfileTile(
                      icon: Icons.menu_book_rounded,
                      text: 'База знаний',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KnowledgeBaseScreen())),
                    ),
                    const SizedBox(height: 10),
                    ...List.generate(clubsToDisplay.length, (i) {
                      final club = clubsToDisplay[i];
                      return Padding(
                        padding: EdgeInsets.only(bottom: i == clubsToDisplay.length - 1 ? 0 : 10),
                        child: ProfileTile(
                          icon: Icons.location_searching_rounded,
                          text: club,
                          showAlertBadge: !profile.workplaceVerified && club.isNotEmpty && i == 0,
                          onTap: _canEditProfile && club.isNotEmpty ? () => _openEdit(EditFocus.none) : null,
                        ),
                      );
                    }),
                    const SizedBox(height: 10),
                    ProfileTile(
                      icon: Icons.location_on_rounded,
                      text: resolvedAddress,
                      onEdit: _canEditProfile ? () => _openEdit(EditFocus.address) : null,
                    ),
                    const SizedBox(height: 10),
                    ProfileTile(
                      icon: Icons.notifications_active_outlined,
                      text: 'Оповещения',
                      badgeCount: _notificationsCount,
                      onTap: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPage()));
                        if (mounted) {
                          setState(() {
                            _notificationsCount = _notificationsController.badgeCount;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    ProfileTile(
                      icon: Icons.star_border_rounded,
                      text: 'Избранные заказы/детали',
                      onTap: () => Navigator.pushNamed(context, Routes.favorites),
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

class _ClubAccessTile extends StatelessWidget {
  final UserClub club;

  const _ClubAccessTile({required this.club});

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];
    if (club.accessLevel != null && club.accessLevel!.trim().isNotEmpty) {
      chips.add(Chip(label: Text('Доступ: ${club.accessLevel}')));
    }
    if (club.accessExpiresAt != null) {
      chips.add(Chip(label: Text('До ${_formatDate(club.accessExpiresAt!)}')));
    }
    if (club.infoAccessRestricted) {
      chips.add(const Chip(label: Text('Без техинфо')));
    }
    if (club.isTemporary && chips.isEmpty) {
      chips.add(const Chip(label: Text('Временный доступ')));
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.lock_clock_rounded, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                club.name,
                style: const TextStyle(fontSize: 14, color: AppColors.textDark, fontWeight: FontWeight.w600),
              ),
              if (club.address != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    club.address!,
                    style: const TextStyle(fontSize: 12, color: AppColors.darkGray),
                  ),
                ),
              if (chips.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: chips,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}';
  }
}
