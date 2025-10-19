import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/repositories/maintenance_repository.dart';
import '../../../../models/part_request_dto.dart';
import '../../../../core/utils/net_ui.dart';
import '../../../../shared/widgets/buttons/custom_button.dart';

/// Экран создания новой заявки на обслуживание
class CreateMaintenanceRequestScreen extends StatefulWidget {
  const CreateMaintenanceRequestScreen({super.key});

  @override
  State<CreateMaintenanceRequestScreen> createState() => _CreateMaintenanceRequestScreenState();
}

class _CreateMaintenanceRequestScreenState extends State<CreateMaintenanceRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = MaintenanceRepository();
  
  final _notesController = TextEditingController();
  final _catalogNumberController = TextEditingController();
  final _partNameController = TextEditingController();
  final _quantityController = TextEditingController();
  
  int? clubId;
  int? mechanicId;
  int? laneNumber;
  
  List<RequestedPartDto> requestedParts = [];

  @override
  void dispose() {
    _notesController.dispose();
    _catalogNumberController.dispose();
    _partNameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _addPart() {
    if (_partNameController.text.trim().isEmpty) {
      showSnack(context, 'Укажите название запчасти');
      return;
    }
    final quantity = int.tryParse(_quantityController.text.trim());
    if (quantity == null || quantity <= 0) {
      showSnack(context, 'Укажите корректное количество');
      return;
    }

    setState(() {
      requestedParts.add(RequestedPartDto(
        catalogNumber: _catalogNumberController.text.trim().isEmpty ? null : _catalogNumberController.text.trim(),
        partName: _partNameController.text.trim(),
        quantity: quantity,
      ));
      _catalogNumberController.clear();
      _partNameController.clear();
      _quantityController.clear();
    });
  }

  void _removePart(int index) {
    setState(() {
      requestedParts.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (clubId == null || mechanicId == null) {
      showSnack(context, 'Заполните все обязательные поля');
      return;
    }

    if (requestedParts.isEmpty) {
      showSnack(context, 'Добавьте хотя бы одну запчасть');
      return;
    }

    final request = PartRequestDto(
      clubId: clubId!,
      mechanicId: mechanicId!,
      laneNumber: laneNumber,
      managerNotes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      requestedParts: requestedParts,
    );

    final result = await handleApiCall(
      context,
      () => _repo.create(request),
      successMessage: 'Заявка успешно создана',
    );

    if (result != null && mounted) {
      Navigator.pop(context, true);
    }
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
          'Новая заявка',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textDark),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ID клуба
            _buildTextField(
              label: 'ID клуба *',
              hint: 'Введите ID клуба',
              keyboardType: TextInputType.number,
              validator: (v) => v?.isEmpty ?? true ? 'Обязательное поле' : null,
              onChanged: (v) => clubId = int.tryParse(v),
            ),
            const SizedBox(height: 16),

            // ID механика
            _buildTextField(
              label: 'ID механика *',
              hint: 'Введите ID механика',
              keyboardType: TextInputType.number,
              validator: (v) => v?.isEmpty ?? true ? 'Обязательное поле' : null,
              onChanged: (v) => mechanicId = int.tryParse(v),
            ),
            const SizedBox(height: 16),

            // Номер дорожки
            _buildTextField(
              label: 'Номер дорожки',
              hint: 'Введите номер дорожки',
              keyboardType: TextInputType.number,
              onChanged: (v) => laneNumber = int.tryParse(v),
            ),
            const SizedBox(height: 16),

            // Заметки менеджера
            const Text(
              'Заметки менеджера',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Дополнительная информация (опционально)',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.lightGray),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.lightGray),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Секция добавления запчастей
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'Запчасти',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark),
            ),
            const SizedBox(height: 16),

            // Каталожный номер
            _buildTextField(
              label: 'Каталожный номер',
              hint: 'Введите каталожный номер',
              controller: _catalogNumberController,
            ),
            const SizedBox(height: 16),

            // Название запчасти
            _buildTextField(
              label: 'Название запчасти *',
              hint: 'Введите название',
              controller: _partNameController,
            ),
            const SizedBox(height: 16),

            // Количество
            _buildTextField(
              label: 'Количество *',
              hint: 'Введите количество',
              keyboardType: TextInputType.number,
              controller: _quantityController,
            ),
            const SizedBox(height: 16),

            // Кнопка добавления запчасти
            OutlinedButton.icon(
              onPressed: _addPart,
              icon: const Icon(Icons.add, color: AppColors.primary),
              label: const Text('Добавить запчасть', style: TextStyle(color: AppColors.primary)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 16),

            // Список добавленных запчастей
            if (requestedParts.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.lightGray),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Добавленные запчасти:',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(requestedParts.length, (i) {
                      final part = requestedParts[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    part.partName,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                  ),
                                  if (part.catalogNumber != null)
                                    Text(
                                      'Кат. №: ${part.catalogNumber}',
                                      style: const TextStyle(fontSize: 12, color: AppColors.darkGray),
                                    ),
                                  Text(
                                    'Кол-во: ${part.quantity}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.darkGray),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removePart(i),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            const SizedBox(height: 8),

            // Кнопка создания
            CustomButton(
              text: 'Создать заявку',
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    TextEditingController? controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.lightGray),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.lightGray),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
          validator: validator,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
