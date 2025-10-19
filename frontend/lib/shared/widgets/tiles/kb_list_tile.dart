import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../inputs/adaptive_text.dart';

class KbListTile extends StatelessWidget {
  final String title;
  final bool accent;
  final VoidCallback onTap;

  const KbListTile({Key? key, required this.title, this.accent = false, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final borderColor = accent ? AppColors.primary : const Color(0xFFEDEDED);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F7),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.history_rounded, size: 16, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AdaptiveText(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textDark),
              ),
            ),
            if (accent) const Icon(Icons.edit, size: 16, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
