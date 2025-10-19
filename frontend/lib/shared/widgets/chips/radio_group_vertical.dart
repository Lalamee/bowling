import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/radio_chip_style.dart';

class RadioGroupVertical extends StatelessWidget {
  final List<String> options;
  final String? groupValue;
  final void Function(String?) onChanged;

  const RadioGroupVertical({
    Key? key,
    required this.options,
    required this.groupValue,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: options.map((label) {
        final isSelected = label == groupValue;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: GestureDetector(
            onTap: () => onChanged(label),
            child: Row(
              children: [
                Radio<String>(
                  value: label,
                  groupValue: groupValue,
                  onChanged: (val) => onChanged(val),
                  activeColor: AppColors.primary,
                  visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                Container(
                  padding: RadioChipStyle.padding,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(RadioChipStyle.borderRadius),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.grey.shade400,
                    ),
                  ),
                  child: Text(
                    label,
                    style: RadioChipStyle.textStyle(isSelected),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
