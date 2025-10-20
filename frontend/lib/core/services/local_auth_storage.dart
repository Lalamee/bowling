import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LocalAuthStorage {
  static const String _mechanicRegisteredKey = 'mechanic_registered';
  static const String _mechanicProfileKey = 'mechanic_profile';
  static const String _ownerRegisteredKey = 'owner_registered';
  static const String _ownerProfileKey = 'owner_profile';
  static const String _registeredRoleKey = 'registered_role';

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
    await _clearRegisteredRoleIfMatches('mechanic');
  }

  static Future<void> setOwnerRegistered(bool value) async {
    final sp = await SharedPreferences.getInstance();
    if (value) {
      await sp.setBool(_ownerRegisteredKey, true);
    } else {
      await sp.remove(_ownerRegisteredKey);
    }
  }

  static Future<bool> isOwnerRegistered() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(_ownerRegisteredKey) ?? false;
  }

  static Future<void> saveOwnerProfile(Map<String, dynamic> data) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_ownerProfileKey, jsonEncode(data));
  }

  static Future<Map<String, dynamic>?> loadOwnerProfile() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_ownerProfileKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}
    return null;
  }

  static Future<void> clearOwnerState() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_ownerRegisteredKey);
    await sp.remove(_ownerProfileKey);
    await _clearRegisteredRoleIfMatches('owner');
  }

  static Future<void> setRegisteredRole(String role) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_registeredRoleKey, role);
  }

  static Future<String?> getRegisteredRole() async {
    final sp = await SharedPreferences.getInstance();
    final role = sp.getString(_registeredRoleKey);
    if (role == null || role.trim().isEmpty) return null;
    return role.trim();
  }

  static Future<bool> hasRegisteredAccount() async {
    final role = await getRegisteredRole();
    return role != null;
  }

  static Future<void> clearAllState() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_mechanicRegisteredKey);
    await sp.remove(_mechanicProfileKey);
    await sp.remove(_ownerRegisteredKey);
    await sp.remove(_ownerProfileKey);
    await sp.remove(_registeredRoleKey);
  }

  static Future<void> _clearRegisteredRoleIfMatches(String role) async {
    final sp = await SharedPreferences.getInstance();
    final current = sp.getString(_registeredRoleKey);
    if (current != null && current.toLowerCase() == role.toLowerCase()) {
      await sp.remove(_registeredRoleKey);
    }
  }
}
