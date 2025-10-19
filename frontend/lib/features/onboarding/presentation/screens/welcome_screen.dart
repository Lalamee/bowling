import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'register_role_selection.dart';
import '../../../../shared/widgets/titles/bowling_market_title.dart';
import '../../../../core/theme/colors.dart';

import '../../../../../core/routing/routes.dart';
import '../../../../../core/debug/test_overrides.dart';
import '../../../../../core/services/local_auth_storage.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late final TapGestureRecognizer _policyRecognizer;
  bool _canEnter = false;

  @override
  void initState() {
    super.initState();
    _policyRecognizer = TapGestureRecognizer()..onTap = () {};
    _loadRegistrationStatus();
  }

  @override
  void dispose() {
    _policyRecognizer.dispose();
    super.dispose();
  }

  Future<void> _loadRegistrationStatus() async {
    final registered = await LocalAuthStorage.isMechanicRegistered();
    final cached = await LocalAuthStorage.loadMechanicProfile();
    if (!mounted) return;
    setState(() => _canEnter = registered || cached != null);
  }

  Future<void> _enter() async {
    if (TestOverrides.useLoginScreen) {
      Navigator.pushReplacementNamed(context, Routes.authLogin);
      return;
    }
    var canEnter = _canEnter;
    if (!canEnter) {
      final registered = await LocalAuthStorage.isMechanicRegistered();
      final cached = await LocalAuthStorage.loadMechanicProfile();
      canEnter = registered || cached != null;
      if (mounted && canEnter != _canEnter) {
        setState(() => _canEnter = canEnter);
      }
      if (!canEnter) {
        return;
      }
    }
    final role = TestOverrides.userRole.toLowerCase();
    if (role == 'owner') {
      Navigator.pushReplacementNamed(context, Routes.profileOwner);
    } else if (role == 'manager') {
      Navigator.pushReplacementNamed(context, Routes.profileManager);
    } else if (role == 'admin') {
      Navigator.pushReplacementNamed(context, Routes.profileAdmin);
    } else {
      Navigator.pushReplacementNamed(context, Routes.profileMechanic);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: BowlingMarketTitle(fontSize: 28),
            ),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Здесь широкий спектр услуг и товаров для инвесторов, собственников и механиков.',
                style: TextStyle(fontSize: 14, height: 1.4, color: Color(0xFF23262F)),
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => _enter(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                  ),
                  child: const Text('ВОЙТИ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterRoleSelectionScreen()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.lightGray,
                    foregroundColor: AppColors.darkGray,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                  ),
                  child: const Text('Регистрация', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6F6F6F), height: 1.3),
                  children: [
                    const TextSpan(text: 'При входе и регистрации Вы соглашаетесь '),
                    TextSpan(
                      text: 'с политикой обработки персональных данных.',
                      style: const TextStyle(decoration: TextDecoration.underline, color: Color(0xFF6F6F6F)),
                      recognizer: _policyRecognizer,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
