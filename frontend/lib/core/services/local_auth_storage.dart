import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LocalAuthStorage {
  static const String _mechanicRegisteredKey = 'mechanic_registered';
  static const String _mechanicProfileKey = 'mechanic_profile';
  static const String _mechanicApplicationKey = 'mechanic_application';
  static const String _ownerRegisteredKey = 'owner_registered';
  static const String _ownerProfileKey = 'owner_profile';
  static const String _managerProfileKey = 'manager_profile';
  static const String _adminProfileKey = 'admin_profile';
  static const String _registeredRoleKey = 'registered_role';
  static const String _registeredAccountTypeKey = 'registered_account_type';

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
    await sp.remove(_mechanicApplicationKey);
    await _clearRegisteredRoleIfMatches('mechanic');
  }

  static Future<void> saveMechanicApplication(Map<String, dynamic> data) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_mechanicApplicationKey, jsonEncode(data));
  }

  static Future<Map<String, dynamic>?> loadMechanicApplication() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_mechanicApplicationKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return null;
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

  static Future<void> saveManagerProfile(Map<String, dynamic> data) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_managerProfileKey, jsonEncode(data));
  }

  static Future<Map<String, dynamic>?> loadManagerProfile() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_managerProfileKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return null;
  }

  static Future<void> clearManagerState() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_managerProfileKey);
    await _clearRegisteredRoleIfMatches('manager');
  }

  static Future<void> saveAdminProfile(Map<String, dynamic> data) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_adminProfileKey, jsonEncode(data));
  }

  static Future<Map<String, dynamic>?> loadAdminProfile() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_adminProfileKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return null;
  }

  static Future<void> clearAdminState() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_adminProfileKey);
    await _clearRegisteredRoleIfMatches('admin');
  }

  static Future<void> setRegisteredRole(String role) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_registeredRoleKey, role);
  }

  static Future<void> setRegisteredAccountType(String? accountType) async {
    final sp = await SharedPreferences.getInstance();
    if (accountType == null || accountType.trim().isEmpty) {
      await sp.remove(_registeredAccountTypeKey);
    } else {
      await sp.setString(_registeredAccountTypeKey, accountType);
    }
  }

  static Future<String?> getRegisteredRole() async {
    final sp = await SharedPreferences.getInstance();
    final role = sp.getString(_registeredRoleKey);
    if (role == null || role.trim().isEmpty) return null;
    return role.trim();
  }

  static Future<String?> getRegisteredAccountType() async {
    final sp = await SharedPreferences.getInstance();
    final type = sp.getString(_registeredAccountTypeKey);
    if (type == null || type.trim().isEmpty) return null;
    return type.trim();
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
    await sp.remove(_managerProfileKey);
    await sp.remove(_adminProfileKey);
    await sp.remove(_registeredRoleKey);
    await sp.remove(_registeredAccountTypeKey);
  }

  static Future<void> _clearRegisteredRoleIfMatches(String role) async {
    final sp = await SharedPreferences.getInstance();
    final current = sp.getString(_registeredRoleKey);
    if (current != null && current.toLowerCase() == role.toLowerCase()) {
      await sp.remove(_registeredRoleKey);
      await sp.remove(_registeredAccountTypeKey);
    }
  }
}
