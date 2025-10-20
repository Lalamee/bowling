import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';
import '../../../models/login_response_dto.dart';
import '../../../models/user_login_dto.dart';

class AuthApi {
  AuthApi({Dio? dio}) : _dio = dio ?? DioClient.dio;

  final Dio _dio;

  Future<LoginResponseDto> login(UserLoginDto dto) async {
    final response = await _dio.post('/api/auth/login', data: dto.toJson());
    return LoginResponseDto.fromJson(response.data as Map<String, dynamic>);
  }

  Future<LoginResponseDto> loginWithPhone({required String phone, required String password}) async {
    final response = await _dio.post(
      '/api/auth/login/phone',
      data: {'phone': phone, 'password': password},
    );
    return LoginResponseDto.fromJson(response.data as Map<String, dynamic>);
  }

  Future<LoginResponseDto> loginWithEmail({required String email, required String password}) async {
    final response = await _dio.post(
      '/api/auth/login/email',
      data: {'email': email, 'password': password},
    );
    return LoginResponseDto.fromJson(response.data as Map<String, dynamic>);
  }
}
