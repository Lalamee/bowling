import 'package:flutter/material.dart';
import '../../../register/owner/presentation/screens/register_owner_screen.dart';
import '../../../register/mechanic/presentation/screens/register_mechanic_screen.dart';
import '../../../register/manager/presentation/screens/register_manager_screen.dart';
import '../../../../shared/widgets/titles/bowling_market_title.dart';

class RegisterRoleSelectionScreen extends StatelessWidget {
  const RegisterRoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterMechanicScreen()));
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
                Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterOwnerScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.badge_outlined),
              title: const Text('Я менеджер клуба'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterManagerScreen()));
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      );
    },
  );
}
