// lib/features/shared/widgets/layout/section_list.dart
import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import 'common_ui.dart';

class SectionList extends StatelessWidget {
  final List<String> items;
  final int selected;
  final ValueChanged<int> onSelect;

  const SectionList({
    Key? key,
    required this.items,
    required this.selected,
    required this.onSelect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: CommonUI.cardDecoration(color: AppColors.white),
      child: Column(
        children: List.generate(items.length, (index) {
          final isActive = index == selected;
          return InkWell(
            onTap: () => onSelect(index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: index == items.length - 1 ? Colors.transparent : AppColors.lightGray,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    items[index],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isActive ? AppColors.primary : AppColors.textDark,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.keyboard_arrow_down, color: isActive ? AppColors.primary : AppColors.darkGray),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
