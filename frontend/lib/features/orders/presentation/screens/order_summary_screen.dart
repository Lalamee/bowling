import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../../core/repositories/user_repository.dart';
import '../../../../../core/services/authz/acl.dart';
import '../../../../../core/repositories/maintenance_repository.dart';
import '../../../../../core/repositories/notifications_repository.dart';
import '../../../../../core/services/favorites_storage.dart';
import '../../../../../core/theme/colors.dart';
import '../../../../../core/theme/typography_extension.dart';
import '../../../../../models/maintenance_request_response_dto.dart';
import '../../../../../models/help_request_dto.dart';
import '../../../../../core/utils/net_ui.dart';
import '../../../../../core/utils/help_request_status_helper.dart';
import '../../../../../models/notification_event_dto.dart';
import '../../domain/order_status.dart';
import '../widgets/order_status_badge.dart';

class OrderSummaryScreen extends StatefulWidget {
  final MaintenanceRequestResponseDto? order;
  final String? orderNumber;
  final bool canConfirm;
  final bool canComplete;
  final bool canRequestHelp;
  final bool canResolveHelp;
  final bool? initialAvailability;
  final Future<bool> Function({required Map<int, bool> availability, String? comment})? onConfirm;
  final Future<bool> Function()? onComplete;
  final void Function(MaintenanceRequestResponseDto updated)? onOrderUpdated;

  const OrderSummaryScreen({
    super.key,
    this.order,
    this.orderNumber,
    this.canConfirm = false,
    this.canComplete = false,
    this.canRequestHelp = false,
    this.canResolveHelp = false,
    this.initialAvailability,
    this.onConfirm,
    this.onComplete,
    this.onOrderUpdated,
  });

  @override
  State<OrderSummaryScreen> createState() => _OrderSummaryScreenState();
}

class _OrderSummaryScreenState extends State<OrderSummaryScreen> {
  final _userRepository = UserRepository();
  final _maintenanceRepository = MaintenanceRepository();
  final _notificationsRepository = NotificationsRepository();
  final FavoritesStorage _favoritesStorage = FavoritesStorage();
  MaintenanceRequestResponseDto? _currentRequest;
  bool _isSubmitting = false;
  bool _isCompleting = false;
  bool _helpSubmitting = false;
  late final TextEditingController _commentController;
  late final TextEditingController _helpCommentController;
  late final TextEditingController _reassignController;
  bool _accessCheckInProgress = true;
  bool _accessDenied = false;
  bool _helpStatusLoading = false;
  bool _isExporting = false;
  final Map<int, bool> _availabilityDecisions = {};
  Set<int> _selectedHelpPartIds = {};
  HelpResponseDecision _decision = HelpResponseDecision.approved;
  List<NotificationEventDto> _helpEvents = const [];
  UserAccessScope? _scope;
  bool _isFavoriteOrder = false;
  Set<String> _favoritePartKeys = <String>{};

  String get _title {
    if (widget.orderNumber != null && widget.orderNumber!.isNotEmpty) return widget.orderNumber!;
    if (widget.order != null) {
      return 'Заявка №${widget.order!.requestId}';
    }
    return 'Заказ';
  }

  MaintenanceRequestResponseDto? get _request => _currentRequest ?? widget.order;

  List<int> get _partIds {
    final request = _request;
    if (request == null) return const [];
    return request.requestedParts.map((part) => part.partId).toList();
  }

  void _prefillAvailability() {
    final request = _request;
    if (request != null) {
      for (final part in request.requestedParts) {
        final decision = part.available;
        if (decision != null) {
          _availabilityDecisions[part.partId] = decision;
        }
      }
      if (_availabilityDecisions.isEmpty && widget.initialAvailability != null) {
        for (final part in request.requestedParts) {
          _availabilityDecisions[part.partId] = widget.initialAvailability!;
        }
      }
    }
  }

  bool? _decisionForPart(int partId) => _availabilityDecisions[partId];

