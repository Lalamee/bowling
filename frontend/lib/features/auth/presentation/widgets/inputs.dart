import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final TextInputType? keyboardType;

  const AppTextField({super.key, required this.controller, required this.hint, required this.prefixIcon, this.keyboardType});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.textDark),
      decoration: InputDecoration(
        filled: true,
        hintText: hint,
        prefixIcon: Icon(prefixIcon, color: AppColors.darkGray),
      ),
    );
  }
}

class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;

  const PasswordField({super.key, required this.controller, required this.hint});

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final message = _obscure ? 'Показать пароль' : 'Скрыть пароль';
    return TextField(
      controller: widget.controller,
      obscureText: _obscure,
      style: const TextStyle(color: AppColors.textDark),
      decoration: InputDecoration(
        filled: true,
        hintText: widget.hint,
        prefixIcon: const Icon(Icons.lock_outline, color: AppColors.darkGray),
        suffixIcon: Tooltip(
          message: message,
          preferBelow: false,
          child: IconButton(
            onPressed: () => setState(() => _obscure = !_obscure),
            icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppColors.darkGray),
          ),
        ),
      ),
    );
  }
}
