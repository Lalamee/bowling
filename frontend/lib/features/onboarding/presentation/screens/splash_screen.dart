import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../api/api_core.dart';
import '../../../../../core/debug/test_overrides.dart';
import '../../../../../core/routing/routes.dart';
import '../../../../../core/services/local_auth_storage.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    try {
      final sp = await _safeAsync(() => SharedPreferences.getInstance(),
          timeout: const Duration(seconds: 3));
      if (sp == null) {
        _goToWelcome();
        return;
      }

      if (TestOverrides.enabled) {
        if (TestOverrides.forceFirstRun) {
          await sp.setBool('first_run_done', false);
        } else if (TestOverrides.forceSecondRun) {
          await sp.setBool('first_run_done', true);
        }
      }

      final firstRunDone = sp.getBool('first_run_done') ?? false;

      if (!mounted) return;
      if (!firstRunDone) {
        Navigator.pushReplacementNamed(context, Routes.splashFirstTime);
        return;
      }

      final storedRole = await _safeAsync(() => LocalAuthStorage.getRegisteredRole(),
          timeout: const Duration(seconds: 2));
      final token = await _safeAsync(
          () => ApiCore().getAccessToken(),
          timeout: const Duration(seconds: 2));

      if (!mounted) return;

      if (storedRole != null && storedRole.isNotEmpty && token != null && token.isNotEmpty) {
        Navigator.pushReplacementNamed(context, _resolveRouteForRole(storedRole));
      } else {
        _goToWelcome();
      }
    } catch (e, s) {
      if (kDebugMode) {
        debugPrint('Splash boot failed: $e');
        debugPrintStack(stackTrace: s);
      }
      _goToWelcome();
    }
  }

  Future<T?> _safeAsync<T>(Future<T> Function() action, {Duration timeout = const Duration(seconds: 3)}) async {
    try {
      return await action().timeout(timeout);
    } catch (e, s) {
      if (kDebugMode) {
        debugPrint('Splash async operation failed: $e');
        debugPrintStack(stackTrace: s);
      }
      return null;
    }
  }

  void _goToWelcome() {
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, Routes.welcome);
  }

  String _resolveRouteForRole(String role) {
    switch (role.trim().toLowerCase()) {
      case 'owner':
        return Routes.profileOwner;
      case 'manager':
        return Routes.profileManager;
      case 'admin':
        return Routes.profileAdmin;
      default:
        return Routes.profileMechanic;
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
