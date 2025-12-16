import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/repositories/purchase_orders_repository.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/net_ui.dart';
import '../../../../models/purchase_order_acceptance_request_dto.dart';
import '../../../../models/purchase_order_detail_dto.dart';
import '../../../../models/purchase_order_summary_dto.dart';
import '../../../../models/supplier_complaint_request_dto.dart';
import '../../../../models/supplier_complaint_status_update_dto.dart';
import '../../../../models/supplier_review_request_dto.dart';

class SupplyOrderDetailsScreen extends StatefulWidget {
  final int orderId;
  final PurchaseOrderSummaryDto? initialSummary;

  const SupplyOrderDetailsScreen({super.key, required this.orderId, this.initialSummary});

  @override
  State<SupplyOrderDetailsScreen> createState() => _SupplyOrderDetailsScreenState();
}

class _SupplyOrderDetailsScreenState extends State<SupplyOrderDetailsScreen> {
  final PurchaseOrdersRepository _repository = PurchaseOrdersRepository();
  final DateFormat _dateFormat = DateFormat('dd.MM.yyyy');
  PurchaseOrderDetailDto? _detail;
  bool _loading = true;
  bool _error = false;
  bool _acceptanceInProgress = false;
  bool _feedbackInProgress = false;
  bool _complaintStatusInProgress = false;
  final Map<int, _PartAcceptanceState> _partStates = {};
  final TextEditingController _supplierInnController = TextEditingController();
  final TextEditingController _supplierNameController = TextEditingController();
  final TextEditingController _supplierContactController = TextEditingController();
  final TextEditingController _supplierPhoneController = TextEditingController();
  final TextEditingController _supplierEmailController = TextEditingController();
  bool _supplierVerified = false;
  static const List<String> _complaintStatuses = ['DRAFT', 'SENT', 'IN_PROGRESS', 'RESOLVED', 'CLOSED'];
  static const Map<String, String> _complaintStatusLabels = {
    'DRAFT': 'Черновик',
    'SENT': 'Отправлена',
    'IN_PROGRESS': 'В работе',
    'RESOLVED': 'Решена',
    'CLOSED': 'Закрыта',
  };

