import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../debug/test_overrides.dart';
import '../routing/routes.dart';

class AppInitService {
  Future<void> boot(BuildContext context) async {
    final sp = await SharedPreferences.getInstance();

    if (TestOverrides.enabled) {
      if (TestOverrides.forceFirstRun) {
        await sp.setBool('first_run_done', false);
      } else if (TestOverrides.forceSecondRun) {
        await sp.setBool('first_run_done', true);
      }
    }

    final firstRunDone = sp.getBool('first_run_done') ?? false;

    if (!context.mounted) return;
    if (!firstRunDone) {
      Navigator.pushReplacementNamed(context, Routes.splashFirstTime);
    } else {
      Navigator.pushReplacementNamed(context, Routes.welcome);
    }
  }

  static Future<void> completeOnboarding(BuildContext context) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool('first_run_done', true);
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, Routes.welcome);
  }

  static Future<bool> isFirstRun() async {
    final sp = await SharedPreferences.getInstance();
    return !(sp.getBool('first_run_done') ?? false);
  }

  static Future<void> setFirstRun(bool value) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool('first_run_done', !value ? true : false);
  }
}
