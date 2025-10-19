import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/radio_chip_style.dart';

class RadioGroupWrap extends StatelessWidget {
  final List<String> options;
  final String? groupValue;
  final void Function(String) onChanged;

  const RadioGroupWrap({
    Key? key,
    required this.options,
    required this.groupValue,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: options.map((option) {
        final bool isSelected = groupValue == option;
        return InkWell(
          borderRadius: BorderRadius.circular(RadioChipStyle.borderRadius),
          onTap: () => onChanged(option),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Radio<String>(
                value: option,
                groupValue: groupValue,
                onChanged: (val) => onChanged(val!),
                activeColor: AppColors.primary,
                visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              Container(
                padding: RadioChipStyle.padding,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.grey.shade300,
                    width: 1.4,
                  ),
                  borderRadius: BorderRadius.circular(RadioChipStyle.borderRadius),
                ),
                child: Text(
                  option,
                  style: RadioChipStyle.textStyle(isSelected),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
