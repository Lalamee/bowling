import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/repositories/worklogs_repository.dart';
import '../../../../models/work_log_dto.dart';
import '../../../../models/work_log_search_dto.dart';
import '../../../../core/utils/net_ui.dart';
import '../../../../shared/widgets/nav/app_bottom_nav.dart';
import '../../../../core/utils/bottom_nav.dart';

/// Экран просмотра рабочих журналов
class WorkLogsScreen extends StatefulWidget {
  const WorkLogsScreen({super.key});

  @override
  State<WorkLogsScreen> createState() => _WorkLogsScreenState();
}

class _WorkLogsScreenState extends State<WorkLogsScreen> {
  final _repo = WorklogsRepository();
  List<WorkLogDto> workLogs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWorkLogs();
  }

  Future<void> _loadWorkLogs() async {
    setState(() => isLoading = true);
    try {
      final page = await _repo.search(WorkLogSearchDto());
      if (mounted) {
        setState(() {
          workLogs = page.content;
          isLoading = false;
        });
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
          'Рабочие журналы',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textDark),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: _loadWorkLogs,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : workLogs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.work_outline, size: 64, color: AppColors.darkGray),
                      SizedBox(height: 16),
                      Text(
                        'Нет рабочих журналов',
                        style: TextStyle(fontSize: 16, color: AppColors.darkGray),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadWorkLogs,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: workLogs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _WorkLogCard(workLog: workLogs[i]),
                  ),
                ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 0,
        onTap: (i) => BottomNavDirect.go(context, 0, i),
      ),
    );
  }
}

class _WorkLogCard extends StatelessWidget {
  final WorkLogDto workLog;

  const _WorkLogCard({required this.workLog});

  @override
  Widget build(BuildContext context) {
    final logId = workLog.logId;
    final status = workLog.status;
    final problemDescription = workLog.problemDescription;
    final clubName = workLog.clubName;
    final mechanicName = workLog.mechanicName;
    final createdDate = workLog.createdDate;

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
                        'Журнал №${logId ?? 'N/A'}',
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
                        color: _getStatusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getStatusText(status),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(status),
                        ),
                      ),
                    ),
                  ],
                ),
                if (problemDescription.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    problemDescription,
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
                if (createdDate != null)
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.darkGray),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(createdDate),
                        style: const TextStyle(fontSize: 13, color: AppColors.darkGray),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'CREATED':
        return 'Создано';
      case 'ASSIGNED':
        return 'Назначено';
      case 'IN_PROGRESS':
        return 'В работе';
      case 'ON_HOLD':
        return 'На паузе';
      case 'COMPLETED':
        return 'Завершено';
      case 'VERIFIED':
        return 'Проверено';
      case 'CLOSED':
        return 'Закрыто';
      case 'CANCELLED':
        return 'Отменено';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'COMPLETED':
        return Colors.green;
      case 'VERIFIED':
        return Colors.blue;
      case 'CLOSED':
        return Colors.blueGrey;
      case 'CANCELLED':
        return Colors.red;
      case 'IN_PROGRESS':
        return AppColors.primary;
      case 'ASSIGNED':
        return Colors.orange;
      case 'ON_HOLD':
        return Colors.deepPurple;
      case 'CREATED':
        return AppColors.darkGray;
      default:
        return AppColors.darkGray;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
