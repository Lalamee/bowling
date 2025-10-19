import 'package:flutter/material.dart';
import 'text_styles.dart';

@immutable
class AppTypography extends ThemeExtension<AppTypography> {
  final TextStyle onboardingTitle;
  final TextStyle onboardingSubtitle;
  final TextStyle formLabel;
  final TextStyle formHint;
  final TextStyle formInput;
  final TextStyle mainWelcomeTitle;
  final TextStyle sectionTitle;

  const AppTypography({
    required this.onboardingTitle,
    required this.onboardingSubtitle,
    required this.formLabel,
    required this.formHint,
    required this.formInput,
    required this.mainWelcomeTitle,
    required this.sectionTitle,
  });

  const AppTypography.fromDefaults()
      : onboardingTitle = AppTextStyles.onboardingTitle,
        onboardingSubtitle = AppTextStyles.onboardingSubtitle,
        formLabel = AppTextStyles.formLabel,
        formHint = AppTextStyles.formHint,
        formInput = AppTextStyles.formInput,
        mainWelcomeTitle = AppTextStyles.mainWelcomeTitle,
        sectionTitle = AppTextStyles.sectionTitle;

  @override
  AppTypography copyWith({
    TextStyle? onboardingTitle,
    TextStyle? onboardingSubtitle,
    TextStyle? formLabel,
    TextStyle? formHint,
    TextStyle? formInput,
    TextStyle? mainWelcomeTitle,
    TextStyle? sectionTitle,
  }) {
    return AppTypography(
      onboardingTitle: onboardingTitle ?? this.onboardingTitle,
      onboardingSubtitle: onboardingSubtitle ?? this.onboardingSubtitle,
      formLabel: formLabel ?? this.formLabel,
      formHint: formHint ?? this.formHint,
      formInput: formInput ?? this.formInput,
      mainWelcomeTitle: mainWelcomeTitle ?? this.mainWelcomeTitle,
      sectionTitle: sectionTitle ?? this.sectionTitle,
    );
  }

  @override
  AppTypography lerp(ThemeExtension<AppTypography>? other, double t) {
    if (other is! AppTypography) return this;
    return this;
  }
}

extension AppTypographyX on BuildContext {
  AppTypography get typo => Theme.of(this).extension<AppTypography>()!;
}