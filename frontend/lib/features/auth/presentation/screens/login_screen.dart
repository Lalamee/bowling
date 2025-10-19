import '../../../../core/utils/net_ui.dart';
import '../../../../core/services/auth_service.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/routing/routes.dart';
import '../../../../shared/widgets/titles/bowling_market_title.dart';
import '../widgets/brand_button.dart';
import '../widgets/inputs.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _login = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _login.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    final phone = _login.text.trim();
    final password = _password.text;
    if (phone.isEmpty || password.isEmpty) {
      showSnack(context, 'Введите телефон и пароль');
      return;
    }
    final res = await withLoader(context, () => AuthService.login(phone: phone, password: password));
    if (res != null && mounted) {
      Navigator.of(context).pushReplacementNamed(Routes.orders);
    } else if (mounted) {
      showSnack(context, 'Неверный телефон или пароль');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  AppTextField(
                    controller: _login,
                    hint: 'Логин/телефон',
                    prefixIcon: Icons.person_outline,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  PasswordField(controller: _password, hint: 'Пароль'),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text.rich(
                      TextSpan(
                        text: 'Забыли пароль? ',
                        style: const TextStyle(color: AppColors.darkGray, fontSize: 14),
                        children: [
                          TextSpan(
                            text: 'Восстановить.',
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                            recognizer: TapGestureRecognizer()..onTap = () => Navigator.pushNamed(context, Routes.recoverAsk),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  BrandButton(text: 'ВОЙТИ', onPressed: _onLogin),
                ],
              ),
            ),
            const Spacer(),
            const Padding(
              padding: EdgeInsets.only(bottom: 24),
              child: BowlingMarketTitle(fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }
}