  static const Map<String, String> _statusLabels = {
    'PENDING': 'Ожидает',
    'CONFIRMED': 'Подтверждена',
    'PARTIALLY_COMPLETED': 'Частично принята',
    'COMPLETED': 'Полностью принята',
    'REJECTED': 'Отклонена',
    'CANCELED': 'Отменена',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final state in _partStates.values) {
      state.dispose();
    }
    _supplierInnController.dispose();
    _supplierNameController.dispose();
    _supplierContactController.dispose();
    _supplierPhoneController.dispose();
    _supplierEmailController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final detail = await _repository.get(widget.orderId);
      if (!mounted) return;
      _applyDetail(detail);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
      });
      showApiError(context, e);
    }
  }

  void _applyDetail(PurchaseOrderDetailDto detail) {
    for (final state in _partStates.values) {
      state.dispose();
    }
    _partStates.clear();
    for (final part in detail.parts) {
      final decision = _decisionFromStatus(part.status);
      final quantity = part.acceptedQuantity ?? part.orderedQuantity ?? 0;
      final comment = part.acceptanceComment ?? part.rejectionReason ?? '';
      _partStates[part.partId] = _PartAcceptanceState(
        decision: decision,
        quantity: quantity,
        comment: comment,
        storageLocation: part.inventoryLocation,
      );
    }
    setState(() {
      _detail = detail;
      _loading = false;
      _error = false;
      _supplierInnController.text = detail.supplierInn ?? '';
      _supplierNameController.text = detail.supplierName ?? '';
      _supplierContactController.text = detail.supplierContact ?? '';
      _supplierPhoneController.text = detail.supplierPhone ?? '';
      _supplierEmailController.text = detail.supplierEmail ?? '';
      _supplierVerified = false;
    });
  }

  bool get _canAccept {
    final detail = _detail;
    if (detail == null) return false;
    return detail.status == 'PENDING' || detail.status == 'CONFIRMED';
  }

  @override
  Widget build(BuildContext context) {
    final summary = _detail ?? widget.initialSummary;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          summary?.supplierName ?? 'Поставка #${widget.orderId}',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textDark),
        ),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh, color: AppColors.primary),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error || _detail == null) {
      return _ErrorState(onRetry: _load);
    }
    final detail = _detail!;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _buildSummary(detail),
          const SizedBox(height: 12),
          _buildSupplierForm(),
          const SizedBox(height: 16),
          Text('Состав поставки', style: _sectionTitle),
          const SizedBox(height: 8),
          ...detail.parts.map(_buildPartCard),
          if (_canAccept) ...[
            const SizedBox(height: 16),
            _buildAcceptanceButton(),
          ],
          const SizedBox(height: 24),
          _buildFeedbackActions(detail),
          const SizedBox(height: 12),
          _buildReviews(detail),
          const SizedBox(height: 24),
          _buildComplaints(detail),
        ],
      ),
    );
  }

  Widget _buildSummary(PurchaseOrderDetailDto detail) {
    final lines = <String>[];
    if (detail.supplierInn != null) {
      lines.add('ИНН: ${detail.supplierInn}');
    }
    if (detail.expectedDeliveryDate != null) {
      lines.add('Ожидалось: ${_dateFormat.format(detail.expectedDeliveryDate!)}');
    }
    if (detail.actualDeliveryDate != null) {
      lines.add('Принято: ${_dateFormat.format(detail.actualDeliveryDate!)}');
    }
    if (detail.clubName != null) {
      lines.add('Клуб: ${detail.clubName}');
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(detail.supplierName ?? 'Поставка #${detail.orderId}', style: _sectionTitle),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _StatusBadge(
                label: _statusLabels[detail.status?.toUpperCase()] ?? detail.status ?? '-',
                color: AppColors.primary,
              ),
              if (detail.hasComplaint)
                const _StatusBadge(label: 'Есть претензии', color: Colors.redAccent),
              if (detail.hasReview)
                const _StatusBadge(label: 'Есть оценки', color: Colors.green),
            ],
          ),
          const SizedBox(height: 8),
          if (lines.isNotEmpty)
            Text(lines.join(' • '), style: const TextStyle(color: AppColors.darkGray)),
          const SizedBox(height: 8),
          if (detail.supplierContact != null)
            Text('Контакт: ${detail.supplierContact}', style: const TextStyle(color: AppColors.darkGray)),
          if (detail.supplierPhone != null)
            Text('Телефон: ${detail.supplierPhone}', style: const TextStyle(color: AppColors.darkGray)),
          if (detail.supplierEmail != null)
            Text('Email: ${detail.supplierEmail}', style: const TextStyle(color: AppColors.darkGray)),
        ],
      ),
    );
  }

  Widget _buildSupplierForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Данные поставщика', style: _sectionTitle),
          const SizedBox(height: 12),
          TextField(
            controller: _supplierInnController,
            decoration: const InputDecoration(labelText: 'ИНН поставщика*', border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _supplierNameController,
            decoration: const InputDecoration(labelText: 'Наименование поставщика', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _supplierContactController,
            decoration: const InputDecoration(labelText: 'Контактное лицо', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _supplierPhoneController,
            decoration: const InputDecoration(labelText: 'Телефон', border: OutlineInputBorder()),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _supplierEmailController,
            decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 4),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _supplierVerified,
            onChanged: (val) => setState(() => _supplierVerified = val ?? false),
            title: const Text('Поставщик подтверждён'),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
    );
  }

  Widget _buildPartCard(PurchaseOrderPartDto part) {
    final state = _partStates[part.partId];
    final decision = state?.decision ?? AcceptanceDecision.accepted;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(part.partName ?? 'Деталь #${part.partId}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          if (part.catalogNumber != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Каталожный номер: ${part.catalogNumber}', style: const TextStyle(color: AppColors.darkGray)),
            ),
          if (part.orderedQuantity != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Заказано: ${part.orderedQuantity}', style: const TextStyle(color: AppColors.darkGray)),
            ),
          if (part.acceptedQuantity != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Принято ранее: ${part.acceptedQuantity}', style: const TextStyle(color: AppColors.darkGray)),
            ),
          if (!_canAccept && part.acceptanceComment != null && part.acceptanceComment!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Комментарий: ${part.acceptanceComment}', style: const TextStyle(color: AppColors.darkGray)),
            ),
          if (part.inventoryLocation != null || part.warehouseId != null || part.inventoryId != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Размещение: ${part.inventoryLocation ?? 'на складе #${part.warehouseId ?? '-'}'}'
                '${part.inventoryId != null ? ' • инвентаризация #${part.inventoryId}' : ''}',
                style: const TextStyle(color: AppColors.darkGray),
              ),
            ),
          if (_canAccept && state != null) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<AcceptanceDecision>(
              value: decision,
              decoration: const InputDecoration(labelText: 'Решение по позиции'),
              items: const [
                DropdownMenuItem(value: AcceptanceDecision.accepted, child: Text('Принять полностью')),
                DropdownMenuItem(value: AcceptanceDecision.partial, child: Text('Принять частично')),
                DropdownMenuItem(value: AcceptanceDecision.rejected, child: Text('Отказаться')),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  state.decision = value;
                  if (value == AcceptanceDecision.rejected) {
                    state.quantityController.text = '0';
                  } else if (state.quantityController.text.isEmpty) {
                    state.quantityController.text = (part.orderedQuantity ?? 0).toString();
                  }
                });
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: state.quantityController,
              enabled: decision != AcceptanceDecision.rejected,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Принятое количество'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: state.commentController,
              decoration: const InputDecoration(labelText: 'Комментарий/причина'),
              maxLines: 2,
            ),
            if (decision != AcceptanceDecision.rejected) ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: state.storageController,
                decoration: const InputDecoration(labelText: 'Адрес хранения / зона складирования'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: state.shelfController,
                      decoration: const InputDecoration(labelText: 'Полка/стеллаж'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: state.cellController,
                      decoration: const InputDecoration(labelText: 'Ячейка/ряд'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: state.placementNotesController,
                decoration: const InputDecoration(labelText: 'Примечание к размещению'),
                maxLines: 2,
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildAcceptanceButton() {
    return ElevatedButton.icon(
      onPressed: _acceptanceInProgress ? null : _submitAcceptance,
      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(48)),
      icon: _acceptanceInProgress
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.check_circle_outline),
      label: const Text('Подтвердить приёмку'),
    );
  }

  Widget _buildFeedbackActions(PurchaseOrderDetailDto detail) {
    final isArchived = !_canAccept;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: (_feedbackInProgress || !isArchived) ? null : _handleAddReview,
            icon: const Icon(Icons.star_rate_rounded, color: AppColors.primary),
            label: const Text('Оставить оценку'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _feedbackInProgress ? null : _handleAddComplaint,
            icon: const Icon(Icons.report_gmailerrorred_outlined, color: Colors.redAccent),
            label: const Text('Претензия'),
          ),
        ),
      ],
    );
  }

  Widget _buildReviews(PurchaseOrderDetailDto detail) {
    return _FeedbackList(
      title: 'Отзывы',
      emptyText: 'Пока нет оценок',
      items: detail.reviews,
    );
  }

  Widget _buildComplaints(PurchaseOrderDetailDto detail) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Претензии', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark)),
          const SizedBox(height: 12),
          if (detail.complaints.isEmpty)
            const Text('Претензии не создавались', style: TextStyle(color: AppColors.darkGray))
          else
            ...detail.complaints.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Статус: ${_describeComplaintStatus(item.complaintStatus)}',
                      style: const TextStyle(color: AppColors.darkGray),
                    ),
                    if (item.complaintTitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('Тема: ${item.complaintTitle}', style: const TextStyle(color: AppColors.textDark)),
                      ),
                    if (item.comment != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(item.comment!, style: const TextStyle(color: AppColors.textDark)),
                      ),
                    if (item.resolutionNotes != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('Решение: ${item.resolutionNotes}', style: const TextStyle(color: AppColors.darkGray)),
                      ),
                    if (_complaintStatusInProgress)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: LinearProgressIndicator(minHeight: 2),
                      )
                    else
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => _handleComplaintStatus(item),
                          icon: const Icon(Icons.edit, color: AppColors.primary),
                          label: const Text('Обновить статус'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _submitAcceptance() async {
    final detail = _detail;
    if (detail == null) return;
    final supplierInn = _supplierInnController.text.trim();
    if (supplierInn.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Введите ИНН поставщика для приёмки')));
      return;
    }
    for (final part in detail.parts) {
      final state = _partStates[part.partId];
      if (state == null) continue;
      final ordered = part.orderedQuantity ?? 0;
      final qty = state.decision == AcceptanceDecision.rejected ? 0 : state.quantity;
      if (qty < 0 || qty > ordered) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Количество по ${part.partName ?? 'позиции'} не может превышать заказанное ($ordered)')),
        );
        return;
      }
      if (state.decision == AcceptanceDecision.accepted && qty != ordered) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Для полного приёма позиции ${part.partName ?? part.partId} нужно принять $ordered шт.')),
        );
        return;
      }
      if (state.decision == AcceptanceDecision.partial && qty >= ordered) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Укажите принятие меньше $ordered шт. для частичной приёмки.')),
        );
        return;
      }
      if (state.decision != AcceptanceDecision.rejected && qty > 0 && state.storageLocation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Укажите место хранения для ${part.partName ?? part.partId}')),
        );
        return;
      }
    }
    setState(() => _acceptanceInProgress = true);
    try {
      final partsPayload = detail.parts.map((part) {
        final state = _partStates[part.partId];
        if (state == null) return null;
        final status = _statusForDecision(state.decision);
        final accepted = state.decision == AcceptanceDecision.rejected ? 0 : state.quantity;
        return PartAcceptanceDto(
          partId: part.partId,
          status: status,
          acceptedQuantity: accepted,
          comment: state.comment,
          storageLocation: state.storageLocation,
          shelfCode: state.shelfCode,
          cellCode: state.cellCode,
          placementNotes: state.placementNotes,
        );
      }).whereType<PartAcceptanceDto>().toList();
      if (partsPayload.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Нет данных для приёмки')));
        return;
      }
      final updated = await _repository.accept(
        detail.orderId,
        PurchaseOrderAcceptanceRequestDto(
          parts: partsPayload,
          supplierInn: supplierInn,
          supplierName: _supplierNameController.text.trim().isEmpty ? null : _supplierNameController.text.trim(),
          supplierContactPerson:
              _supplierContactController.text.trim().isEmpty ? null : _supplierContactController.text.trim(),
          supplierPhone: _supplierPhoneController.text.trim().isEmpty ? null : _supplierPhoneController.text.trim(),
          supplierEmail: _supplierEmailController.text.trim().isEmpty ? null : _supplierEmailController.text.trim(),
          supplierVerified: _supplierVerified,
        ),
      );
      if (!mounted) return;
      _applyDetail(updated);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Приёмка сохранена')));
    } catch (e) {
      if (!mounted) return;
      showApiError(context, e);
    } finally {
      if (mounted) {
        setState(() => _acceptanceInProgress = false);
      }
    }
  }

  Future<void> _handleAddReview() async {
    final request = await _showReviewDialog();
    if (request == null) return;
    setState(() => _feedbackInProgress = true);
    try {
      final updated = await _repository.review(widget.orderId, request);
      if (!mounted) return;
      _applyDetail(updated);
    } catch (e) {
      if (!mounted) return;
      showApiError(context, e);
    } finally {
      if (mounted) {
        setState(() => _feedbackInProgress = false);
      }
    }
  }

  Future<void> _handleAddComplaint() async {
    final request = await _showComplaintDialog();
    if (request == null) return;
    setState(() => _feedbackInProgress = true);
    try {
      final updated = await _repository.complaint(widget.orderId, request);
      if (!mounted) return;
      _applyDetail(updated);
    } catch (e) {
      if (!mounted) return;
      showApiError(context, e);
    } finally {
      if (mounted) {
        setState(() => _feedbackInProgress = false);
      }
    }
  }

  Future<void> _handleComplaintStatus(SupplierReviewDto item) async {
    final update = await _showComplaintStatusDialog(item);
    if (update == null) return;
    setState(() => _complaintStatusInProgress = true);
    try {
      final updated = await _repository.updateComplaintStatus(
        widget.orderId,
        item.reviewId,
        update,
      );
      if (!mounted) return;
      _applyDetail(updated);
    } catch (e) {
      if (!mounted) return;
      showApiError(context, e);
    } finally {
      if (mounted) setState(() => _complaintStatusInProgress = false);
    }
  }

  Future<SupplierReviewRequestDto?> _showReviewDialog() {
    final ratingNotifier = ValueNotifier<int>(5);
    final commentController = TextEditingController();
    return showDialog<SupplierReviewRequestDto>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Оценка поставщика'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Выберите оценку (1-5)'),
            const SizedBox(height: 8),
            ValueListenableBuilder<int>(
              valueListenable: ratingNotifier,
              builder: (context, value, _) => DropdownButton<int>(
                value: value,
                items: List.generate(5, (index) => index + 1)
                    .map((rating) => DropdownMenuItem(value: rating, child: Text('$rating')))
                    .toList(),
                onChanged: (val) {
                  if (val != null) ratingNotifier.value = val;
                },
              ),
            ),
            TextField(
              controller: commentController,
              decoration: const InputDecoration(labelText: 'Комментарий'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () {
              final comment = commentController.text.trim();
              if (comment.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Добавьте комментарий')));
                return;
              }
              Navigator.pop(
                context,
                SupplierReviewRequestDto(rating: ratingNotifier.value, comment: comment),
              );
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    ).then((value) {
      ratingNotifier.dispose();
      commentController.dispose();
      return value;
    });
  }

  Future<SupplierComplaintRequestDto?> _showComplaintDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String status = 'SENT';
    return showDialog<SupplierComplaintRequestDto>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Новая претензия'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Тема'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Описание проблемы'),
                minLines: 3,
                maxLines: 4,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: status,
                decoration: const InputDecoration(labelText: 'Статус претензии'),
                items: const [
                  DropdownMenuItem(value: 'DRAFT', child: Text('Черновик')),
                  DropdownMenuItem(value: 'SENT', child: Text('Отправлена')),
                  DropdownMenuItem(value: 'IN_PROGRESS', child: Text('В работе')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    status = value;
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () {
              final title = titleController.text.trim();
              final description = descriptionController.text.trim();
              if (title.isEmpty || description.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Заполните тему и описание')),
                );
                return;
              }
              Navigator.pop(
                context,
                SupplierComplaintRequestDto(title: title, description: description, status: status),
              );
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    ).then((value) {
      titleController.dispose();
      descriptionController.dispose();
      return value;
    });
  }

  Future<SupplierComplaintStatusUpdateDto?> _showComplaintStatusDialog(SupplierReviewDto item) {
    String status = item.complaintStatus ?? 'IN_PROGRESS';
    bool? resolved = item.complaintResolved;
    final resolutionController = TextEditingController(text: item.resolutionNotes ?? '');
    return showDialog<SupplierComplaintStatusUpdateDto>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Обновление статуса спора'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: status,
              decoration: const InputDecoration(labelText: 'Статус'),
              items: _complaintStatuses
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(_complaintStatusLabels[value] ?? value),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) status = value;
              },
            ),
            CheckboxListTile(
              value: resolved ?? false,
              onChanged: (val) => resolved = val ?? false,
              title: const Text('Спор закрыт/решён'),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            TextField(
              controller: resolutionController,
              decoration: const InputDecoration(labelText: 'Комментарий решения'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(
                context,
                SupplierComplaintStatusUpdateDto(
                  status: status,
                  resolved: resolved,
                  resolutionNotes: resolutionController.text.trim().isEmpty
                      ? null
                      : resolutionController.text.trim(),
                ),
              );
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    ).then((value) {
      resolutionController.dispose();
      return value;
    });
  }

  String _describeComplaintStatus(String? status) {
    if (status == null) return '-';
    final normalized = status.trim().toUpperCase();
    if (normalized.isEmpty) return '-';
    return _complaintStatusLabels[normalized] ?? status;
  }

  AcceptanceDecision _decisionFromStatus(String? status) {
    switch (status) {
      case 'REJECTED':
        return AcceptanceDecision.rejected;
      case 'PARTIALLY_ACCEPTED':
        return AcceptanceDecision.partial;
      default:
        return AcceptanceDecision.accepted;
    }
  }

  String _statusForDecision(AcceptanceDecision decision) {
    switch (decision) {
      case AcceptanceDecision.rejected:
        return 'REJECTED';
      case AcceptanceDecision.partial:
        return 'PARTIALLY_ACCEPTED';
      case AcceptanceDecision.accepted:
      default:
        return 'ACCEPTED';
    }
  }

  TextStyle get _sectionTitle => const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textDark);
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _FeedbackList extends StatelessWidget {
  final String title;
  final String emptyText;
  final List<SupplierReviewDto> items;
  final bool complaint;

  const _FeedbackList({
    required this.title,
    required this.emptyText,
    required this.items,
    this.complaint = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark)),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Text(emptyText, style: const TextStyle(color: AppColors.darkGray))
          else ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (item.rating != null && !complaint)
                          Row(
                            children: List.generate(
                              item.rating!,
                              (_) => const Icon(Icons.star, size: 16, color: Colors.amber),
                            ),
                          ),
                        if (complaint && item.complaintStatus != null)
                          Text(
                            'Статус: ${_describeComplaintStatus(item.complaintStatus)}',
                            style: const TextStyle(color: AppColors.darkGray),
                          ),
                      ],
                    ),
                    if (item.comment != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(item.comment!, style: const TextStyle(color: AppColors.textDark)),
                      ),
                    if (complaint && item.complaintTitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('Тема: ${item.complaintTitle}', style: const TextStyle(color: AppColors.darkGray)),
                      ),
                    if (item.createdAt != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(DateFormat('dd.MM.yyyy').format(item.createdAt!), style: const TextStyle(color: AppColors.darkGray)),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, size: 64, color: AppColors.darkGray),
          const SizedBox(height: 12),
          const Text('Не удалось загрузить поставку', style: TextStyle(color: AppColors.darkGray)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }
}

