import 'package:flutter_test/flutter_test.dart';

import '../lib/models/admin_registration_application_dto.dart';
import '../lib/models/admin_complaint_dto.dart';

void main() {
  test('AdminRegistrationApplicationDto serializes', () {
    final dto = AdminRegistrationApplicationDto.fromJson({
      'userId': '10',
      'profileId': 5,
      'phone': '+79995550001',
      'fullName': 'Иван Тест',
      'role': 'MECHANIC',
      'accountType': 'FREE_MECHANIC_BASIC',
      'profileType': 'INDIVIDUAL',
      'isActive': true,
      'isVerified': false,
      'isProfileVerified': true,
      'clubId': 2,
      'clubName': 'Тест клуб',
      'submittedAt': '2024-05-01T10:00:00Z',
    });

    expect(dto.userId, 10);
    expect(dto.accountType, 'FREE_MECHANIC_BASIC');
    expect(dto.clubName, 'Тест клуб');
    expect(dto.toJson()['fullName'], 'Иван Тест');
  });

  test('AdminComplaintDto serializes', () {
    final dto = AdminComplaintDto.fromJson({
      'reviewId': 7,
      'supplierId': '3',
      'clubId': 1,
      'userId': 9,
      'complaintStatus': 'OPEN',
      'complaintResolved': false,
      'rating': 2,
      'comment': 'Недопоставка',
      'complaintTitle': 'Нет позиций',
      'resolutionNotes': 'Ожидание поставки',
    });

    expect(dto.reviewId, 7);
    expect(dto.complaintStatus, 'OPEN');
    expect(dto.complaintResolved, isFalse);
    expect(dto.toJson()['complaintTitle'], 'Нет позиций');
  });
}
