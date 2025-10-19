import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../shared/widgets/inputs/labeled_text_field.dart';
import '../../../../shared/widgets/inputs/adaptive_text.dart';

class PositionCard extends StatelessWidget {
  final bool selected;
  final String title;
  final VoidCallback onEdit;
  final TextEditingController cellCtrl;
  final TextEditingController shelfCtrl;
  final TextEditingController markCtrl;

  const PositionCard({
    Key? key,
    required this.selected,
    required this.title,
    required this.onEdit,
    required this.cellCtrl,
    required this.shelfCtrl,
    required this.markCtrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: selected ? AppColors.primary : AppColors.lightGray, width: 1.5),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Column(
        children: [
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: AdaptiveText(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark, fontSize: 16),
                  ),
                ),
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, size: 18, color: AppColors.primary),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFEDEDED)),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                LabeledTextField(label: '№ Ячейки', controller: cellCtrl),
                const SizedBox(height: 8),
                LabeledTextField(label: '№ Номер полки', controller: shelfCtrl),
                const SizedBox(height: 8),
                LabeledTextField(label: 'Ориентир', controller: markCtrl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