  bool get _allDecisionsMade {
    if (!widget.canConfirm) return true;
    final ids = _partIds;
    if (ids.isEmpty) return true;
    return ids.every(_availabilityDecisions.containsKey);
  }

  void _applyUpdate(MaintenanceRequestResponseDto updated) {
    setState(() {
      _currentRequest = updated;
      _selectedHelpPartIds = updated.requestedParts
          .where((part) => part.helpRequested == true)
          .map((e) => e.partId)
          .toSet();
    });
    widget.onOrderUpdated?.call(updated);
    final scope = _scope;
    if (scope != null) {
      _loadHelpNotifications(scope);
    }
  }

  String _availabilityLabel(bool? value) {
    if (value == null) return 'не указано';
    return value ? 'есть в наличии' : 'нет в наличии';
  }

  void _setDecisionForPart(int partId, bool value) {
    setState(() {
      _availabilityDecisions[partId] = value;
    });
  }

  void _applyBulkDecision(bool value) {
    final ids = _partIds;
    if (ids.isEmpty) return;
    setState(() {
      for (final id in ids) {
        _availabilityDecisions[id] = value;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController();
    _helpCommentController = TextEditingController();
    _reassignController = TextEditingController();
    _prefillAvailability();
    _selectedHelpPartIds = _partIds.toSet();
    _guardAccess();
    _loadFavorites();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _helpCommentController.dispose();
    _reassignController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    final orders = await _favoritesStorage.loadFavoriteOrders();
    final parts = await _favoritesStorage.loadFavoriteParts();
    if (!mounted) return;
    setState(() {
      final requestId = _request?.requestId;
      _isFavoriteOrder = requestId != null && orders.contains(requestId);
      _favoritePartKeys = parts.map((part) => part.key).toSet();
    });
  }

  Future<void> _toggleFavoriteOrder() async {
    final requestId = _request?.requestId;
    if (requestId == null) return;
    await _favoritesStorage.toggleFavoriteOrder(requestId);
    await _loadFavorites();
  }

  Future<void> _toggleFavoritePart(RequestPartResponseDto part) async {
    final key = FavoritesStorage.partKey(partId: part.partId, catalogNumber: part.catalogNumber);
    final name = part.partName ?? part.catalogNumber ?? 'Деталь ${part.partId}';
    await _favoritesStorage.toggleFavoritePart(
      FavoritePart(
        key: key,
        name: name,
        catalogNumber: part.catalogNumber,
      ),
    );
    await _loadFavorites();
  }

  Future<void> _exportToExcel() async {
    final request = _request;
    if (request?.requestId == null) {
      _toast('Не удалось определить заявку для выгрузки');
      return;
    }
    if (kIsWeb) {
      _toast('Выгрузка доступна в мобильном приложении');
      return;
    }
    if (_isExporting) {
      return;
    }
    setState(() => _isExporting = true);
    try {
      final bytes = await _maintenanceRepository.downloadOrderExcel(request!.requestId);
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/order-${request.requestId}.xlsx');
      await file.writeAsBytes(bytes, flush: true);
      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done) {
        _toast('Файл сохранён: ${file.path}');
      }
    } catch (e) {
      if (!mounted) return;
      showApiError(context, e);
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.typo;
    final request = _request;
    final orderStatus = request != null ? mapOrderStatus(request.status) : OrderStatusCategory.pending;

    if (_accessCheckInProgress) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_accessDenied) {
      return Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          title: Text(_title, style: t.sectionTitle),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 56, color: AppColors.darkGray),
                const SizedBox(height: 16),
                const Text(
                  'У вас нет доступа к этой заявке',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.darkGray, fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Вернуться'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(_title, style: t.sectionTitle),
        actions: [
          IconButton(
            icon: Icon(_isFavoriteOrder ? Icons.star : Icons.star_border, color: Colors.amber),
            onPressed: _toggleFavoriteOrder,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Text('Сводка', style: t.mainWelcomeTitle.copyWith(fontSize: 24))),
                      OrderStatusBadge(category: orderStatus),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (request != null && request.clubName != null)
                    Text(request.clubName!, style: t.formInput),
                  if (request != null && request.laneNumber != null) ...[
                    const SizedBox(height: 4),
                    Text('Дорожка ${request.laneNumber}', style: t.formInput),
                  ],
                  if (request != null && request.status != null) ...[
                    const SizedBox(height: 4),
                    Text('Текущий статус: ${describeOrderStatus(request.status)}', style: t.formInput),
                  ],
                  if (request != null && request.managerNotes != null && request.managerNotes!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text('Заметки менеджера', style: t.formLabel),
                    const SizedBox(height: 4),
                    Text(request.managerNotes!, style: t.formInput),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_scope?.isFreeMechanic == true && request != null) ...[
            OutlinedButton.icon(
              onPressed: _isExporting ? null : _exportToExcel,
              icon: _isExporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_outlined, color: AppColors.primary),
              label: Text(
                _isExporting ? 'Выгрузка...' : 'Выгрузить в Excel',
                style: const TextStyle(color: AppColors.primary),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text('Детали заказа', style: t.sectionTitle),
          const SizedBox(height: 12),
          if (request == null || request.requestedParts.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: const Text('Нет деталей', style: TextStyle(color: AppColors.darkGray)),
            )
          else
            ...request.requestedParts.map(
              (part) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (part.helpRequested == true)
                          const Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Icon(Icons.priority_high, color: Colors.orange, size: 18),
                          ),
                        Expanded(
                          child: Text(
                            part.partName ?? part.catalogNumber ?? 'Неизвестная деталь',
                            style: t.formLabel,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _favoritePartKeys.contains(
                              FavoritesStorage.partKey(partId: part.partId, catalogNumber: part.catalogNumber),
                            )
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                          ),
                          onPressed: () => _toggleFavoritePart(part),
                        ),
                      ],
                    ),
                    if (part.catalogNumber != null && part.catalogNumber!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('Каталожный номер: ${part.catalogNumber}', style: t.formInput),
                      ),
                    if (part.inventoryLocation != null && part.inventoryLocation!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('Локация: ${part.inventoryLocation}', style: t.formInput),
                      ),
                    if (part.quantity != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('Количество: ${part.quantity}', style: t.formInput),
                      ),
                    if (part.status != null && part.status!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('Статус: ${describeOrderStatus(part.status)}', style: t.formInput),
                      ),
                    if (part.acceptedQuantity != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('Принято: ${part.acceptedQuantity}', style: t.formInput),
                      ),
                    if (widget.canConfirm && widget.onConfirm != null) ...[
                      const SizedBox(height: 12),
                      Text('Наличие детали', style: t.formLabel),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Есть в наличии'),
                            selected: _decisionForPart(part.partId) == true,
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: _decisionForPart(part.partId) == true
                                  ? Colors.white
                                  : AppColors.textDark,
                            ),
                            onSelected: (_) => _setDecisionForPart(part.partId, true),
                          ),
                          ChoiceChip(
                            label: const Text('Нет в наличии'),
                            selected: _decisionForPart(part.partId) == false,
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: _decisionForPart(part.partId) == false
                                  ? Colors.white
                                  : AppColors.textDark,
                            ),
                            onSelected: (_) => _setDecisionForPart(part.partId, false),
                          ),
                        ],
                      ),
                    ] else ...[
                      const SizedBox(height: 12),
                      Text('Наличие: ${_availabilityLabel(part.available)}', style: t.formInput),
                    ],
                    if (part.rejectionReason != null && part.rejectionReason!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('Причина отказа: ${part.rejectionReason}', style: t.formInput),
                      ),
                    if (part.acceptanceComment != null && part.acceptanceComment!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('Комментарий приемки: ${part.acceptanceComment}', style: t.formInput),
                      ),
                    if (part.orderDate != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('Заказано: ${_formatDate(part.orderDate!)}', style: t.formInput),
                      ),
                    if (part.deliveryDate != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('Доставка: ${_formatDate(part.deliveryDate!)}', style: t.formInput),
                      ),
                    if (part.issueDate != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('Выдача: ${_formatDate(part.issueDate!)}', style: t.formInput),
                      ),
                  ],
                ),
              ),
            ),
          if ((widget.canRequestHelp || widget.canResolveHelp) && request != null) ...[
            const SizedBox(height: 12),
            _buildHelpRequestSection(t, request),
          ],
          if (widget.canConfirm && widget.onConfirm != null) ...[
            const SizedBox(height: 24),
            Text('Подтверждение заказа', style: t.sectionTitle),
            const SizedBox(height: 12),
            if (_partIds.isNotEmpty) ...[
              Text('Отметьте наличие для каждой детали', style: t.formLabel),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _applyBulkDecision(true),
                    icon: const Icon(Icons.check_circle_outline, color: AppColors.primary),
                    label: const Text('Все есть в наличии'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _applyBulkDecision(false),
                    icon: const Icon(Icons.remove_circle_outline, color: AppColors.primary),
                    label: const Text('Ничего нет в наличии'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Комментарий для механика',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: (!_allDecisionsMade || _isSubmitting || _isCompleting)
                    ? null
                    : () => _handleConfirm(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Подтвердить заказ'),
              ),
            ),
          ],
          if (widget.canComplete && widget.onComplete != null) ...[
            const SizedBox(height: 24),
            Text('Завершение заказа', style: t.sectionTitle),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: (_isSubmitting || _isCompleting)
                    ? null
                    : () => _handleComplete(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isCompleting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Завершить заказ'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _guardAccess() async {
    final order = widget.order;
    if (order == null) {
      setState(() {
        _accessCheckInProgress = false;
      });
      return;
    }

    try {
      final me = await _userRepository.me();
      final scope = await UserAccessScope.fromProfile(me);
      _scope = scope;
      final allowed = scope.canViewOrder(order);
      if (!mounted) return;
      setState(() {
        _accessDenied = !allowed;
        _accessCheckInProgress = false;
      });
      if (allowed) {
        await _loadHelpNotifications(scope);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _accessDenied = true;
        _accessCheckInProgress = false;
      });
    }
  }

  Future<void> _loadHelpNotifications(UserAccessScope scope) async {
    final request = _request;
    if (request == null) return;
    setState(() => _helpStatusLoading = true);
    try {
      final events = await _notificationsRepository.fetchNotifications(
        clubId: request.clubId,
        role: scope.role,
      );
      if (!mounted) return;
      setState(() {
        _helpEvents = events.where((e) => e.requestId == request.requestId).toList();
      });
    } catch (e) {
      if (mounted) {
        showApiError(context, e);
      }
    } finally {
      if (mounted) setState(() => _helpStatusLoading = false);
    }
  }

  Future<void> _handleComplete() async {
    if (widget.onComplete == null) return;
    setState(() => _isCompleting = true);
    final success = await widget.onComplete!.call();
    if (!mounted) return;
    setState(() => _isCompleting = false);
    if (success) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _handleConfirm() async {
    if (widget.onConfirm == null || !_allDecisionsMade) return;
    setState(() => _isSubmitting = true);
    final comment = _commentController.text.trim();
    final success = await widget.onConfirm!(
      availability: Map<int, bool>.from(_availabilityDecisions),
      comment: comment.isEmpty ? null : comment,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (success) {
      Navigator.pop(context, true);
    }
  }

  Widget _buildHelpRequestSection(AppTypography t, MaintenanceRequestResponseDto request) {
    final helpCount = request.requestedParts.where((part) => part.helpRequested == true).length;
    final hasActiveHelp = helpCount > 0;
    final status = deriveHelpRequestStatus(events: _helpEvents, requestId: request.requestId);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
      color: Colors.orange.withOpacity(0.06),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.support_agent, color: Colors.orange),
                const SizedBox(width: 8),
                Text('Запрос помощи', style: t.sectionTitle.copyWith(fontSize: 18)),
                const Spacer(),
                if (_helpStatusLoading)
                  const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange),
                  ),
                if (hasActiveHelp)
                  Chip(
                    label: Text('Активно: $helpCount', style: const TextStyle(color: Colors.orange)),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Colors.orange),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              hasActiveHelp
                  ? 'Механик запросил помощь по отмеченным позициям. Выберите действие или дождитесь ответа.'
                  : 'Если не получается выполнить работу, отправьте запрос помощи менеджеру/Администрации.',
              style: t.formInput,
            ),
            const SizedBox(height: 8),
            if (status.resolution != HelpRequestResolution.none)
              Row(
                children: [
                  Chip(
                    backgroundColor: _helpStatusColor(status.resolution).withOpacity(0.15),
                    label: Text(
                      'Статус: ${_helpStatusLabel(status.resolution)}',
                      style: TextStyle(color: _helpStatusColor(status.resolution)),
                    ),
                  ),
                  if (status.updatedAt != null) ...[
                    const SizedBox(width: 8),
                    Text(_formatDate(status.updatedAt!), style: t.formInput),
                  ]
                ],
              ),
            if (status.comment != null && status.comment!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(status.comment!, style: t.formInput),
              ),
            const SizedBox(height: 12),
            if (widget.canRequestHelp)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _helpSubmitting ? null : () => _openHelpRequestDialog(request),
                  icon: const Icon(Icons.priority_high, color: Colors.orange),
                  label: Text(hasActiveHelp ? 'Дополнить запрос помощи' : 'Нужна помощь',
                      style: const TextStyle(color: Colors.orange)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.orange),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            if (widget.canResolveHelp && hasActiveHelp) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _helpSubmitting ? null : () => _openResolveHelpDialog(request),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Ответить на запрос помощи'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openHelpRequestDialog(MaintenanceRequestResponseDto request) async {
    final partIds = request.requestedParts.map((e) => e.partId).toList();
    if (partIds.isEmpty) {
      _toast('Нет позиций для запроса помощи');
      return;
    }
    _selectedHelpPartIds = _selectedHelpPartIds.isEmpty ? partIds.toSet() : _selectedHelpPartIds;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: StatefulBuilder(builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Выберите позиции, по которым нужна помощь',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 12),
                  ...request.requestedParts.map((part) {
                    final checked = _selectedHelpPartIds.contains(part.partId);
                    return CheckboxListTile(
                      value: checked,
                      title: Text(part.partName ?? part.catalogNumber ?? 'Позиция ${part.partId}'),
                      subtitle: part.catalogNumber != null ? Text(part.catalogNumber!) : null,
                      onChanged: (value) {
                        setSheetState(() {
                          if (value == true) {
                            _selectedHelpPartIds.add(part.partId);
                          } else {
                            _selectedHelpPartIds.remove(part.partId);
                          }
                        });
                      },
                    );
                  }),
                  TextField(
                    controller: _helpCommentController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Комментарий к запросу',
                      hintText: 'Опишите, что требуется',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _helpSubmitting
                          ? null
                          : () async {
                              await _submitHelpRequest(request);
                              if (mounted) Navigator.pop(context);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _helpSubmitting
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Отправить запрос'),
                    ),
                  ),
                ],
              ),
            );
          }),
        );
      },
    );
  }

  Future<void> _openResolveHelpDialog(MaintenanceRequestResponseDto request) async {
    final helpParts = request.requestedParts.where((p) => p.helpRequested == true).toList();
    _selectedHelpPartIds = helpParts.map((e) => e.partId).toSet();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: StatefulBuilder(builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Решение по запросу помощи',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 12),
                  ...helpParts.map((part) {
                    final checked = _selectedHelpPartIds.contains(part.partId);
                    return CheckboxListTile(
                      value: checked,
                      title: Text(part.partName ?? part.catalogNumber ?? 'Позиция ${part.partId}'),
                      onChanged: (value) {
                        setSheetState(() {
                          if (value == true) {
                            _selectedHelpPartIds.add(part.partId);
                          } else {
                            _selectedHelpPartIds.remove(part.partId);
                          }
                        });
                      },
                    );
                  }),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: HelpResponseDecision.values.map((decision) {
                      final selected = _decision == decision;
                      return ChoiceChip(
                        label: Text(_decisionLabel(decision)),
                        selected: selected,
                        onSelected: (_) => setSheetState(() => _decision = decision),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  if (_decision == HelpResponseDecision.reassigned)
                    TextField(
                      controller: _reassignController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'ID нового механика',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  if (_decision != HelpResponseDecision.reassigned)
                    TextField(
                      controller: _helpCommentController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Комментарий',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _helpSubmitting
                          ? null
                          : () async {
                              await _submitHelpDecision(request);
                              if (mounted) Navigator.pop(context);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _helpSubmitting
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Сохранить решение'),
                    ),
                  ),
                ],
              ),
            );
          }),
        );
      },
    );
  }

  Future<void> _submitHelpRequest(MaintenanceRequestResponseDto request) async {
    final selected = _selectedHelpPartIds.isEmpty ? _partIds.toSet() : _selectedHelpPartIds;
    if (selected.isEmpty) {
      _toast('Выберите хотя бы одну позицию');
      return;
    }
    setState(() => _helpSubmitting = true);
    try {
      final payload = HelpRequestDto(
        partIds: selected.toList(),
        reason: _helpCommentController.text.trim().isEmpty ? null : _helpCommentController.text.trim(),
      );
      final updated = await _maintenanceRepository.requestHelp(request.requestId, payload);
      _applyUpdate(updated);
      _toast('Запрос помощи отправлен');
    } catch (e) {
      showApiError(context, e);
    } finally {
      if (mounted) setState(() => _helpSubmitting = false);
    }
  }

  Future<void> _submitHelpDecision(MaintenanceRequestResponseDto request) async {
    final selected = _selectedHelpPartIds;
    if (selected.isEmpty) {
      _toast('Нужно выбрать позиции для обработки');
      return;
    }
    if (_decision == HelpResponseDecision.reassigned && _reassignController.text.trim().isEmpty) {
      _toast('Укажите ID нового механика');
      return;
    }
    setState(() => _helpSubmitting = true);
    try {
      final dto = HelpResponseDto(
        partIds: selected.toList(),
        decision: _decision,
        reassignedMechanicId: _decision == HelpResponseDecision.reassigned
            ? int.tryParse(_reassignController.text.trim())
            : null,
        comment: _decision == HelpResponseDecision.reassigned ? null : _helpCommentController.text.trim(),
      );
      final updated = await _maintenanceRepository.resolveHelp(request.requestId, dto);
      _applyUpdate(updated);
      _toast('Решение сохранено');
    } catch (e) {
      showApiError(context, e);
    } finally {
      if (mounted) setState(() => _helpSubmitting = false);
    }
  }

  String _decisionLabel(HelpResponseDecision decision) {
    switch (decision) {
      case HelpResponseDecision.approved:
        return 'Подтвердить помощь';
      case HelpResponseDecision.reassigned:
        return 'Назначить другого';
      case HelpResponseDecision.declined:
        return 'Отклонить';
    }
  }

  Color _helpStatusColor(HelpRequestResolution resolution) {
    switch (resolution) {
      case HelpRequestResolution.approved:
        return Colors.green;
      case HelpRequestResolution.declined:
        return Colors.redAccent;
      case HelpRequestResolution.reassigned:
        return Colors.blue;
      case HelpRequestResolution.awaiting:
        return Colors.orange;
      case HelpRequestResolution.none:
      default:
        return AppColors.darkGray;
    }
  }

  String _helpStatusLabel(HelpRequestResolution resolution) {
    switch (resolution) {
      case HelpRequestResolution.approved:
        return 'Подтверждено';
      case HelpRequestResolution.declined:
        return 'Отклонено';
      case HelpRequestResolution.reassigned:
        return 'Переназначено';
      case HelpRequestResolution.awaiting:
        return 'Ожидает ответа';
      case HelpRequestResolution.none:
      default:
        return 'Без статуса';
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
