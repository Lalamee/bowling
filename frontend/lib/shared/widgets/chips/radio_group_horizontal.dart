import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/radio_chip_style.dart';

class RadioGroupHorizontal extends StatelessWidget {
  final List<String> options;
  final String? groupValue;
  final void Function(String?) onChanged;

  const RadioGroupHorizontal({
    Key? key,
    required this.options,
    required this.groupValue,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: options.map((label) {
        final isSelected = label == groupValue;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
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
                  width: 113,
                  height: 29,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.lightGray,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadowSoft,
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    label,
                    style: RadioChipStyle.textStyle(isSelected),
                    textAlign: TextAlign.center,
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

