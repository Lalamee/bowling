import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/repositories/user_repository.dart';
import '../../../core/repositories/specialists_repository.dart';
import '../../../core/repositories/notifications_repository.dart';
import '../../../core/services/authz/acl.dart';
import '../../../core/services/local_auth_storage.dart';
import '../../../core/theme/colors.dart';
import '../../../core/routing/routes.dart';
import '../../../core/models/order_status.dart';
import '../../../core/utils/net_ui.dart';
import '../../../core/utils/user_club_resolver.dart';
import '../../../core/models/user_club.dart';
import '../../../models/maintenance_request_response_dto.dart';
import '../../../models/mechanic_directory_models.dart';
import '../notifications/notifications_badge_controller.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _badgeController = NotificationsBadgeController();
  final _userRepository = UserRepository();
  final _specialistsRepository = SpecialistsRepository();
  final _notificationsRepository = NotificationsRepository();
  final _dateFormatter = DateFormat('dd.MM.yyyy HH:mm');

  UserAccessScope? _scope;
  bool _loading = true;
  bool _error = false;
  bool _loadingMechanicEvents = false;
  bool _isMechanic = false;
  bool _isFreeMechanic = false;
  List<_MechanicEvent> _mechanicEvents = const [];
  List<UserClub> _clubAccesses = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final me = await _userRepository.me();
      final scope = await UserAccessScope.fromProfile(me);
      final clubs = resolveUserClubs(me);
      await _badgeController.ensureInitialized(scope);
      List<_MechanicEvent> mechanicEvents = _mechanicEvents;
      bool isMechanic = scope.role == 'mechanic';
      bool isFreeMechanic = scope.isFreeMechanic;
      if (isMechanic) {
        mechanicEvents = await _loadMechanicEvents(scope, clubs);
      }
      if (!mounted) return;
      setState(() {
        _scope = scope;
        _isMechanic = isMechanic;
        _isFreeMechanic = isFreeMechanic;
        _mechanicEvents = mechanicEvents;
        _clubAccesses = clubs;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
      });
      showApiError(context, e);
    }
  }

  Future<void> _refresh() async {
    await _badgeController.refresh();
    if (_scope != null && _scope!.role == 'mechanic') {
      _mechanicEvents = await _loadMechanicEvents(_scope!, _clubAccesses);
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _markAsRead() async {
    await _badgeController.markAllAsRead();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = _scope;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Оповещения',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textDark),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: _refresh,
          ),
        ],
      ),
      body: _buildBody(scope),
    );
  }

  Widget _buildBody(UserAccessScope? scope) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 56, color: AppColors.darkGray),
            const SizedBox(height: 12),
            const Text('Не удалось загрузить оповещения', style: TextStyle(color: AppColors.darkGray)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Повторить попытку'),
            ),
          ],
        ),
      );
    }

    if (scope == null) {
      return const Center(child: Text('Нет данных профиля'));
    }

    return AnimatedBuilder(
      animation: _badgeController,
      builder: (context, _) {
        final items = _badgeController.newOrders;

        final hasOrders = items.isNotEmpty;

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              if (_isMechanic) _buildMechanicEventBlock(),
              const SizedBox(height: 12),
              _SupportAppealCard(
                onPressed: () => Navigator.pushNamed(context, Routes.supportAppeal),
              ),
              if (hasOrders) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0, top: 8),
                  child: ElevatedButton(
                    onPressed: _markAsRead,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Отметить все как прочитано'),
                  ),
                ),
                ...items.map((order) {
                  final updatedAt = _resolveUpdatedAt(order);
                  final subtitle = _buildSubtitle(order, updatedAt);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            offset: const Offset(0, 4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: ListTile(
                        title: Text(
                          'Заявка №${order.requestId}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark),
                        ),
                        subtitle: subtitle.isEmpty
                            ? null
                            : Text(
                                subtitle,
                                style: const TextStyle(fontSize: 13, color: AppColors.darkGray),
                              ),
                      ),
                    ),
                  );
                }),
              ],
              if (!hasOrders && _mechanicEvents.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 48.0),
                  child: Center(
                    child: Text(
                      _isMechanic
                          ? 'Пока нет новых оповещений по заявкам и заявкам на аттестацию'
                          : 'Новых оповещений нет',
                      style: const TextStyle(color: AppColors.darkGray, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<List<_MechanicEvent>> _loadMechanicEvents(UserAccessScope scope, List<UserClub> clubs) async {
    try {
      setState(() => _loadingMechanicEvents = true);
      final events = <_MechanicEvent>[];
      final applications = await _specialistsRepository.getAttestationApplications();
      final profileId = scope.mechanicProfileId;
      final userId = scope.userId;
      for (final app in applications) {
        final matchesProfile = profileId != null && app.mechanicProfileId != null && app.mechanicProfileId == profileId;
        final matchesUser = userId != null && app.userId != null && app.userId == userId;
        if (matchesProfile || matchesUser) {
          events.add(_MechanicEvent(
            title: 'Аттестация: ${_statusLabel(app.status)}',
            description: app.comment ?? 'Заявленный грейд: ${app.requestedGrade?.toApiValue() ?? '-'}',
            createdAt: app.updatedAt ?? app.submittedAt,
          ));
        }
      }

      if (scope.isFreeMechanic) {
        final registration = await LocalAuthStorage.loadMechanicApplication();
        if (registration != null) {
          final status = registration['status']?.toString();
          final comment = registration['comment']?.toString();
          final accountType = registration['accountType']?.toString();
          if (status != null && status.isNotEmpty) {
            events.add(_MechanicEvent(
              title: 'Регистрация: $status',
              description: comment?.isNotEmpty == true
                  ? comment
                  : (accountType != null && accountType.isNotEmpty
                      ? 'Тип аккаунта: $accountType'
                      : 'Заявка на регистрацию обработана'),
              createdAt: DateTime.now(),
            ));
          }
        }
      }

      final notifications = await _notificationsRepository.fetchNotifications(role: scope.role);
      final accessibleClubs = scope.accessibleClubIds;
      for (final event in notifications) {
        if (event.clubId != null && accessibleClubs.isNotEmpty && !accessibleClubs.contains(event.clubId!)) {
          continue;
        }
        if (event.mechanicId != null && scope.mechanicProfileId != null && event.mechanicId != scope.mechanicProfileId) {
          continue;
        }

        final upperAudiences = event.audiences.map((e) => e.toUpperCase()).toSet();
        final hasAudienceRestriction = upperAudiences.isNotEmpty;
        final audienceAllowed = !hasAudienceRestriction ||
            upperAudiences.contains('ALL') ||
            upperAudiences.contains('MECHANIC') ||
            (scope.isFreeMechanic && upperAudiences.contains('FREE_MECHANIC')) ||
            (!scope.isFreeMechanic && (upperAudiences.contains('STAFF') || upperAudiences.contains('STAFF_MECHANIC')));
        if (!audienceAllowed) continue;

        if (scope.isFreeMechanic && event.isSupplierComplaint) continue;

        if (event.isHelpEvent ||
            event.isWarningEvent ||
            event.isSupplierComplaint ||
            event.isAccessRequest ||
            event.isAdminReply ||
            event.isFreeMechanicEvent) {
          final payloadText = _extractPayloadText(event.payload);
          final description = payloadText ?? _sanitizeMessage(event.message);
          events.add(_MechanicEvent(
            title: event.typeKey.label(),
            description: description.isNotEmpty ? description : null,
            createdAt: event.createdAt,
          ));
        }
      }

      if (scope.accessibleClubIds.isNotEmpty && scope.isFreeMechanic && clubs.isNotEmpty) {
        final formattedClubs = clubs.map((club) {
          final parts = <String>[club.name];
          if (club.accessLevel != null && club.accessLevel!.isNotEmpty) {
            parts.add('доступ: ${club.accessLevel}');
          }
          if (club.accessExpiresAt != null) {
            parts.add('до ${_formatDateTime(club.accessExpiresAt!)}');
          }
          if (club.infoAccessRestricted) {
            parts.add('техинфо ограничена');
          }
          return parts.join(' • ');
        }).join('; ');

        events.add(_MechanicEvent(
          title: 'Клубы и доступы',
          description: formattedClubs,
          createdAt: DateTime.now(),
        ));
      }

      events.sort((a, b) {
        final aDate = a.createdAt;
        final bDate = b.createdAt;
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });
      return events;
    } finally {
      if (mounted) {
        setState(() => _loadingMechanicEvents = false);
      }
    }
  }

  String _statusLabel(AttestationDecisionStatus? status) {
    switch (status) {
      case AttestationDecisionStatus.approved:
        return 'Одобрена';
      case AttestationDecisionStatus.rejected:
        return 'Отклонена';
      case AttestationDecisionStatus.pending:
      default:
        return 'На рассмотрении';
    }
  }

  Widget _buildMechanicEventBlock() {
    if (_loadingMechanicEvents) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_mechanicEvents.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.lightGray),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isFreeMechanic ? 'Кабинет свободного механика' : 'Оповещения механика',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark),
            ),
            const SizedBox(height: 6),
            const Text(
              'Новых решений по регистрации и аттестации нет',
              style: TextStyle(color: AppColors.darkGray),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isFreeMechanic ? 'Клубы и доступы' : 'Оповещения механика',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark),
          ),
          const SizedBox(height: 10),
          ..._mechanicEvents.map((event) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (event.description != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(event.description!, style: const TextStyle(color: AppColors.darkGray)),
                      ),
                    if (event.createdAt != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _formatDateTime(event.createdAt!),
                          style: const TextStyle(color: AppColors.darkGray, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  String _buildSubtitle(MaintenanceRequestResponseDto order, DateTime? updatedAt) {
    final parts = <String>[];
    if (order.requestedParts.any((part) => part.helpRequested == true)) {
      final helpCount = order.requestedParts.where((part) => part.helpRequested == true).length;
      parts.add('Запрос помощи: $helpCount поз.');
    }
    if (order.clubName != null && order.clubName!.isNotEmpty) {
      parts.add(order.clubName!);
    }
    if (order.status != null && order.status!.isNotEmpty) {
      parts.add(describeOrderStatus(order.status));
    }
    if (updatedAt != null) {
      parts.add(_formatDateTime(updatedAt));
    }
    return parts.join(' • ');
  }

  DateTime? _resolveUpdatedAt(MaintenanceRequestResponseDto order) {
    DateTime? latest;
    void consider(DateTime? value) {
      if (value == null) return;
      if (latest == null || value.isAfter(latest!)) {
        latest = value;
      }
    }

    consider(order.managerDecisionDate);
    consider(order.completionDate);
    consider(order.requestDate);
    for (final part in order.requestedParts) {
      consider(part.deliveryDate);
      consider(part.issueDate);
      consider(part.orderDate);
    }

    return latest;
  }

  String _formatDateTime(DateTime date) => _dateFormatter.format(date.toLocal());

  String? _extractPayloadText(String? payload) {
    if (payload == null) return null;
    final trimmed = payload.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map) {
          const keys = ['message', 'reply', 'answer', 'text', 'comment', 'content'];
          for (final key in keys) {
            final value = decoded[key];
            if (value is String && value.trim().isNotEmpty) {
              return value.trim();
            }
          }
        }
      } catch (_) {
        // ignore parsing errors
      }
    }
    return trimmed;
  }

  String _sanitizeMessage(String message) {
    final trimmed = message.trim();
    if (trimmed.isEmpty) return trimmed;
    final cleaned = trimmed.replaceAll(RegExp(r'[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}', caseSensitive: false), '');
    return cleaned.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
  }
}

class _SupportAppealCard extends StatelessWidget {
  final VoidCallback onPressed;

  const _SupportAppealCard({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Создать обращение',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark),
          ),
          const SizedBox(height: 6),
          const Text(
            'Опишите вопрос в свободной форме — ответ придёт в оповещения.',
            style: TextStyle(color: AppColors.darkGray),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.edit_note_outlined, color: AppColors.primary),
              label: const Text('Создать обращение', style: TextStyle(color: AppColors.primary)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MechanicEvent {
  final String title;
  final String? description;
  final DateTime? createdAt;

  const _MechanicEvent({required this.title, this.description, this.createdAt});
}
