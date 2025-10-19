import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/routing/routes.dart';
import '../../../../shared/widgets/titles/bowling_market_title.dart';
import '../widgets/brand_button.dart';

class RecoverCodeScreen extends StatefulWidget {
  const RecoverCodeScreen({super.key});

  @override
  State<RecoverCodeScreen> createState() => _RecoverCodeScreenState();
}

class _RecoverCodeScreenState extends State<RecoverCodeScreen> {
  final _nodes = List.generate(4, (_) => FocusNode());
  final _ctrls = List.generate(4, (_) => TextEditingController());

  @override
  void dispose() {
    for (final n in _nodes) n.dispose();
    for (final c in _ctrls) c.dispose();
    super.dispose();
  }

  void _onChanged(int i, String v) {
    if (v.isNotEmpty && i < 3) FocusScope.of(context).requestFocus(_nodes[i + 1]);
    if (v.isEmpty && i > 0) FocusScope.of(context).requestFocus(_nodes[i - 1]);
    setState(() {});
  }

  Widget _box(int i) {
    return SizedBox(
      width: 58,
      height: 58,
      child: TextField(
        controller: _ctrls[i],
        focusNode: _nodes[i],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: Colors.white,
          prefixIconColor: AppColors.darkGray,
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.mutedGray)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
        ),
        onChanged: (v) => _onChanged(i, v),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Введите код из ....', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      _box(0),
                      const SizedBox(width: 14),
                      _box(1),
                      const SizedBox(width: 14),
                      _box(2),
                      const SizedBox(width: 14),
                      _box(3),
                    ],
                  ),
                  const SizedBox(height: 20),
                  BrandButton(text: 'Подтвердить смену пароля', onPressed: () => Navigator.pushNamed(context, Routes.recoverNewPass)),
                ],
              ),
            ),
            const Spacer(),
            const Padding(
              padding: EdgeInsets.only(bottom: 24),
              child: BowlingMarketTitle(fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }
}
