import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';

class ConfirmOrderDialog extends StatelessWidget {
  final String orderNumber;

  const ConfirmOrderDialog({Key? key, this.orderNumber = 'Заказ №25'}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.lightGray),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(orderNumber, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF23262F))),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
