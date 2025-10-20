import 'package:dio/dio.dart';

import '../../../api/api_core.dart';
import '../../../api/api_service.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/services/local_auth_storage.dart';
import '../../../models/login_response_dto.dart';
import '../../../models/mechanic_profile_dto.dart';
import '../../../models/owner_profile_dto.dart';
import '../../../models/register_request_dto.dart';
import '../../../models/register_user_dto.dart';
import '../../../models/user_info_dto.dart';
import '../../../models/user_login_dto.dart';
import '../validators/login_validator.dart';
import 'auth_api.dart';

class AuthService {
  static final AuthApi _authApi = AuthApi();
  static final ApiService _api = ApiService();

  static Future<LoginSession> login({required String identifier, required String password}) async {
    final normalized = LoginValidator.normalize(identifier);
    if (normalized == null) {
      throw AuthException(
        AuthErrorType.identifierInvalid,
        message: 'Введите телефон +7XXXXXXXXXX или e-mail',
        code: 'AUTH_IDENTIFIER_INVALID',
      );
    }

    final payload = UserLoginDto(identifier: normalized.value, password: password);
    try {
      final response = await _authApi.login(payload);
      await _storeTokens(response);
      return LoginSession(response);
    } on DioException catch (error) {
      if (_shouldFallback(error)) {
        try {
          final response = await _fallbackLogin(normalized, password);
          await _storeTokens(response);
          return LoginSession(response);
        } on DioException catch (fallbackError) {
          throw _mapError(fallbackError);
        }
      }
      throw _mapError(error);
    }
  }

  static Future<bool> registerOwner(Map<String, dynamic> data) async {
    try {
      String? _nullable(dynamic value) {
        if (value == null) return null;
        final str = value.toString().trim();
        return str.isEmpty ? null : str;
      }

      final request = RegisterRequestDto(
        user: RegisterUserDto(
          phone: data['phone'],
          password: data['password'] ?? 'password123',
          roleId: 3,
          accountTypeId: 2,
        ),
        ownerProfile: OwnerProfileDto(
          inn: _nullable(data['inn']) ?? '',
          legalName: _nullable(data['legalName']),
          contactPerson: _nullable(data['contactPerson']),
          contactPhone: _nullable(data['contactPhone']),
          contactEmail: _nullable(data['contactEmail']),
        ),
      );
      final response = await _api.register(request);
      if (!response.isSuccess) {
        throw ApiException(response.message);
      }
      return true;
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('Не удалось зарегистрировать владельца');
    }
  }

  static Future<bool> registerMechanic(Map<String, dynamic> data) async {
    try {
      final birthDate = data['birth'] is DateTime
          ? data['birth'] as DateTime
          : DateTime.tryParse(data['birth']?.toString() ?? '') ?? DateTime.now();

      final request = RegisterRequestDto(
        user: RegisterUserDto(
          phone: data['phone'],
          password: data['password'] ?? 'password123',
          roleId: 1,
          accountTypeId: 1,
        ),
        mechanicProfile: MechanicProfileDto(
          fullName: data['fio'],
          birthDate: birthDate,
          educationLevelId: int.tryParse(data['educationLevelId']?.toString() ?? '') ?? 1,
          educationalInstitution: data['educationName'],
          specializationId: int.tryParse(data['specializationId']?.toString() ?? '') ?? 1,
          advantages: data['advantages'],
          totalExperienceYears: int.tryParse(data['workYears']?.toString() ?? '0') ?? 0,
          bowlingExperienceYears: int.tryParse(data['bowlingYears']?.toString() ?? '0') ?? 0,
          isEntrepreneur: (data['status']?.toString().toLowerCase() == 'самозанятый' ||
                  data['status']?.toString().toLowerCase() == 'ип'),
          skills: data['skills'],
          workPlaces: data['workPlaces'],
          workPeriods: data['workPeriods'],
        ),
      );
      final response = await _api.register(request);
      return response.isSuccess;
    } catch (e) {
      return false;
    }
  }

  static Future<void> logout() async {
    try {
      await _api.logout();
    } catch (_) {}
    await DioClient.clearTokens();
    await LocalAuthStorage.clearAllState();
  }

  static Future<UserInfoDto?> currentUser() async {
    try {
      return await _api.getCurrentUser();
    } catch (_) {
      return null;
    }
  }

  static Future<void> _storeTokens(LoginResponseDto response) async {
    await DioClient.saveTokens(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
    );
  }

  static bool _shouldFallback(DioException error) {
    final status = error.response?.statusCode;
    return status == 404 || status == 405 || status == 415;
  }

  static Future<LoginResponseDto> _fallbackLogin(LoginIdentifier identifier, String password) {
    switch (identifier.kind) {
      case IdentifierKind.phone:
        return _authApi.loginWithPhone(phone: identifier.value, password: password);
      case IdentifierKind.email:
        return _authApi.loginWithEmail(email: identifier.value, password: password);
    }
  }

  static AuthException _mapError(DioException error) {
    final status = error.response?.statusCode;
    final data = error.response?.data;
    final code = data is Map ? data['code']?.toString() : null;
    final message = data is Map
        ? data['message']?.toString() ?? data['error']?.toString() ?? 'Ошибка сервера'
        : error.message ?? 'Ошибка сервера';

    if (status == 400 && code == 'AUTH_IDENTIFIER_INVALID') {
      return AuthException(AuthErrorType.identifierInvalid, message: message, code: code);
    }
    if (status == 401 && code == 'AUTH_INVALID') {
      return AuthException(AuthErrorType.invalidCredentials, message: message, code: code);
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.connectionError:
        return AuthException(AuthErrorType.network, message: 'Нет соединения');
      default:
        return AuthException(AuthErrorType.server, message: message, code: code);
    }
  }
}

class LoginSession {
  LoginSession(this.response);

  final LoginResponseDto response;

  LoginUserDto get user => response.user;
  String get accessToken => response.accessToken;
  String get refreshToken => response.refreshToken;
  String get tokenType => response.tokenType;
}

enum AuthErrorType { identifierInvalid, invalidCredentials, network, server }

class AuthException implements Exception {
  AuthException(this.type, {required this.message, this.code});

  final AuthErrorType type;
  final String message;
  final String? code;

  @override
  String toString() => message;
}
