import 'package:shared_preferences/shared_preferences.dart';

class LocalAuthStorage {
  static const String _mechanicRegisteredKey = 'mechanic_registered';

  static Future<void> setMechanicRegistered(bool value) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_mechanicRegisteredKey, value);
  }

  static Future<bool> isMechanicRegistered() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(_mechanicRegisteredKey) ?? false;
  }
}
