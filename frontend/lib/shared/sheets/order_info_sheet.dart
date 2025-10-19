import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';

class OrderInfoSheet extends StatelessWidget {
  const OrderInfoSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: ListView(
            controller: controller,
            children: [
              Row(
                children: [
                  const Expanded(child: Text('Дорожка 1', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF23262F)))),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, size: 22, color: Color(0xFF6F6F6F)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Технические характеристики:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF23262F))),
              const SizedBox(height: 8),
              const _Bullet('модель'),
              const _Bullet('год выпуска'),
              const _Bullet('серийный номер пинсетера'),
              const _Bullet('серийный номер электронных комплектующих'),
              const _Bullet('Ещё какая-то информация'),
              const _Bullet('Много информации'),
              const SizedBox(height: 16),
              const Text('Комментарии', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF23262F))),
              const SizedBox(height: 12),
              _comment('06.08.2025 - необходимо заменить деталь'),
              _comment('01.02.2025 - установлен новую деталь'),
              _comment('01.06.2024 - новое оборудование установлено'),
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
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Добавить комментарий'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _comment(String text) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Text(text, style: const TextStyle(fontSize: 14, color: Color(0xFF23262F))),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet(this.text, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 14, color: Color(0xFF23262F))),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14, color: Color(0xFF23262F)))),
        ],
      ),
    );
  }
}
