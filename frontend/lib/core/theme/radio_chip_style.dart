import 'package:flutter/material.dart';
import 'colors.dart';
import 'text_styles.dart';

class RadioChipStyle {
  static const double borderRadius = 18;
  static const EdgeInsets padding = EdgeInsets.symmetric(horizontal: 12, vertical: 8);

  static TextStyle textStyle(bool selected) {
    return AppTextStyles.formLabel.copyWith(
      fontWeight: FontWeight.w500,
      color: selected ? AppColors.primary : Colors.black87,
    );
  }
}
