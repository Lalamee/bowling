import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/core/network/dio_client.dart';
import 'package:flutter_application_1/core/storage/secure_storage.dart';
import 'package:flutter_application_1/features/auth/data/auth_service.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

class _InMemoryStorage implements TokenStorageBackend {
  final Map<String, String> _data = {};

  @override
  Future<void> delete(String key) async {
    _data.remove(key);
  }

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> write(String key, String? value) async {
    if (value == null || value.isEmpty) {
      _data.remove(key);
    } else {
      _data[key] = value;
    }
  }
}

void main() {
  late DioAdapter adapter;

  setUp(() {
    SecureStorage.overrideBackend(_InMemoryStorage());
    adapter = DioAdapter(dio: DioClient.dio);
    DioClient.dio.httpClientAdapter = adapter;
  });

  tearDown(() async {
    await SecureStorage.clearTokens();
  });

  test('login stores tokens and returns session with normalized identifier', () async {
    adapter.onPost(
      '/api/auth/login',
      (server) => server.reply(200, {
        'accessToken': 'access-1',
        'refreshToken': 'refresh-1',
        'tokenType': 'Bearer',
        'user': {
          'id': 42,
          'role': 'OWNER',
          'name': 'Owner Name',
          'email': 'owner@mail.com',
          'phone': '+79991234567',
        },
      }),
      data: {'identifier': '+79991234567', 'password': 'secret'},
    );

    final session = await AuthService.login(identifier: '+7 (999) 123-45-67', password: 'secret');
    expect(session.user.id, 42);
    expect(session.user.role, 'OWNER');
    expect(await SecureStorage.readAccessToken(), 'access-1');
    expect(await SecureStorage.readRefreshToken(), 'refresh-1');
  });

  test('login throws AuthException with invalid credentials', () async {
    adapter.onPost(
      '/api/auth/login',
      (server) => server.reply(401, {
        'code': 'AUTH_INVALID',
        'message': 'Неверный логин или пароль',
      }),
      data: {'identifier': '+79991234567', 'password': 'wrong'},
    );

    expect(
      () => AuthService.login(identifier: '+7 999 123 45 67', password: 'wrong'),
      throwsA(isA<AuthException>().having((e) => e.type, 'type', AuthErrorType.invalidCredentials)),
    );
  });

  test('login falls back to legacy phone endpoint', () async {
    adapter.onPost(
      '/api/auth/login',
      (server) => server.reply(404, {'error': 'not found'}),
      data: {'identifier': '+79991234567', 'password': 'secret'},
    );

    adapter.onPost(
      '/api/auth/login/phone',
      (server) => server.reply(200, {
        'accessToken': 'legacy-access',
        'refreshToken': 'legacy-refresh',
        'tokenType': 'Bearer',
        'user': {
          'id': 1,
          'role': 'MECHANIC',
          'name': 'Mechanic',
          'email': null,
          'phone': '+79991234567',
        },
      }),
      data: {'phone': '+79991234567', 'password': 'secret'},
    );

    final session = await AuthService.login(identifier: '8 (999) 123-45-67', password: 'secret');
    expect(session.accessToken, 'legacy-access');
    expect(await SecureStorage.readAccessToken(), 'legacy-access');
  });
}
