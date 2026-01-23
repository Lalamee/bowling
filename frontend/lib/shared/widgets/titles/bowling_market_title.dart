import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';

class BowlingMarketTitle extends StatelessWidget {
  final double? fontSize;
  final FontWeight? fontWeight;

  const BowlingMarketTitle({
    super.key,
    this.fontSize,
    this.fontWeight,
  });

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.mainWelcomeTitle.copyWith(
      fontSize: fontSize ?? AppTextStyles.mainWelcomeTitle.fontSize,
      fontWeight: fontWeight ?? AppTextStyles.mainWelcomeTitle.fontWeight,
    );

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'Bowling ',
            style: style.copyWith(color: AppColors.black),
          ),
          TextSpan(
            text: 'Manager',
            style: style.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
