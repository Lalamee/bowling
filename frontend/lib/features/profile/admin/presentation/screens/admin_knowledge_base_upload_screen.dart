import 'dart:developer';

import 'package:flutter/material.dart';

import '../../../../../core/repositories/clubs_repository.dart';
import '../../../../../core/theme/colors.dart';
import '../../../../../core/utils/net_ui.dart';
import '../../../../../features/knowledge_base/data/knowledge_base_repository.dart';
import '../../../../../models/club_summary_dto.dart';
import '../../../../../models/knowledge_base_document_create_dto.dart';

class AdminKnowledgeBaseUploadScreen extends StatefulWidget {
  const AdminKnowledgeBaseUploadScreen({super.key});

  @override
  State<AdminKnowledgeBaseUploadScreen> createState() => _AdminKnowledgeBaseUploadScreenState();
}

class _AdminKnowledgeBaseUploadScreenState extends State<AdminKnowledgeBaseUploadScreen> {
  final ClubsRepository _clubsRepository = ClubsRepository();
  final KnowledgeBaseRepository _knowledgeBaseRepository = KnowledgeBaseRepository();

  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _descriptionCtrl = TextEditingController();
  final TextEditingController _typeCtrl = TextEditingController();
  final TextEditingController _manufacturerCtrl = TextEditingController();
  final TextEditingController _equipmentCtrl = TextEditingController();
  final TextEditingController _languageCtrl = TextEditingController();
  final TextEditingController _accessLevelCtrl = TextEditingController();
  final TextEditingController _fileNameCtrl = TextEditingController();
  final TextEditingController _base64Ctrl = TextEditingController();

  List<ClubSummaryDto> _clubs = [];
  int? _selectedClubId;
  bool _loadingClubs = true;

  @override
  void initState() {
    super.initState();
    _loadClubs();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _typeCtrl.dispose();
    _manufacturerCtrl.dispose();
    _equipmentCtrl.dispose();
    _languageCtrl.dispose();
    _accessLevelCtrl.dispose();
    _fileNameCtrl.dispose();
    _base64Ctrl.dispose();
    super.dispose();
  }

  Future<void> _loadClubs() async {
    try {
      setState(() => _loadingClubs = true);
      final clubs = await _clubsRepository.getClubs();
      if (!mounted) return;
      setState(() {
        _clubs = clubs;
        if (_clubs.isNotEmpty) {
          _selectedClubId ??= _clubs.first.id;
        }
        _loadingClubs = false;
      });
    } catch (e, s) {
      log('Failed to load clubs: $e', stackTrace: s);
      if (!mounted) return;
      setState(() => _loadingClubs = false);
      showApiError(context, e);
    }
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    final base64 = _base64Ctrl.text.trim();

    if (title.isEmpty) {
      showSnack(context, 'Укажите название документа');
      return;
    }
    if (_selectedClubId == null) {
      showSnack(context, 'Выберите клуб');
      return;
    }
    if (base64.isEmpty) {
      showSnack(context, 'Добавьте base64 содержимое PDF');
      return;
    }

    final payload = KnowledgeBaseDocumentCreateDto(
      clubId: _selectedClubId!,
      title: title,
      description: _descriptionCtrl.text.trim().isEmpty ? null : _descriptionCtrl.text.trim(),
      documentType: _typeCtrl.text.trim().isEmpty ? null : _typeCtrl.text.trim(),
      manufacturer: _manufacturerCtrl.text.trim().isEmpty ? null : _manufacturerCtrl.text.trim(),
      equipmentModel: _equipmentCtrl.text.trim().isEmpty ? null : _equipmentCtrl.text.trim(),
      language: _languageCtrl.text.trim().isEmpty ? null : _languageCtrl.text.trim(),
      accessLevel: _accessLevelCtrl.text.trim().isEmpty ? null : _accessLevelCtrl.text.trim(),
      fileName: _fileNameCtrl.text.trim().isEmpty ? null : _fileNameCtrl.text.trim(),
      fileBase64: base64,
    );

    final created = await handleApiCall(
      context,
      () => _knowledgeBaseRepository.createDocument(payload),
      successMessage: 'Документ добавлен',
    );
    if (!mounted || created == null) return;

    _titleCtrl.clear();
    _descriptionCtrl.clear();
    _typeCtrl.clear();
    _manufacturerCtrl.clear();
    _equipmentCtrl.clear();
    _languageCtrl.clear();
    _accessLevelCtrl.clear();
    _fileNameCtrl.clear();
    _base64Ctrl.clear();
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
          'База знаний',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textDark),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const Text(
            'Загрузите PDF в формате base64, чтобы сразу проверить работу базы знаний в приложении.',
            style: TextStyle(fontSize: 14, color: AppColors.darkGray),
          ),
          const SizedBox(height: 16),
          _buildClubSelector(),
          const SizedBox(height: 12),
          _buildField(controller: _titleCtrl, label: 'Название документа *'),
          const SizedBox(height: 12),
          _buildField(controller: _descriptionCtrl, label: 'Описание'),
          const SizedBox(height: 12),
          _buildField(controller: _typeCtrl, label: 'Тип документа'),
          const SizedBox(height: 12),
          _buildField(controller: _manufacturerCtrl, label: 'Производитель'),
          const SizedBox(height: 12),
          _buildField(controller: _equipmentCtrl, label: 'Модель оборудования'),
          const SizedBox(height: 12),
          _buildField(controller: _languageCtrl, label: 'Язык'),
          const SizedBox(height: 12),
          _buildField(controller: _accessLevelCtrl, label: 'Уровень доступа'),
          const SizedBox(height: 12),
          _buildField(controller: _fileNameCtrl, label: 'Имя файла'),
          const SizedBox(height: 12),
          _buildField(
            controller: _base64Ctrl,
            label: 'Base64 PDF *',
            maxLines: 5,
            hint: 'Можно вставить строку с data:application/pdf;base64,...',
          ),
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
              child: const Text('Добавить документ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClubSelector() {
    if (_loadingClubs) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_clubs.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Клубы не найдены', style: TextStyle(color: AppColors.darkGray)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _loadClubs,
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            label: const Text('Обновить', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      );
    }

    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Клуб',
        border: OutlineInputBorder(),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedClubId,
          items: _clubs
              .map(
                (club) => DropdownMenuItem(
                  value: club.id,
                  child: Text(club.name),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => _selectedClubId = value),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
