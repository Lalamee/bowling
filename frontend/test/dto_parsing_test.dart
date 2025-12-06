import 'package:flutter_test/flutter_test.dart';
import 'package:bowling_market/models/login_response_dto.dart';
import 'package:bowling_market/models/user_info_dto.dart';
import 'package:bowling_market/models/maintenance_request_response_dto.dart';
import 'package:bowling_market/models/parts_catalog_response_dto.dart';
import 'package:bowling_market/models/work_log_dto.dart';
import 'package:bowling_market/models/service_history_dto.dart';
import 'package:bowling_market/models/mechanic_profile_dto.dart';

void main() {
  test('LoginResponseDto parse', () {
    final json = {'accessToken': 'a', 'refreshToken': 'b'};
    final dto = LoginResponseDto.fromJson(json);
    expect(dto.accessToken, 'a');
    expect(dto.refreshToken, 'b');
    expect(dto.toJson(), json);
  });

  test('UserInfoDto parse with date', () {
    final json = {
      'id': 1,
      'phone': '+79991112233',
      'roleId': 5,
      'accountTypeId': 2,
      'isVerified': true,
      'registrationDate': '2024-01-01'
    };
    final dto = UserInfoDto.fromJson(json);
    expect(dto.id, 1);
    expect(dto.registrationDate?.year, 2024);
  });

  test('MaintenanceRequestResponseDto parse nested', () {
    final json = {
      'requestId': 10,
      'clubId': 5,
      'requestedParts': [
        {
          'partId': 1,
          'catalogNumber': 'CN-1',
          'partName': 'Bearing',
          'quantity': 2
        }
      ]
    };
    final dto = MaintenanceRequestResponseDto.fromJson(json);
    expect(dto.requestId, 10);
    expect(dto.requestedParts.length, 1);
    expect(dto.requestedParts.first.partName, 'Bearing');
  });

  test('PartsCatalogResponseDto parse', () {
    final json = {
      'catalogId': 100,
      'catalogNumber': 'ABC-123',
      'manufacturerName': 'ACME',
      'availableQuantity': 3,
      'availabilityStatus': 'IN_STOCK'
    };
    final dto = PartsCatalogResponseDto.fromJson(json);
    expect(dto.catalogId, 100);
    expect(dto.catalogNumber, 'ABC-123');
    expect(dto.availabilityStatus, 'IN_STOCK');
  });

  test('WorkLogDto basic parse', () {
    final json = {
      'clubId': 1,
      'mechanicId': 2,
      'status': 'OPEN',
      'workType': 'REPAIR',
      'problemDescription': 'Broken belt',
      'partsUsed': [
        {
          'partName': 'Belt',
          'catalogNumber': 'B-1',
          'quantityUsed': 1,
          'unitCost': 10.5,
          'sourcedFrom': 'INVENTORY'
        }
      ],
      'statusHistory': [
        {
          'previousStatus': 'NEW',
          'newStatus': 'OPEN',
          'changedDate': '2024-02-01T10:00:00Z'
        }
      ]
    };
    final dto = WorkLogDto.fromJson(json);
    expect(dto.status, 'OPEN');
    expect(dto.partsUsed?.first.partName, 'Belt');
    expect(dto.statusHistory?.first.newStatus, 'OPEN');
  });

  test('ServiceHistoryDto basic parse', () {
    final json = {
      'clubId': 1,
      'serviceType': 'MAINTENANCE',
      'description': 'Quarterly check',
      'performedByMechanicId': 5,
      'partsUsed': [
        {
          'partName': 'Oil',
          'catalogNumber': 'OIL-1',
          'quantity': 1,
          'unitCost': 5.0
        }
      ]
    };
    final dto = ServiceHistoryDto.fromJson(json);
    expect(dto.serviceType, 'MAINTENANCE');
    expect(dto.partsUsed?.first.partName, 'Oil');
  });

  test('MechanicProfileDto covers verification and region fields', () {
    final json = {
      'fullName': 'Иван Тестовый',
      'birthDate': '1991-02-03',
      'educationLevelId': 2,
      'educationalInstitution': 'СПбГЭТУ',
      'totalExperienceYears': 8,
      'bowlingExperienceYears': 5,
      'isEntrepreneur': true,
      'isDataVerified': true,
      'verificationDate': '2024-05-10',
      'specializationId': 1,
      'skills': 'ремонт',
      'advantages': 'быстро',
      'workPlaces': 'Клуб А',
      'workPeriods': '2020-2024',
      'rating': 4.7,
      'region': 'Москва',
      'clubId': 3,
    };

    final profile = MechanicProfileDto.fromJson(json);
    expect(profile.isDataVerified, isTrue);
    expect(profile.verificationDate?.year, 2024);
    expect(profile.region, 'Москва');

    final back = profile.toJson();
    expect(back['verificationDate'], '2024-05-10');
    expect(back['region'], 'Москва');
  });
}
