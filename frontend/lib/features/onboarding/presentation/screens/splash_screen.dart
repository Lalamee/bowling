import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../core/debug/test_overrides.dart';
import '../../../../../core/routing/routes.dart';

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
    final sp = await SharedPreferences.getInstance();

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
    } else {
      Navigator.pushReplacementNamed(context, Routes.welcome);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
