import 'package:dio/dio.dart';

import '../storage/secure_storage.dart';

class DioClient {
  DioClient._() {
    _dio.options
      ..baseUrl = _baseUrl
      ..connectTimeout = const Duration(seconds: 10)
      ..receiveTimeout = const Duration(seconds: 20);

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await SecureStorage.readAccessToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        final isUnauthorized = error.response?.statusCode == 401;
        final alreadyRetried = error.requestOptions.headers['x-retried'] == true;
        if (isUnauthorized && !alreadyRetried) {
          final refreshToken = await SecureStorage.readRefreshToken();
          if (refreshToken != null && refreshToken.isNotEmpty) {
            try {
              final refreshed = await _dio.post(
                '/api/auth/refresh',
                data: {'refreshToken': refreshToken},
                options: Options(headers: {'x-retried': true}),
              );
              final data = refreshed.data;
              final access = data is Map ? data['accessToken']?.toString() : null;
              final refresh = data is Map ? data['refreshToken']?.toString() : null;
              if (access != null && access.isNotEmpty) {
                await SecureStorage.writeAccessToken(access);
                await SecureStorage.writeRefreshToken(refresh);

                final requestHeaders = Map<String, dynamic>.from(error.requestOptions.headers);
                requestHeaders['x-retried'] = true;
                requestHeaders['Authorization'] = 'Bearer $access';

                final options = Options(
                  method: error.requestOptions.method,
                  headers: requestHeaders,
                  contentType: error.requestOptions.contentType,
                  responseType: error.requestOptions.responseType,
                  sendTimeout: error.requestOptions.sendTimeout,
                  receiveTimeout: error.requestOptions.receiveTimeout,
                );

                final response = await _dio.request(
                  error.requestOptions.path,
                  data: error.requestOptions.data,
                  queryParameters: error.requestOptions.queryParameters,
                  options: options,
                  cancelToken: error.requestOptions.cancelToken,
                  onSendProgress: error.requestOptions.onSendProgress,
                  onReceiveProgress: error.requestOptions.onReceiveProgress,
                );
                return handler.resolve(response);
              }
            } catch (_) {
              await SecureStorage.clearTokens();
            }
          }
        }
        return handler.next(error);
      },
    ));
  }

  static const String _baseUrl = 'http://158.160.205.8:8080';

  static final DioClient _instance = DioClient._();

  final Dio _dio = Dio();

  static Dio get dio => _instance._dio;

  static String get baseUrl => _baseUrl;

  static Future<void> saveTokens({String? accessToken, String? refreshToken}) async {
    await SecureStorage.writeAccessToken(accessToken);
    await SecureStorage.writeRefreshToken(refreshToken);
  }

  static Future<void> clearTokens() => SecureStorage.clearTokens();
}
