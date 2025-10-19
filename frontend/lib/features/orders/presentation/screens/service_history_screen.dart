import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/repositories/service_history_repository.dart';
import '../../../../models/service_history_dto.dart';
import '../../../../core/utils/net_ui.dart';
import '../../../../shared/widgets/nav/app_bottom_nav.dart';
import '../../../../core/utils/bottom_nav.dart';

/// Экран просмотра истории обслуживания
class ServiceHistoryScreen extends StatefulWidget {
  final int? clubId;
  
  const ServiceHistoryScreen({super.key, this.clubId});

  @override
  State<ServiceHistoryScreen> createState() => _ServiceHistoryScreenState();
}

class _ServiceHistoryScreenState extends State<ServiceHistoryScreen> {
  final _repo = ServiceHistoryRepository();
  List<dynamic> historyRecords = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => isLoading = true);
    try {
      // Если указан clubId, загружаем историю конкретного клуба
      // Иначе можно загрузить всю историю (если есть такой endpoint)
      if (widget.clubId != null) {
        final data = await _repo.getByClub(widget.clubId!);
        if (mounted) {
          setState(() {
            historyRecords = data;
            isLoading = false;
          });
        }
      } else {
        // Загружаем общую историю (если доступно)
        if (mounted) {
          setState(() {
            historyRecords = [];
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        showApiError(context, e);
      }
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
          'История обслуживания',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textDark),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: _loadHistory,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : historyRecords.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.history, size: 64, color: AppColors.darkGray),
                      SizedBox(height: 16),
                      Text(
                        'Нет записей об обслуживании',
                        style: TextStyle(fontSize: 16, color: AppColors.darkGray),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadHistory,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: historyRecords.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _ServiceHistoryCard(record: historyRecords[i]),
                  ),
                ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 0,
        onTap: (i) => BottomNavDirect.go(context, 0, i),
      ),
    );
  }
}

class _ServiceHistoryCard extends StatelessWidget {
  final dynamic record;

  const _ServiceHistoryCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final serviceId = record is Map ? record['serviceId'] : null;
    final serviceType = record is Map ? record['serviceType'] ?? 'UNKNOWN' : 'UNKNOWN';
    final description = record is Map ? record['description'] ?? '' : '';
    final clubName = record is Map ? record['clubName'] : null;
    final laneNumber = record is Map ? record['laneNumber'] : null;
    final mechanicName = record is Map ? record['performedByMechanicName'] : null;
    final totalCost = record is Map ? record['totalCost'] : null;
    final serviceDate = record is Map && record['serviceDate'] != null
        ? DateTime.tryParse(record['serviceDate'].toString())
        : null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            // Навигация к детальному просмотру
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Обслуживание №${serviceId ?? 'N/A'}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getServiceTypeText(serviceType),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 14, color: AppColors.darkGray),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),
                if (clubName != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: AppColors.darkGray),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          clubName.toString(),
                          style: const TextStyle(fontSize: 13, color: AppColors.darkGray),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (laneNumber != null) ...[
                        const SizedBox(width: 12),
                        const Icon(Icons.straighten, size: 16, color: AppColors.darkGray),
                        const SizedBox(width: 4),
                        Text(
                          'Дорожка $laneNumber',
                          style: const TextStyle(fontSize: 13, color: AppColors.darkGray),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                if (mechanicName != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 16, color: AppColors.darkGray),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          mechanicName.toString(),
                          style: const TextStyle(fontSize: 13, color: AppColors.darkGray),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  children: [
                    if (serviceDate != null) ...[
                      const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.darkGray),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(serviceDate),
                        style: const TextStyle(fontSize: 13, color: AppColors.darkGray),
                      ),
                    ],
                    if (totalCost != null) ...[
                      const Spacer(),
                      Text(
                        '${totalCost} ₽',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getServiceTypeText(String type) {
    switch (type) {
      case 'PREVENTIVE':
        return 'Профилактика';
      case 'REPAIR':
        return 'Ремонт';
      case 'MAINTENANCE':
        return 'Обслуживание';
      case 'INSPECTION':
        return 'Осмотр';
      default:
        return type;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
