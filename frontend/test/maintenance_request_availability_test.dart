import 'package:bowling_market/api/api_core.dart';
import 'package:bowling_market/features/orders/presentation/screens/create_maintenance_request_screen.dart';
import 'package:bowling_market/models/maintenance_request_response_dto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ApiCore core;
  late DioAdapter adapter;
  int createCalls = 0;
  int publishCalls = 0;

  setUp(() async {
    createCalls = 0;
    publishCalls = 0;
    core = ApiCore();
    await core.init(baseUrl: 'http://localhost');
    adapter = DioAdapter(dio: core.dio);
    core.dio.httpClientAdapter = adapter;
    await core.storage.write(key: 'jwt_token', value: 'token');

    adapter.onGet('/api/auth/me', (server) {
      server.reply(200, {
        'userId': 42,
        'role': 'MECHANIC',
        'mechanicProfileId': 501,
        'clubsDetailed': [
          {
            'id': 77,
            'name': 'Strike Point',
            'lanesCount': 12,
          },
        ],
      });
    });

    adapter.onGet('/api/inventory/warehouses', (server) {
      server.reply(200, [
        {
          'warehouseId': 1,
          'title': 'Личный zip-склад',
          'warehouseType': 'PERSONAL',
          'personalAccess': true,
          'locationReference': 'Бокс 1',
        },
        {
          'warehouseId': 2,
          'title': 'Склад клуба Strike',
          'warehouseType': 'CLUB',
          'clubId': 77,
          'locationReference': 'Кладовая',
        }
      ]);
    });

    adapter.onGet(
      '/api/inventory/search',
      (server) {
        server.reply(200, [
          {
            'inventoryId': 10,
            'catalogId': 11,
            'catalogNumber': 'ABC-1',
            'quantity': 3,
            'reservedQuantity': 0,
            'warehouseId': 1,
            'locationReference': 'Бокс 1',
            'isAvailable': true,
          }
        ]);
      },
      queryParameters: {'query': 'ABC-1'},
    );

    adapter.onGet(
      '/api/inventory/search',
      (server) {
        server.reply(200, []);
      },
      queryParameters: {'query': Matchers.any},
    );

    adapter.onPost('/api/maintenance/requests', (server) {
      createCalls += 1;
      server.reply(200, {
        'requestId': 123,
        'clubId': 77,
        'mechanicId': 501,
        'status': 'NEW',
        'requestedParts': [
          {'partId': 1, 'catalogNumber': 'ABC-1', 'partName': 'Ролик', 'quantity': 1},
          {'partId': 2, 'catalogNumber': 'MISS-9', 'partName': 'Нет детали', 'quantity': 1},
        ],
      });
    });

    adapter.onPut('/api/maintenance/requests/123/publish', (server) {
      publishCalls += 1;
      server.reply(200, MaintenanceRequestResponseDto(
        requestId: 123,
        clubId: 77,
        mechanicId: 501,
        status: 'UNDER_REVIEW',
        requestedParts: const [],
      ).toJson());
    });
  });

  testWidgets('availability badges show warehouse match and draft/publish actions', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: CreateMaintenanceRequestScreen(initialClubId: 77)),
    ));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Причина закупки / выдачи *'),
      'Плановая замена',
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'Название запчасти *'), 'Ролик ABC');
    await tester.enterText(find.widgetWithText(TextFormField, 'Каталожный номер *'), 'ABC-1');
    await tester.enterText(find.widgetWithText(TextFormField, 'Количество *'), '1');
    await tester.tap(find.text('Добавить запчасть'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Есть на складе'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Название запчасти *'), 'Нет детали');
    await tester.enterText(find.widgetWithText(TextFormField, 'Каталожный номер *'), 'MISS-9');
    await tester.enterText(find.widgetWithText(TextFormField, 'Количество *'), '1');
    await tester.tap(find.text('Добавить запчасть'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Нужно заказывать'), findsOneWidget);

    await tester.tap(find.text('Отправить менеджеру'));
    await tester.pumpAndSettle();

    expect(createCalls, 1);
    expect(publishCalls, 1);
  });
}
