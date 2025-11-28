import 'package:flutter_test/flutter_test.dart';
import 'package:bowling_market/models/technical_info_dto.dart';
import 'package:bowling_market/models/maintenance_schedule_dto.dart';
import 'package:bowling_market/models/service_journal_entry_dto.dart';
import 'package:bowling_market/models/notification_event_dto.dart';
import 'package:bowling_market/models/warning_dto.dart';

void main() {
  test('TechnicalInfoDto parses schedules and components', () {
    final dto = TechnicalInfoDto.fromJson({
      'equipmentId': 5,
      'model': 'Brunswick GS-X',
      'productionYear': 2020,
      'lanesCount': 10,
      'conditionPercentage': 85,
      'lastMaintenanceDate': '2024-12-01',
      'nextMaintenanceDate': '2025-01-15',
      'components': [
        {'componentId': 1, 'name': 'Датчик скорости'},
      ],
      'schedules': [
        {'scheduleId': 7, 'maintenanceType': 'INSPECTION', 'scheduledDate': '2025-01-15', 'critical': true}
      ]
    });

    expect(dto.equipmentId, 5);
    expect(dto.components.first.name, 'Датчик скорости');
    expect(dto.schedules.first, isA<MaintenanceScheduleDto>());
    expect(dto.nextMaintenanceDate?.month, 1);
  });

  test('ServiceJournalEntryDto parses dates and parts', () {
    final dto = ServiceJournalEntryDto.fromJson({
      'workLogId': 11,
      'requestId': 22,
      'laneNumber': 3,
      'equipmentModel': 'AMF 90XLi',
      'workType': 'INSPECTION',
      'status': 'COMPLETED',
      'createdDate': '2025-02-02T10:00:00',
      'completedDate': '2025-02-03T11:00:00',
      'mechanicName': 'Иванов И.',
      'partsUsed': [
        {'partName': 'Датчик', 'catalogNumber': 'P-1', 'quantityUsed': 1, 'unitCost': 10, 'sourcedFrom': 'stock'}
      ]
    });

    expect(dto.workLogId, 11);
    expect(dto.partsUsed, isNotEmpty);
    expect(dto.createdDate?.year, 2025);
    expect(dto.completedDate?.day, 3);
  });

  test('NotificationEventDto parses identifiers', () {
    final dto = NotificationEventDto.fromJson({
      'id': 'uuid-1',
      'type': 'MECHANIC_HELP_REQUESTED',
      'message': 'Механик запросил помощь',
      'clubId': 9,
      'createdAt': '2025-03-01T09:30:00',
      'partIds': [1, 2, 3]
    });

    expect(dto.id, 'uuid-1');
    expect(dto.partIds.length, 3);
    expect(dto.clubId, 9);
  });

  test('WarningDto marks overdue type', () {
    final dto = WarningDto.fromJson({
      'type': 'MAINTENANCE_OVERDUE',
      'message': 'Просроченное ТО',
      'dueDate': '2025-01-10'
    });

    expect(dto.message, contains('ТО'));
    expect(dto.dueDate?.year, 2025);
  });
}
