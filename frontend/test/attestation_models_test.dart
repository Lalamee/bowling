import 'package:bowling_market/models/mechanic_directory_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AttestationApplication serializes and parses decision enums', () {
    final app = AttestationApplication(
      id: 5,
      userId: 10,
      mechanicProfileId: 22,
      clubId: 3,
      status: AttestationDecisionStatus.pending,
      requestedGrade: MechanicGrade.senior,
      comment: 'Опыт 5 лет',
    );

    final json = app.toJson();
    expect(json['status'], 'PENDING');
    expect(json['requestedGrade'], 'SENIOR');

    final parsed = AttestationApplication.fromJson(json);
    expect(parsed.status, AttestationDecisionStatus.pending);
    expect(parsed.requestedGrade, MechanicGrade.senior);
    expect(parsed.comment, 'Опыт 5 лет');
  });

  test('SpecialistCard parses grading and dates', () {
    final card = SpecialistCard.fromJson({
      'profileId': 7,
      'userId': 2,
      'fullName': 'Тестовый Механик',
      'region': 'Москва',
      'specializationId': 4,
      'skills': 'Механика, электрика',
      'advantages': 'Работа в ночные смены',
      'totalExperienceYears': 6,
      'bowlingExperienceYears': 4,
      'isEntrepreneur': true,
      'rating': 4.7,
      'attestedGrade': 'LEAD',
      'accountType': 'FREE_MECHANIC_PREMIUM',
      'verificationDate': '2024-05-01',
      'clubs': ['Strike City'],
    });

    expect(card.attestedGrade, MechanicGrade.lead);
    expect(card.region, 'Москва');
    expect(card.clubs, contains('Strike City'));
    expect(card.verificationDate?.year, 2024);
  });
}
