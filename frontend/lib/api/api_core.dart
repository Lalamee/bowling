import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Централизованный обработчик ошибок API
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorType;

  ApiException(this.message, {this.statusCode, this.errorType});

  @override
  String toString() => message;
}

class ApiCore {
  static final ApiCore _i = ApiCore._internal();
  factory ApiCore() => _i;
  ApiCore._internal();

  final Dio dio = Dio();
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  static const String _defaultBaseUrl = 'http://158.160.205.8:8080';

  String _baseUrl = _defaultBaseUrl;
  String get baseUrl => _baseUrl;

  Future<void> init({String? baseUrl}) async {
    _baseUrl = _resolveBaseUrl(baseUrl);
    dio.options.baseUrl = _baseUrl;
    dio.options.connectTimeout = const Duration(seconds: 30);
    dio.options.receiveTimeout = const Duration(seconds: 30);
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.read(key: 'jwt_token');
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (e, handler) async {
        // Попытка обновить токен при 401
        final isUnauthorized = e.response?.statusCode == 401;
        final reqOptions = e.requestOptions;
        final retried = reqOptions.headers['x-retried'] == true;
        
        if (isUnauthorized && !retried) {
          final refresh = await storage.read(key: 'refresh_token');
          if (refresh != null && refresh.isNotEmpty) {
            try {
              final r = await dio.post('/api/auth/refresh', data: {'refreshToken': refresh});
              final data = r.data;
              String? newAccessToken;
              String? newRefreshToken;
              if (data is Map) {
                final access = data['accessToken'];
                final refreshValue = data['refreshToken'];
                newAccessToken = access?.toString();
                newRefreshToken = refreshValue?.toString();
              }
              if (newAccessToken != null) {
                final headers = Map<String, dynamic>.from(reqOptions.headers);
                headers['x-retried'] = true;
                headers['Authorization'] = 'Bearer $newAccessToken';

                await storage.write(key: 'jwt_token', value: newAccessToken);
                if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
                  await storage.write(key: 'refresh_token', value: newRefreshToken);
                }

                final opts = Options(
                  method: reqOptions.method,
                  headers: headers,
                  contentType: reqOptions.contentType,
                  responseType: reqOptions.responseType,
                  sendTimeout: reqOptions.sendTimeout,
                  receiveTimeout: reqOptions.receiveTimeout,
                );

                final newRes = await dio.request(
                  reqOptions.path,
                  data: reqOptions.data,
                  queryParameters: reqOptions.queryParameters,
                  options: opts,
                  cancelToken: reqOptions.cancelToken,
                  onSendProgress: reqOptions.onSendProgress,
                  onReceiveProgress: reqOptions.onReceiveProgress,
                );
                return handler.resolve(newRes);
              }
            } catch (_) {
              // Если обновление токена не удалось, очищаем токены
              await clearToken();
            }
          }
        }
        
        // Преобразуем ошибку в user-friendly формат
        final apiError = _handleError(e);
        return handler.reject(DioException(
          requestOptions: reqOptions,
          error: apiError,
          response: e.response,
          type: e.type,
        ));
      },
    ));
  }

  String _resolveBaseUrl(String? candidate) {
    final raw = candidate?.trim();
    if (raw == null || raw.isEmpty) {
      return _defaultBaseUrl;
    }

    final normalized = raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
    if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
      return normalized;
    }

    return 'https://$normalized';
  }
  
  /// Преобразует DioException в понятное пользователю сообщение
  ApiException _handleError(DioException error) {
    final statusCode = error.response?.statusCode;
    String message;
    String? errorType;
    
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = 'Превышено время ожидания. Проверьте подключение к интернету.';
        errorType = 'timeout';
        break;
        
      case DioExceptionType.connectionError:
        message = 'Не удалось подключиться к серверу. Проверьте подключение к интернету.';
        errorType = 'connection';
        break;
        
      case DioExceptionType.badResponse:
        message = _getErrorMessage(statusCode, error.response?.data);
        errorType = 'server';
        break;
        
      case DioExceptionType.cancel:
        message = 'Запрос был отменён';
        errorType = 'cancel';
        break;
        
      default:
        message = 'Произошла ошибка. Попробуйте позже.';
        errorType = 'unknown';
    }
    
    return ApiException(message, statusCode: statusCode, errorType: errorType);
  }
  
  /// Извлекает сообщение об ошибке из ответа сервера
  String _getErrorMessage(int? statusCode, dynamic responseData) {
    // Пытаемся извлечь сообщение из ответа сервера
    String? serverMessage;
    if (responseData is Map) {
      serverMessage = responseData['message']?.toString() ?? 
                      responseData['error']?.toString() ??
                      responseData['detail']?.toString();
    }
    
    switch (statusCode) {
      case 400:
        return serverMessage ?? 'Неверные данные запроса';
      case 401:
        return 'Требуется авторизация';
      case 403:
        return 'Доступ запрещён';
      case 404:
        return 'Ресурс не найден';
      case 409:
        return serverMessage ?? 'Конфликт данных';
      case 422:
        return serverMessage ?? 'Ошибка валидации данных';
      case 500:
        return 'Ошибка сервера. Попробуйте позже.';
      case 502:
      case 503:
        return 'Сервис временно недоступен';
      default:
        return serverMessage ?? 'Ошибка запроса ($statusCode)';
    }
  }

  Future<void> setToken(String token) async {
    await storage.write(key: 'jwt_token', value: token);
  }

  Future<void> clearToken() async {
    await storage.delete(key: 'jwt_token');
    await storage.delete(key: 'refresh_token');
  }
}
