import 'package:flutter_test/flutter_test.dart';
import 'package:bowling_market/models/free_mechanic_application_request_dto.dart';
import 'package:bowling_market/models/free_mechanic_application_response_dto.dart';

void main() {
  group('Free mechanic DTO', () {
    test('request serializes required fields', () {
      final req = FreeMechanicApplicationRequestDto(
        phone: '+79990000000',
        password: 'StrongPass1',
        fullName: 'Иван Мастер',
        birthDate: DateTime(1990, 5, 10),
        educationLevelId: 1,
        educationalInstitution: 'Боулинг колледж',
        totalExperienceYears: 5,
        bowlingExperienceYears: 3,
        isEntrepreneur: true,
        specializationId: 1,
        region: 'Москва',
        skills: 'Диагностика, обслуживание',
        advantages: 'Быстро реагирую',
      );

      final json = req.toJson();
      expect(json['phone'], '+79990000000');
      expect(json['birthDate'], '1990-05-10');
      expect(json['isEntrepreneur'], isTrue);
      expect(json['region'], 'Москва');
      expect(json['educationLevelId'], 1);
      expect(json['educationalInstitution'], 'Боулинг колледж');
    });

    test('response parsing keeps status and account type', () {
      final dto = FreeMechanicApplicationResponseDto.fromJson({
        'applicationId': 10,
        'status': 'APPROVED',
        'accountType': 'FREE_MECHANIC_PREMIUM',
        'comment': 'ok',
      });

      expect(dto.applicationId, 10);
      expect(dto.status, 'APPROVED');
      expect(dto.accountType, 'FREE_MECHANIC_PREMIUM');
      expect(dto.comment, 'ok');
    });
  });
}
