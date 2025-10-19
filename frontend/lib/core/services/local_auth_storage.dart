import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LocalAuthStorage {
  static const String _mechanicRegisteredKey = 'mechanic_registered';
  static const String _mechanicProfileKey = 'mechanic_profile';

  static Future<void> setMechanicRegistered(bool value) async {
    final sp = await SharedPreferences.getInstance();
    if (value) {
      await sp.setBool(_mechanicRegisteredKey, true);
    } else {
      await sp.remove(_mechanicRegisteredKey);
    }
  }

  static Future<bool> isMechanicRegistered() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(_mechanicRegisteredKey) ?? false;
  }

  static Future<void> saveMechanicProfile(Map<String, dynamic> data) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_mechanicProfileKey, jsonEncode(data));
  }

  static Future<Map<String, dynamic>?> loadMechanicProfile() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_mechanicProfileKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      // ignore corrupted cache and fall back to null
    }
    return null;
  }

  static Future<void> clearMechanicState() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_mechanicRegisteredKey);
    await sp.remove(_mechanicProfileKey);
  }
}
