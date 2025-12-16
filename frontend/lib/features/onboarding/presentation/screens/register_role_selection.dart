import 'package:flutter/material.dart';
import '../../../register/owner/presentation/screens/register_owner_screen.dart';
import '../../../register/mechanic/presentation/screens/register_mechanic_screen.dart';
import '../../../register/manager/presentation/screens/register_manager_screen.dart';
import '../../../../shared/widgets/titles/bowling_market_title.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/colors.dart';

class RegisterRoleSelectionScreen extends StatelessWidget {
  const RegisterRoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 12, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterMechanicScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(60),
                  backgroundColor: Colors.grey[700],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text(
                  'Я МЕХАНИК',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: ElevatedButton(
                onPressed: () => _showClubRoleOptions(context),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(60),
                  backgroundColor: const Color(0xFFB2002D),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text(
                  'Я ВЛАДЕЛЕЦ (МЕНЕДЖЕР) КЛУБА',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
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

void _showClubRoleOptions(BuildContext context) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.business_outlined),
              title: const Text('Я владелец клуба'),
              onTap: () {
                Navigator.pop(ctx);
                _showAuthOptions(context, const RegisterOwnerScreen());
              },
            ),
            ListTile(
              leading: const Icon(Icons.badge_outlined),
              title: const Text('Я менеджер клуба'),
              onTap: () {
                Navigator.pop(ctx);
                _showAuthOptions(context, const RegisterManagerScreen());
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      );
    },
  );
}

void _showAuthOptions(BuildContext context, Widget registerScreen) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text('Войти'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, Routes.authLogin);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add_alt_1_outlined),
              title: const Text('Зарегистрироваться'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => registerScreen));
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      );
    },
  );
}
