import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';

class MiniAddButton extends StatelessWidget {
  final VoidCallback onTap;

  const MiniAddButton({Key? key, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.lightGray),
          boxShadow: const [BoxShadow(color: AppColors.shadowSoft, blurRadius: 6, offset: Offset(0, 2))],
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.add, color: AppColors.primary, size: 18),
      ),
    );
  }
}

