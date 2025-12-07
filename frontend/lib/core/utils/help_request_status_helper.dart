import '../../models/notification_event_dto.dart';

enum HelpRequestResolution {
  none,
  awaiting,
  approved,
  declined,
  reassigned,
}

class HelpRequestStatus {
  final HelpRequestResolution resolution;
  final String? comment;
  final List<int> partIds;
  final DateTime? updatedAt;

  const HelpRequestStatus({
    required this.resolution,
    this.comment,
    this.partIds = const [],
    this.updatedAt,
  });

  bool get isAwaiting => resolution == HelpRequestResolution.awaiting;
}

HelpRequestStatus deriveHelpRequestStatus({
  required List<NotificationEventDto> events,
  required int requestId,
}) {
  final relevant = events
      .where((event) =>
          event.requestId == requestId && event.isHelpEvent && event.createdAt != null)
      .toList()
    ..sort((a, b) {
      final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });

  if (relevant.isEmpty) {
    return const HelpRequestStatus(resolution: HelpRequestResolution.none);
  }

  final latest = relevant.first;
  switch (latest.typeKey) {
    case NotificationEventType.mechanicHelpRequested:
      return HelpRequestStatus(
        resolution: HelpRequestResolution.awaiting,
        comment: latest.payload,
        partIds: latest.partIds,
        updatedAt: latest.createdAt,
      );
    case NotificationEventType.mechanicHelpConfirmed:
      return HelpRequestStatus(
        resolution: HelpRequestResolution.approved,
        comment: latest.payload,
        partIds: latest.partIds,
        updatedAt: latest.createdAt,
      );
    case NotificationEventType.mechanicHelpDeclined:
      return HelpRequestStatus(
        resolution: HelpRequestResolution.declined,
        comment: latest.payload,
        partIds: latest.partIds,
        updatedAt: latest.createdAt,
      );
    case NotificationEventType.mechanicHelpReassigned:
      return HelpRequestStatus(
        resolution: HelpRequestResolution.reassigned,
        comment: latest.payload,
        partIds: latest.partIds,
        updatedAt: latest.createdAt,
      );
    case NotificationEventType.unknown:
    default:
      return HelpRequestStatus(
        resolution: HelpRequestResolution.none,
        comment: latest.payload,
        partIds: latest.partIds,
        updatedAt: latest.createdAt,
      );
  }
}
