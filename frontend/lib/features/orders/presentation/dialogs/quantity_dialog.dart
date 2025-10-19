import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';

class QuantityDialog extends StatefulWidget {
  const QuantityDialog({Key? key}) : super(key: key);

  @override
  State<QuantityDialog> createState() => _QuantityDialogState();
}

class _QuantityDialogState extends State<QuantityDialog> {
  int value = 1;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close, size: 20, color: AppColors.darkGray),
              ),
            ),
            const SizedBox(height: 2),
            const Text('Укажите количество деталей', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF23262F))),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _square(
                  onTap: () => setState(() => value = value > 1 ? value - 1 : 1),
                  child: const Icon(Icons.remove, size: 22, color: Color(0xFF23262F)),
                ),
                const SizedBox(width: 24),
                Text('$value', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w600, color: Color(0xFF23262F))),
                const SizedBox(width: 24),
                _square(
                  onTap: () => setState(() => value += 1),
                  child: const Icon(Icons.add, size: 22, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop<int>(context, value),
                child: const Text('Добавить детали'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _square({required Widget child, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.lightGray),
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}
