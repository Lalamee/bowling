import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/routing/routes.dart';
import '../../../../shared/widgets/titles/bowling_market_title.dart';
import '../widgets/brand_button.dart';
import '../widgets/inputs.dart';

class RecoverAskLoginScreen extends StatefulWidget {
  const RecoverAskLoginScreen({super.key});

  @override
  State<RecoverAskLoginScreen> createState() => _RecoverAskLoginScreenState();
}

class _RecoverAskLoginScreenState extends State<RecoverAskLoginScreen> {
  final _login = TextEditingController();

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
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Восстановить пароль', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(controller: _login, hint: 'Логин/телефон', prefixIcon: Icons.person_outline),
                  const SizedBox(height: 20),
                  BrandButton(text: 'Восстановить пароль', onPressed: () => Navigator.pushNamed(context, Routes.recoverCode)),
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
