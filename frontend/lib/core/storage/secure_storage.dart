import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class TokenStorageBackend {
  Future<void> write(String key, String? value);
  Future<String?> read(String key);
  Future<void> delete(String key);
}

class SecureStorage {
  SecureStorage._();

  static const _accessTokenKey = 'accessToken';
  static const _refreshTokenKey = 'refreshToken';

  static TokenStorageBackend _backend = _FlutterSecureStorageBackend();

  @visibleForTesting
  static void overrideBackend(TokenStorageBackend backend) {
    _backend = backend;
  }

  static Future<void> writeAccessToken(String? token) => _backend.write(_accessTokenKey, token);

  static Future<void> writeRefreshToken(String? token) => _backend.write(_refreshTokenKey, token);

  static Future<String?> readAccessToken() => _backend.read(_accessTokenKey);

  static Future<String?> readRefreshToken() => _backend.read(_refreshTokenKey);

  static Future<void> clearTokens() async {
    await _backend.delete(_accessTokenKey);
    await _backend.delete(_refreshTokenKey);
  }
}

class _FlutterSecureStorageBackend implements TokenStorageBackend {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String? value) {
    if (value == null || value.isEmpty) {
      return _storage.delete(key: key);
    }
    return _storage.write(key: key, value: value);
  }
}