class _PartAcceptanceState {
  AcceptanceDecision decision;
  final TextEditingController quantityController;
  final TextEditingController commentController;
  final TextEditingController storageController;
  final TextEditingController shelfController;
  final TextEditingController cellController;
  final TextEditingController placementNotesController;

  _PartAcceptanceState({
    required this.decision,
    required int quantity,
    String? comment,
    String? storageLocation,
  })
      : quantityController = TextEditingController(text: quantity.toString()),
        commentController = TextEditingController(text: comment ?? ''),
        storageController = TextEditingController(text: storageLocation ?? ''),
        shelfController = TextEditingController(),
        cellController = TextEditingController(),
        placementNotesController = TextEditingController();

  int get quantity => int.tryParse(quantityController.text) ?? 0;
  String? get comment => commentController.text.trim().isEmpty ? null : commentController.text.trim();
  String? get storageLocation => storageController.text.trim().isEmpty ? null : storageController.text.trim();
  String? get shelfCode => shelfController.text.trim().isEmpty ? null : shelfController.text.trim();
  String? get cellCode => cellController.text.trim().isEmpty ? null : cellController.text.trim();
  String? get placementNotes =>
      placementNotesController.text.trim().isEmpty ? null : placementNotesController.text.trim();

  void dispose() {
    quantityController.dispose();
    commentController.dispose();
    storageController.dispose();
    shelfController.dispose();
    cellController.dispose();
    placementNotesController.dispose();
  }
}

enum AcceptanceDecision { accepted, partial, rejected }
