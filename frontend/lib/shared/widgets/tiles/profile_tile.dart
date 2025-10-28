import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';

class ProfileTile extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final bool danger;
  final bool showAlertBadge;
  final int? badgeCount;

  const ProfileTile({
    Key? key,
    required this.icon,
    required this.text,
    this.onTap,
    this.onEdit,
    this.danger = false,
    this.showAlertBadge = false,
    this.badgeCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final baseStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: danger ? const Color(0xFFEB003B) : AppColors.textDark,
      height: 1.2,
    );

    return InkWell(
      onTap: onTap ?? onEdit,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(color: AppColors.lightGray),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: baseStyle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if ((badgeCount ?? 0) > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEB003B),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${badgeCount!}',
                  style: const TextStyle(color: AppColors.white, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ] else if (showAlertBadge) ...[
              const SizedBox(width: 8),
              Container(
                width: 18,
                height: 18,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFFEB003B),
                  shape: BoxShape.circle,
                ),
                child: const Text('!', style: TextStyle(color: AppColors.white, fontSize: 12)),
              ),
            ],
            if (onEdit != null) ...[
              const SizedBox(width: 8),
              InkWell(
                onTap: onEdit,
                child: Icon(Icons.edit, size: 18, color: AppColors.primary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
