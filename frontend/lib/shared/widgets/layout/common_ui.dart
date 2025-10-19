import 'package:flutter/material.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/colors.dart';
import '../buttons/custom_button.dart';

class CommonUI {
  static const double radius = 16;

  static BoxDecoration cardDecoration({
    Color color = AppColors.white,
    double blur = 8,
    double spread = 0,
    Offset offset = const Offset(0, 2),
    Color shadow = AppColors.shadowSoft,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [BoxShadow(color: shadow, blurRadius: blur, spreadRadius: spread, offset: offset)],
    );
  }

  static Widget card({
    required Widget child,
    EdgeInsets? padding,
    EdgeInsets? margin,
    Color color = AppColors.white,
  }) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: cardDecoration(color: color),
      child: child,
    );
  }
}

Widget formStepTitle(String text) {
  return Text(text, style: AppTextStyles.mainWelcomeTitle);
}

Widget sectionTitle(String text) {
  return Text(text, style: AppTextStyles.sectionTitle);
}

Widget formDescription(String text) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(text, style: AppTextStyles.onboardingSubtitle),
  );
}

Widget stepNavigationButton(String text, VoidCallback onPressed) {
  return SizedBox(
    width: double.infinity,
    height: 65,
    child: CustomButton(text: text, onPressed: onPressed),
  );
}
