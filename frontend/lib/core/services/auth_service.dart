import '../../api/api_core.dart';
import '../../api/api_service.dart';
import '../../models/user_login_dto.dart';
import '../../models/register_request_dto.dart';
import '../../models/register_user_dto.dart';
import '../../models/mechanic_profile_dto.dart';
import '../../models/owner_profile_dto.dart';
import '../../models/manager_profile_dto.dart';
import '../../models/bowling_club_dto.dart';
import '../../models/user_info_dto.dart';
import 'local_auth_storage.dart';

class AuthService {
  static final _api = ApiService();

  static Future<Map<String, dynamic>?> login({required String phone, required String password}) async {
    final loginDto = UserLoginDto(phone: phone, password: password);
    final response = await _api.login(loginDto);
    await _api.saveTokens(response);
    return {
      'accessToken': response.accessToken,
      'refreshToken': response.refreshToken,
    };
  }

  static Future<bool> registerOwner(Map<String, dynamic> data) async {
    try {
      String? _nullable(dynamic value) {
        if (value == null) return null;
        final str = value.toString().trim();
        return str.isEmpty ? null : str;
      }

      final password = (data['password'] as String?)?.trim();
      if (password == null || password.isEmpty) {
        throw ApiException('Введите пароль');
      }

      final request = RegisterRequestDto(
        user: RegisterUserDto(
          phone: data['phone'],
          password: password,
          roleId: 5,
          accountTypeId: 2,
        ),
        ownerProfile: OwnerProfileDto(
          inn: _nullable(data['inn']) ?? '',
          legalName: _nullable(data['legalName']),
          contactPerson: _nullable(data['contactPerson']),
          contactPhone: _nullable(data['contactPhone']),
          contactEmail: _nullable(data['contactEmail']),
        ),
        club: () {
          final String? clubName = _nullable(data['clubName']) ?? _nullable(data['legalName']);
          final String? clubAddress = _nullable(data['clubAddress']) ?? _nullable(data['address']);
          final dynamic rawLanes = data['lanesCount'] ?? data['lanes'];
          final int? lanesCount = rawLanes is int
              ? rawLanes
              : int.tryParse(rawLanes?.toString() ?? '');

          if (clubName == null || clubName.isEmpty) {
            throw ApiException('Укажите название клуба');
          }
          if (clubAddress == null || clubAddress.isEmpty) {
            throw ApiException('Укажите адрес клуба');
          }
          if (lanesCount == null || lanesCount <= 0) {
            throw ApiException('Количество дорожек должно быть положительным числом');
          }

          return BowlingClubDto(
            name: clubName,
            address: clubAddress,
            lanesCount: lanesCount,
            contactPhone: _nullable(data['clubPhone']) ?? _nullable(data['contactPhone']),
            contactEmail: _nullable(data['contactEmail']),
          );
        }(),
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
      final dynamic rawClubId = data['clubId'];
      final int? clubId = rawClubId is int
          ? rawClubId
          : int.tryParse(rawClubId?.toString() ?? '');

      final password = (data['password'] as String?)?.trim();
      if (password == null || password.isEmpty) {
        throw ApiException('Введите пароль');
      }

      bool? resolveEntrepreneurStatus() {
        final raw = data['status']?.toString().toLowerCase().trim();
        if (raw == null || raw.isEmpty) return null;
        if (raw.contains('ип')) return true;
        if (raw.contains('самозан')) return false;
        return null;
      }

      String? nullableString(dynamic value) {
        if (value == null) return null;
        final str = value.toString().trim();
        return str.isEmpty ? null : str;
      }

      final workPlaces = nullableString(data['workPlaces']);
      final workPeriods = nullableString(data['workPeriods']);
      final skills = nullableString(data['skills']);
      final advantages = nullableString(data['advantages']);

      final request = RegisterRequestDto(
        user: RegisterUserDto(
          phone: data['phone'],
          password: password,
          roleId: 4,
          accountTypeId: 1,
        ),
        mechanicProfile: MechanicProfileDto(
          fullName: data['fio'],
          birthDate: birthDate,
          educationLevelId: int.tryParse(data['educationLevelId']?.toString() ?? '') ?? 1,
          educationalInstitution: data['educationName'],
          specializationId: int.tryParse(data['specializationId']?.toString() ?? '') ?? 1,
          advantages: advantages,
          totalExperienceYears: int.tryParse(data['workYears']?.toString() ?? '0') ?? 0,
          bowlingExperienceYears: int.tryParse(data['bowlingYears']?.toString() ?? '0') ?? 0,
          isEntrepreneur: resolveEntrepreneurStatus(),
          skills: skills,
          workPlaces: workPlaces,
          workPeriods: workPeriods,
          clubId: clubId,
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
      throw ApiException('Не удалось зарегистрировать механика');
    }
  }

  static Future<bool> registerManager(Map<String, dynamic> data) async {
    try {
      final password = (data['password'] as String?)?.trim();
      if (password == null || password.isEmpty) {
        throw ApiException('Введите пароль');
      }

      String? nullableString(dynamic value) {
        if (value == null) return null;
        final str = value.toString().trim();
        return str.isEmpty ? null : str;
      }

      final normalizedPhone = nullableString(data['phone']) ?? data['phone'];

      final request = RegisterRequestDto(
        user: RegisterUserDto(
          phone: normalizedPhone,
          password: password,
          roleId: 6,
          accountTypeId: 3,
        ),
        managerProfile: ManagerProfileDto(
          fullName: data['fio'],
          contactEmail: nullableString(data['email']),
          contactPhone: normalizedPhone,
        ),
      );

      final response = await _api.register(request);
      if (!response.isSuccess) {
        throw ApiException(response.message);
      }

      final loginResult = await AuthService.login(phone: normalizedPhone, password: password);
      if (loginResult == null) {
        throw ApiException('Не удалось войти с новыми данными, попробуйте позже');
      }

      await LocalAuthStorage.clearMechanicState();
      await LocalAuthStorage.clearOwnerState();
      final profileData = {
        'fullName': data['fio'],
        'phone': normalizedPhone,
        'email': nullableString(data['email']),
        'clubName': '',
        'address': '',
        'clubs': <String>[],
        'workplaceVerified': false,
      };

      await LocalAuthStorage.saveManagerProfile(profileData);
      await LocalAuthStorage.setRegisteredRole('manager');

      return true;
    } on ApiException {
      rethrow;
    } catch (_) {
      return false;
    }
  }

  static Future<void> logout() async {
    try {
      await _api.logout();
    } catch (_) {}
    await _api.clearTokens();
  }

  static Future<UserInfoDto?> currentUser() async {
    try {
      return await _api.getCurrentUser();
    } catch (_) {
      return null;
    }
  }
}
