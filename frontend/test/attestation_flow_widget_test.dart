import 'package:bowling_market/api/api_core.dart';
import 'package:bowling_market/features/specialists/presentation/screens/admin_attestation_screen.dart';
import 'package:bowling_market/features/specialists/presentation/screens/attestation_applications_screen.dart';
import 'package:bowling_market/features/specialists/presentation/screens/specialists_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:bowling_market/models/mechanic_directory_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ApiCore core;
  late DioAdapter adapter;
  final List<Map<String, dynamic>> applications = [];
  final List<Map<String, dynamic>> specialists = [];

  setUp(() async {
    applications.clear();
    specialists.clear();
    core = ApiCore();
    await core.init(baseUrl: 'http://localhost');
    adapter = DioAdapter(dio: core.dio);
    core.dio.httpClientAdapter = adapter;
    await core.storage.write(key: 'jwt_token', value: 'token');

    adapter.onGet('/api/auth/me', (server) {
      server.reply(200, {
        'userId': 101,
        'role': 'MECHANIC',
        'mechanicProfile': {
          'profileId': 201,
          'clubId': null,
          'mechanicProfileId': 201,
        },
      });
    });

    adapter.onGet('/api/attestations/applications', (server) {
      server.reply(200, applications);
    });

    adapter.onGet('/api/mechanics/201', (server) {
      server.reply(200, {
        'profileId': 201,
        'fullName': 'Свободный Механик',
        'region': 'Казань',
      });
    });

    adapter.onGet('/api/mechanics/specialists', (server) {
      server.reply(200, specialists);
    });

    adapter.onPost('/api/attestations/applications', (server) {
      final app = {
        'id': 1,
        'userId': 101,
        'mechanicProfileId': 201,
        'clubId': null,
        'status': 'PENDING',
        'comment': 'Опыт 7 лет',
        'requestedGrade': 'SENIOR',
        'submittedAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };
      applications.add(app);
      server.reply(200, app);
    });

    adapter.onPut('/api/attestations/applications/1/status', (server) {
      final updated = {
        ...applications.first,
        'status': 'APPROVED',
        'approvedGrade': 'LEAD',
        'comment': 'Подтверждено администратором',
        'updatedAt': DateTime.now().toIso8601String(),
      };
      applications[0] = updated;
      specialists.add({
        'profileId': 201,
        'userId': 101,
        'fullName': 'Свободный Механик',
        'region': 'Казань',
        'specializationId': 12,
        'skills': 'диагностика, ремонт',
        'totalExperienceYears': 7,
        'bowlingExperienceYears': 4,
        'isEntrepreneur': true,
        'rating': 4.8,
        'attestedGrade': 'LEAD',
        'accountType': 'FREE_MECHANIC_BASIC',
        'verificationDate': DateTime.now().toIso8601String(),
        'clubs': ['Strike Point'],
      });
      server.reply(200, updated);
    });
  });

  testWidgets(
    'free mechanic submits attestation, admin approves, manager sees specialist card',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AttestationApplicationsScreen()));
      await tester.pumpAndSettle();
      expect(find.textContaining('нет заявок'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.verified_user_outlined));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<MechanicGrade>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('SENIOR').last);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Описание опыта и компетенций'),
        'Опыт 7 лет, диагностика дорожек',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Дополнительные сведения (при необходимости)'),
        'Сертификат Brunswick 2023',
      );
      await tester.tap(find.text('Подать заявку'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Рассматривается'), findsOneWidget);

      await tester.pumpWidget(const MaterialApp(home: AdminAttestationScreen()));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check_circle_outline), findsWidgets);
      await tester.tap(find.byIcon(Icons.check_circle_outline).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Сохранить'));
      await tester.pumpAndSettle();

      expect(find.textContaining('APPROVED'), findsWidgets);

      await tester.pumpWidget(const MaterialApp(home: AttestationApplicationsScreen()));
      await tester.pumpAndSettle();
      expect(find.textContaining('Одобрено'), findsOneWidget);

      await tester.pumpWidget(const MaterialApp(home: SpecialistsListScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Свободный Механик'), findsOneWidget);
      expect(find.textContaining('LEAD'), findsWidgets);
    },
  );
}
