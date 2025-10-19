import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';

class OnboardingCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const OnboardingCard({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 120, color: Colors.grey),
          SizedBox(height: 40),
          Text(title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          SizedBox(height: 20),
          Text(subtitle, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}