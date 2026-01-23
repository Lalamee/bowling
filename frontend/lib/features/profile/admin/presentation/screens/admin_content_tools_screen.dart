import 'package:flutter/material.dart';

import '../../../../../core/routing/routes.dart';
import '../../../../../core/theme/colors.dart';
import '../../../../../shared/widgets/tiles/profile_tile.dart';

class AdminContentToolsScreen extends StatelessWidget {
  const AdminContentToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Инструменты наполнения',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textDark),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          ProfileTile(
            icon: Icons.picture_as_pdf_outlined,
            text: 'Добавить документ в базу знаний',
            onTap: () => Navigator.pushNamed(context, Routes.adminKnowledgeBaseUpload),
          ),
          const SizedBox(height: 10),
          ProfileTile(
            icon: Icons.build_outlined,
            text: 'Добавить позицию в каталог запчастей',
            onTap: () => Navigator.pushNamed(context, Routes.adminPartsCatalogCreate),
          ),
        ],
      ),
    );
  }
}
