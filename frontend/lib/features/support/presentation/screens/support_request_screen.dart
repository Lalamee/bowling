import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../core/repositories/notifications_repository.dart';
import '../../../../core/repositories/support_repository.dart';
import '../../../../core/repositories/user_repository.dart';
import '../../../../core/services/authz/acl.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/net_ui.dart';
import '../../../../models/notification_event_dto.dart';
import '../../../../models/support_appeal_request_dto.dart';

class SupportRequestScreen extends StatefulWidget {
  const SupportRequestScreen({super.key});

  @override
  State<SupportRequestScreen> createState() => _SupportRequestScreenState();
}

class _SupportRequestScreenState extends State<SupportRequestScreen> {
  final SupportRepository _repository = SupportRepository();
  final NotificationsRepository _notificationsRepository = NotificationsRepository();
  final UserRepository _userRepository = UserRepository();
  final TextEditingController _subjectCtrl = TextEditingController();
  final TextEditingController _messageCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;
  bool _loadingReplies = true;
  List<NotificationEventDto> _replies = const [];

  @override
  void initState() {
    super.initState();
    _loadReplies();
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadReplies() async {
    setState(() => _loadingReplies = true);
    try {
      final me = await _userRepository.me();
      final scope = await UserAccessScope.fromProfile(me);
      final notifications = await _notificationsRepository.fetchNotifications(role: scope.role);
      final filtered = notifications.where((event) {
        if (!event.isAdminReply) return false;
        if (event.clubId != null && !scope.accessibleClubIds.contains(event.clubId)) return false;
        if (event.mechanicId != null && scope.mechanicProfileId != null && event.mechanicId != scope.mechanicProfileId) {
          return false;
        }
        return true;
      }).toList()
        ..sort((a, b) {
          final aDate = a.createdAt;
          final bDate = b.createdAt;
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return bDate.compareTo(aDate);
        });
      if (!mounted) return;
      setState(() {
        _replies = filtered;
        _loadingReplies = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingReplies = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final dto = SupportAppealRequestDto(
        subject: _subjectCtrl.text.trim().isEmpty ? null : _subjectCtrl.text.trim(),
        message: _messageCtrl.text.trim(),
      );
      await _repository.submitAppeal(dto);
      if (!mounted) return;
      _subjectCtrl.clear();
      _messageCtrl.clear();
      await _loadReplies();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сообщение отправлено')),
      );
    } catch (e) {
      if (!mounted) return;
      showApiError(context, e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

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
        final match = RegExp(r'(message|reply|answer|text|comment|content)\s*[:=]\s*([^,}]+)')
            .firstMatch(trimmed);
        if (match != null) {
          return match.group(2)?.trim();
        }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Обращение в администрацию'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.lightGray),
            ),
            child: const Text(
              'Опишите ваш вопрос в свободной форме. Администрация ответит в разделе оповещений.',
              style: TextStyle(color: AppColors.darkGray),
            ),
          ),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _subjectCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Тема',
                    hintText: 'Например: Доступ к разделу или ошибка в приложении',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _messageCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Сообщение',
                    hintText: 'Опишите проблему, укажите детали',
                  ),
                  maxLines: 6,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Введите сообщение';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _submitting ? null : _submit,
                    icon: _submitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_outlined),
                    label: Text(_submitting ? 'Отправка...' : 'Отправить'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Ответы администрации',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark),
                ),
              ),
              IconButton(
                onPressed: _loadingReplies ? null : _loadReplies,
                icon: const Icon(Icons.refresh, color: AppColors.primary),
              ),
            ],
          ),
          if (_loadingReplies)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_replies.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Ответов пока нет',
                style: TextStyle(color: AppColors.darkGray),
              ),
            )
          else
            ..._replies.map((reply) {
              final payloadText = _extractPayloadText(reply.payload);
              final header = reply.isAdminReply ? 'Ответ администрации' : reply.message;
              final body = payloadText ?? (reply.isAdminReply ? _sanitizeMessage(reply.message) : null);
              return Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.lightGray),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        header,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (body != null && body.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(body, style: const TextStyle(color: AppColors.darkGray)),
                      ],
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
