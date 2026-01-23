import 'package:flutter/material.dart';

import '../../../../../core/repositories/parts_repository.dart';
import '../../../../../core/theme/colors.dart';
import '../../../../../core/utils/net_ui.dart';

class AdminPartsCatalogCreateScreen extends StatefulWidget {
  const AdminPartsCatalogCreateScreen({super.key});

  @override
  State<AdminPartsCatalogCreateScreen> createState() => _AdminPartsCatalogCreateScreenState();
}

class _AdminPartsCatalogCreateScreenState extends State<AdminPartsCatalogCreateScreen> {
  final PartsRepository _partsRepository = PartsRepository();

  final TextEditingController _catalogNumberCtrl = TextEditingController();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _descriptionCtrl = TextEditingController();
  final TextEditingController _categoryCtrl = TextEditingController();
  bool _isUnique = false;

  @override
  void dispose() {
    _catalogNumberCtrl.dispose();
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final catalogNumber = _catalogNumberCtrl.text.trim();
    if (catalogNumber.isEmpty) {
      showSnack(context, 'Укажите каталожный номер');
      return;
    }

    final created = await handleApiCall(
      context,
      () => _partsRepository.createOrFindCatalog(
        catalogNumber: catalogNumber,
        name: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
        description: _descriptionCtrl.text.trim().isEmpty ? null : _descriptionCtrl.text.trim(),
        categoryCode: _categoryCtrl.text.trim().isEmpty ? null : _categoryCtrl.text.trim(),
        isUnique: _isUnique,
      ),
      successMessage: 'Каталог обновлён',
    );

    if (!mounted || created == null) return;

    _catalogNumberCtrl.clear();
    _nameCtrl.clear();
    _descriptionCtrl.clear();
    _categoryCtrl.clear();
    setState(() => _isUnique = false);
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
          'Каталог запчастей',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textDark),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _buildField(controller: _catalogNumberCtrl, label: 'Каталожный номер *'),
          const SizedBox(height: 12),
          _buildField(controller: _nameCtrl, label: 'Название'),
          const SizedBox(height: 12),
          _buildField(controller: _descriptionCtrl, label: 'Описание', maxLines: 3),
          const SizedBox(height: 12),
          _buildField(controller: _categoryCtrl, label: 'Код категории'),
          const SizedBox(height: 8),
          SwitchListTile(
            value: _isUnique,
            onChanged: (value) => setState(() => _isUnique = value),
            title: const Text('Уникальная запчасть'),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Сохранить позицию', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
