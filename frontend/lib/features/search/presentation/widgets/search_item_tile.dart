import 'package:flutter/material.dart';

import '../../../../core/theme/colors.dart';
import '../../../search/domain/search_item.dart';
import '../../../../shared/widgets/highlight_text.dart';

class SearchItemTile extends StatelessWidget {
  const SearchItemTile({
    super.key,
    required this.item,
    required this.query,
    this.onTap,
  });

  final SearchItem item;
  final String query;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E5E5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              offset: const Offset(0, 2),
              blurRadius: 6,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(item.domain.icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.domain.label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                if (item.trailing != null && item.trailing!.trim().isNotEmpty)
                  Text(
                    item.trailing!,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.darkGray,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            HighlightText(
              text: item.title,
              highlight: query,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
              highlightStyle: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (item.subtitle.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              HighlightText(
                text: item.subtitle,
                highlight: query,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.darkGray,
                ),
                highlightStyle: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

