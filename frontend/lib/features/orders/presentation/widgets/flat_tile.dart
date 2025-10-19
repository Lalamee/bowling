import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';

class FlatTile extends StatelessWidget {
  final String label;
  final IconData? trailing;
  final VoidCallback? onTap;

  const FlatTile({
    Key? key,
    required this.label,
    this.trailing,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.lightGray),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(child: Text(label, style: const TextStyle(color: Color(0xFF23262F), fontSize: 14, fontWeight: FontWeight.w500))),
              if (trailing != null) Icon(trailing, color: AppColors.darkGray, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
