import 'package:flutter/material.dart';
import 'colors.dart';

class AppTextStyles {
  static const TextStyle onboardingTitle = TextStyle(
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w700,
    fontSize: 28,
    height: 30 / 28,
    letterSpacing: -0.02 * 28,
    color: AppColors.textDark,
  );

  static const TextStyle onboardingSubtitle = TextStyle(
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w300,
    fontSize: 20,
    height: 30 / 20,
    letterSpacing: -0.02 * 20,
    color: AppColors.textDark,
  );

  static const TextStyle formLabel = TextStyle(
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w500,
    fontSize: 10,
    height: 1.0,
    letterSpacing: -0.2,
    color: AppColors.darkGray,
  );

  static const TextStyle formHint = TextStyle(
    color: Colors.grey,
  );

  static const TextStyle formInput = TextStyle(
    color: AppColors.textDark,
  );

  static const TextStyle mainWelcomeTitle = TextStyle(
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w700,
    fontSize: 32,
    height: 1.25,
    letterSpacing: -0.04,
    color: AppColors.primary,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w500,
    fontSize: 20,
    height: 1.0,
    letterSpacing: -0.02,
    color: AppColors.darkGray,
  );
}
