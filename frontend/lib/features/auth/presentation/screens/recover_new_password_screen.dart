import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/routing/routes.dart';
import '../../../../shared/widgets/titles/bowling_market_title.dart';
import '../widgets/brand_button.dart';
import '../widgets/inputs.dart';

class RecoverNewPasswordScreen extends StatefulWidget {
  const RecoverNewPasswordScreen({super.key});

  @override
  State<RecoverNewPasswordScreen> createState() => _RecoverNewPasswordScreenState();
}

class _RecoverNewPasswordScreenState extends State<RecoverNewPasswordScreen> {
  final _pass = TextEditingController();

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Восстановить пароль', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                  const SizedBox(height: 12),
                  PasswordField(controller: _pass, hint: 'Введите новый пароль'),
                  const SizedBox(height: 20),
                  BrandButton(text: 'Сменить пароль и войти', onPressed: () => Navigator.pushNamedAndRemoveUntil(context, Routes.authLogin, (r) => false)),
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
