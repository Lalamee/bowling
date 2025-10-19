import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';

class IconSquareButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const IconSquareButton({Key? key, required this.icon, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.lightGray),
          boxShadow: const [BoxShadow(color: AppColors.shadowSoft, blurRadius: 6, offset: Offset(0, 2))],
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: AppColors.textDark, size: 20),
      ),
    );
  }
}

