import 'package:dio/dio.dart';

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
import '../../models/free_mechanic_application_request_dto.dart';
import '../../models/free_mechanic_application_response_dto.dart';
import '../../models/mechanic_work_history_dto.dart';
import '../utils/validators.dart';
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
      String? nullableString(dynamic value) {
        if (value == null) return null;
        final str = value.toString().trim();
        return str.isEmpty ? null : str;
      }

      final password = (data['password'] as String?)?.trim();
      if (password == null || password.isEmpty) {
        throw ApiException('Введите пароль');
      }

      // IDs должны соответствовать фактическим значениям в таблицах role и account_type
      // (см. данные продовой БД: CLUB_OWNER -> role.id = 44, account_type.id = 64).
      final request = RegisterRequestDto(
        user: RegisterUserDto(
          phone: data['phone'],
          password: password,
          roleId: 44,
          accountTypeId: 64,
        ),
        ownerProfile: OwnerProfileDto(
          inn: nullableString(data['inn']) ?? '',
          legalName: nullableString(data['legalName']),
          contactPerson: nullableString(data['contactPerson']),
          contactPhone: nullableString(data['contactPhone']),
          contactEmail: nullableString(data['contactEmail']),
        ),
        club: () {
          final String? clubName =
              nullableString(data['clubName']) ?? nullableString(data['legalName']);
          final String? clubAddress =
              nullableString(data['clubAddress']) ?? nullableString(data['address']);
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
            contactPhone:
                nullableString(data['clubPhone']) ?? nullableString(data['contactPhone']),
            contactEmail: nullableString(data['contactEmail']),
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
        if (data['isEntrepreneur'] is bool) return data['isEntrepreneur'] as bool;
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
      final entries = Validators.parseEmploymentHistory(data['bowlingHistory']?.toString() ?? '');

      final region = nullableString(data['region']);
      if (region == null || region.isEmpty) {
        throw ApiException('Укажите регион');
      }

      final entrepreneur = resolveEntrepreneurStatus();
      if (clubId == null && entrepreneur == null) {
        throw ApiException('Укажите статус: ИП или самозанятый');
      }

      if (clubId == null) {
        final workHistory = entries
            .map((e) => MechanicWorkHistoryDto(
                  organization: e.place,
                  position: 'Механик',
                  startDate: e.from,
                  endDate: e.to,
                  description: skills,
                ))
            .toList();

        final request = FreeMechanicApplicationRequestDto(
          phone: data['phone'],
          password: password,
          fullName: data['fio'],
          birthDate: birthDate,
          educationLevelId: int.tryParse(data['educationLevelId']?.toString() ?? ''),
          educationalInstitution: data['educationName'],
          totalExperienceYears: int.tryParse(data['workYears']?.toString() ?? '0') ?? 0,
          bowlingExperienceYears: int.tryParse(data['bowlingYears']?.toString() ?? '0') ?? 0,
          isEntrepreneur: entrepreneur ?? false,
          specializationId: int.tryParse(data['specializationId']?.toString() ?? ''),
          region: region,
          skills: skills,
          advantages: advantages,
          workHistory: workHistory,
        );

        final FreeMechanicApplicationResponseDto response = await _api.applyFreeMechanic(request);
        final cachedProfile = {
          'fullName': data['fio'],
          'phone': data['phone'],
          'status': 'Заявка отправлена',
          'clubs': <String>[],
          'address': region,
          'workplaceVerified': false,
          'applicationStatus': response.status ?? 'NEW',
          'applicationComment': response.comment,
          'accountType': response.accountType ?? 'FREE_MECHANIC_BASIC',
        };
        await LocalAuthStorage.saveMechanicProfile(cachedProfile);
        await LocalAuthStorage.setMechanicRegistered(true);
        await LocalAuthStorage.saveMechanicApplication(response.toJson());
        await LocalAuthStorage.setRegisteredRole('mechanic');
        await LocalAuthStorage.setRegisteredAccountType(response.accountType ?? 'FREE_MECHANIC_BASIC');
        return true;
      }

      // Для наймных механиков используем идентификаторы из таблиц role и account_type
      // (role.MECHANIC = 42, account_type.INDIVIDUAL = 63).
      final request = RegisterRequestDto(
        user: RegisterUserDto(
          phone: data['phone'],
          password: password,
          roleId: 42,
          accountTypeId: 63,
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
          isEntrepreneur: entrepreneur,
          skills: skills,
          workPlaces: workPlaces,
          workPeriods: workPeriods,
          region: region,
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
    } on DioException catch (e) {
      final error = e.error;
      if (error is ApiException) {
        throw error;
      }
      throw ApiException(error?.toString() ?? 'Не удалось зарегистрировать механика');
    } catch (_) {
      throw ApiException('Не удалось зарегистрировать механика');
    }
  }

  static Future<bool> registerHeadMechanic(Map<String, dynamic> data) async {
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
      final dynamic rawClubId = data['clubId'];
      final int? clubId = rawClubId is int
          ? rawClubId
          : int.tryParse(rawClubId?.toString() ?? '');
      final clubName = nullableString(data['clubName']);
      final clubAddress = nullableString(data['clubAddress']);

      if (clubId == null) {
        throw ApiException('Выберите клуб, в котором вы работаете');
      }

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
          clubId: clubId,
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
        'clubId': clubId,
        'clubName': clubName ?? '',
        'address': clubAddress ?? '',
        'clubs': clubName != null && clubName.isNotEmpty ? [clubName] : <String>[],
        'workplaceVerified': false,
      };

      await LocalAuthStorage.saveManagerProfile(profileData);
      await LocalAuthStorage.setRegisteredRole('manager');

      return true;
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      final error = e.error;
      if (error is ApiException) {
        throw error;
      }
      throw ApiException('Не удалось зарегистрироваться. Попробуйте позже.');
    } catch (_) {
      throw ApiException('Не удалось зарегистрироваться. Попробуйте позже.');
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
