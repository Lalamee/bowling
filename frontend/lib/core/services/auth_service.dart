import '../../api/api_service.dart';
import '../../models/user_login_dto.dart';
import '../../models/register_request_dto.dart';
import '../../models/register_user_dto.dart';
import '../../models/mechanic_profile_dto.dart';
import '../../models/owner_profile_dto.dart';
import '../../models/user_info_dto.dart';

class AuthService {
  static final _api = ApiService();

  static Future<Map<String, dynamic>?> login({required String phone, required String password}) async {
    try {
      final loginDto = UserLoginDto(phone: phone, password: password);
      final response = await _api.login(loginDto);
      await _api.saveTokens(response);
      return {
        'accessToken': response.accessToken,
        'refreshToken': response.refreshToken,
      };
    } catch (e) {
      return null;
    }
  }

  static Future<bool> registerOwner(Map<String, dynamic> data) async {
    try {
      final request = RegisterRequestDto(
        user: RegisterUserDto(
          phone: data['phone'],
          password: data['password'] ?? 'password123',
          roleId: 3,
          accountTypeId: 2,
        ),
        ownerProfile: OwnerProfileDto(
          inn: data['inn'],
          legalName: data['legalName'],
          contactPerson: data['contactPerson'],
          contactPhone: data['contactPhone'],
          contactEmail: data['contactEmail'] ?? '',
        ),
      );
      final response = await _api.register(request);
      return response.isSuccess;
    } catch (e) {
      return false;
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
