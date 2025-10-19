import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../shared/widgets/titles/bowling_market_title.dart';
import 'onboarding_screen.dart';

class SplashFirstTime extends StatefulWidget {
  const SplashFirstTime({super.key});
  @override
  State<SplashFirstTime> createState() => _SplashFirstTimeState();
}

class _SplashFirstTimeState extends State<SplashFirstTime> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            const BowlingMarketTitle(fontSize: 32),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Всё для эффективного управления и обслуживания боулинга — от механиков до собственников',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppColors.darkGray),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'Version 1.0',
                style: const TextStyle(fontSize: 11, color: AppColors.darkGray),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
