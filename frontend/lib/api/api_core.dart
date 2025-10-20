import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/network/dio_client.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorType;

  ApiException(this.message, {this.statusCode, this.errorType});

  @override
  String toString() => message;
}

class ApiCore {
  ApiCore._internal();

  static final ApiCore _i = ApiCore._internal();
  factory ApiCore() => _i;

  bool _initialized = false;

  Dio get dio => DioClient.dio;

  String get baseUrl => DioClient.baseUrl;

  Future<void> init() async {
    if (_initialized) return;
    dio.interceptors.add(InterceptorsWrapper(
      onError: (error, handler) {
        final apiError = _handleError(error);
        handler.next(DioException(
          requestOptions: error.requestOptions,
          response: error.response,
          error: apiError,
          type: error.type,
        ));
      },
    ));
    _initialized = true;
  }

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

  String _getErrorMessage(int? statusCode, dynamic responseData) {
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
        return serverMessage ?? 'Требуется авторизация';
      case 403:
        return serverMessage ?? 'Доступ запрещён';
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
    await DioClient.saveTokens(accessToken: token);
  }

  Future<void> clearToken() => DioClient.clearTokens();
}
