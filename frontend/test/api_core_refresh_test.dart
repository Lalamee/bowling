import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/api/api_core.dart';
import 'package:flutter_application_1/core/storage/secure_storage.dart';
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
  setUp(() {
    SecureStorage.overrideBackend(_InMemoryStorage());
  });

  tearDown(() async {
    await SecureStorage.clearTokens();
  });

  test('ApiCore refreshes token on 401 and retries request once', () async {
    final core = ApiCore();
    await core.init();

    final dio = core.dio;
    final adapter = DioAdapter(dio: dio);
    dio.httpClientAdapter = adapter;

    await SecureStorage.writeRefreshToken('refresh-abc');

    adapter.onPost(
      '/api/auth/refresh',
      (server) => server.reply(200, {'accessToken': 'new-access', 'refreshToken': 'refresh-abc'}),
      data: {'refreshToken': 'refresh-abc'},
    );

    var calls = 0;
    adapter.onGet(
      '/protected',
      (server) {
        calls += 1;
        if (calls == 1) {
          return server.reply(401, {'error': 'unauthorized'});
        } else {
          return server.reply(200, {'ok': true});
        }
      },
    );

    try {
      final res = await dio.get('/protected');
      expect(res.statusCode, 200);
      expect(res.data['ok'], true);
    } catch (e) {
      fail('Request should succeed after refresh: $e');
    }
  });
}
