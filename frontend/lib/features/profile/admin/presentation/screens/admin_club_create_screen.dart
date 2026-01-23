import 'package:flutter/material.dart';

import '../../../../../core/repositories/clubs_repository.dart';
import '../../../../../core/theme/colors.dart';
import '../../../../../core/utils/net_ui.dart';
import '../../../../../models/club_create_dto.dart';

class AdminClubCreateScreen extends StatefulWidget {
  const AdminClubCreateScreen({super.key});

  @override
  State<AdminClubCreateScreen> createState() => _AdminClubCreateScreenState();
}

class _AdminClubCreateScreenState extends State<AdminClubCreateScreen> {
  final ClubsRepository _clubsRepository = ClubsRepository();

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _lanesCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _lanesCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final address = _addressCtrl.text.trim();
    if (name.isEmpty) {
      showSnack(context, 'Введите название клуба');
      return;
    }
    if (address.isEmpty) {
      showSnack(context, 'Введите адрес клуба');
      return;
    }

    final lanesRaw = _lanesCtrl.text.trim();
    final lanes = lanesRaw.isEmpty ? null : int.tryParse(lanesRaw);

    if (lanesRaw.isNotEmpty && lanes == null) {
      showSnack(context, 'Количество дорожек должно быть числом');
      return;
    }

    final created = await handleApiCall(
      context,
      () => _clubsRepository.createClub(
        ClubCreateDto(
          name: name,
          address: address,
          lanesCount: lanes,
          contactPhone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
          contactEmail: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        ),
      ),
      successMessage: 'Клуб добавлен',
    );

    if (!mounted || created == null) return;
    Navigator.pop(context, created);
  }

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
          'Новый клуб',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textDark),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _buildField(controller: _nameCtrl, label: 'Название клуба *'),
          const SizedBox(height: 12),
          _buildField(controller: _addressCtrl, label: 'Адрес клуба *'),
          const SizedBox(height: 12),
          _buildField(
            controller: _lanesCtrl,
            label: 'Количество дорожек',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          _buildField(controller: _phoneCtrl, label: 'Контактный телефон'),
          const SizedBox(height: 12),
          _buildField(controller: _emailCtrl, label: 'Контактный email'),
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Добавить клуб', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
