import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/api/api_core.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

void main() {
  test('ApiCore refreshes token on 401 and retries request once', () async {
    final core = ApiCore();
    await core.init();

    // Attach mock adapter
    final dio = core.dio;
    final adapter = DioAdapter(dio: dio);
    dio.httpClientAdapter = adapter;

    // Seed refresh token in secure storage
    await core.storage.write(key: 'refresh_token', value: 'refresh-abc');

    // 1) Mock refresh endpoint to issue new access token
    adapter.onPost(
      '/api/auth/refresh',
      (server) => server.reply(200, {'accessToken': 'new-access', 'refreshToken': 'refresh-abc'}),
      data: {'refreshToken': 'refresh-abc'},
    );

    // 2) Mock protected endpoint to return 401 first, then 200 on retry
    var calls = 0;
    adapter.onGet(
      '/protected',
      (server) {
        calls += 1;
        if (calls == 1) {
          // First attempt: simulate unauthorized
          return server.reply(401, {'error': 'unauthorized'});
        } else {
          // Second attempt after refresh
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
