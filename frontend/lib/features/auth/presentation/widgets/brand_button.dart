import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';

class BrandButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final double width;

  const BrandButton({super.key, required this.text, required this.onPressed, this.width = 240});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: AppColors.shadowSoft,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed: onPressed,
        child: Text(text),
      ),
    );
  }
}
