import 'package:shared_preferences/shared_preferences.dart';

class LastSeenStorage {
  static const _prefix = 'notifications.lastSeen.';

  static Future<DateTime?> getLastSeen(String keySuffix) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$keySuffix');
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      return DateTime.parse(raw);
    } catch (_) {
      return null;
    }
  }

  static Future<void> setLastSeen(String keySuffix, DateTime value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefix$keySuffix', value.toIso8601String());
  }

  static Future<void> clear(String keySuffix) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$keySuffix');
  }
}
