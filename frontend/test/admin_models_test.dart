import 'package:flutter_test/flutter_test.dart';

import 'package:bowling_market/models/admin_appeal_dto.dart';
import 'package:bowling_market/models/admin_registration_application_dto.dart';
import 'package:bowling_market/models/admin_mechanic_status_change_dto.dart';

void main() {
  group('Admin DTO parsing', () {
    test('registration application parses extra fields', () {
      final dto = AdminRegistrationApplicationDto.fromJson({
        'userId': 4,
        'accountType': 'FREE_MECHANIC_BASIC',
        'applicationType': 'MECHANIC',
        'status': 'PENDING',
        'submittedAt': '2024-01-02T10:00:00Z',
        'payload': {'region': 'Москва', 'experience': 5},
      });

      expect(dto.userId, 4);
      expect(dto.applicationType, 'MECHANIC');
      expect(dto.status, 'PENDING');
      expect(dto.submittedAt, isNotNull);
      expect(dto.payload?['region'], 'Москва');
    });

    test('appeals include payload and ids', () {
      final appeal = AdminAppealDto.fromJson({
        'id': '42',
        'type': 'HELP_REQUEST',
        'message': 'Механик запросил помощь',
        'requestId': 12,
        'clubId': 3,
        'partIds': [1, '2'],
        'createdAt': '2024-02-01T12:00:00Z',
        'payload': {'lane': 5},
      });

      expect(appeal.id, '42');
      expect(appeal.partIds, [1, 2]);
      expect(appeal.payload?['lane'], 5);
      expect(appeal.createdAt, isNotNull);
    });

    test('mechanic status change toggles', () {
      final status = AdminMechanicStatusChangeDto.fromJson({
        'staffId': 10,
        'clubName': 'Test Club',
        'role': 'HEAD_MECHANIC',
        'isActive': false,
        'infoAccessRestricted': true,
      });

      expect(status.staffId, 10);
      expect(status.isActive, isFalse);
      expect(status.infoAccessRestricted, isTrue);
    });
  });
}

