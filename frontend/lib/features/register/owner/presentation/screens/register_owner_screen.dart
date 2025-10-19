import 'package:flutter/material.dart';
import '../../../../../core/theme/colors.dart';
import '../../../../../shared/widgets/buttons/custom_button.dart';
import '../../../../../shared/widgets/chips/radio_group_vertical.dart';
import '../../../../../shared/widgets/chips/radio_group_horizontal.dart';
import '../../../../../shared/widgets/layout/common_ui.dart';
import '../../../../../shared/widgets/inputs/labeled_text_field.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../../core/services/auth_service.dart';

class RegisterOwnerScreen extends StatefulWidget {
  const RegisterOwnerScreen({Key? key}) : super(key: key);

  @override
  State<RegisterOwnerScreen> createState() => _RegisterOwnerScreenState();
}

class _RegisterOwnerScreenState extends State<RegisterOwnerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fio = TextEditingController();
  final _phone = TextEditingController();
  final _inn = TextEditingController();
  final _club = TextEditingController();
  final _addr = TextEditingController();
  final _lanes = TextEditingController();
  final _skills = TextEditingController();
  final _customEquipment = TextEditingController();

  int _step = 0;
  String? status;
  String? selectedEquipment;

  final List<String> _equipmentOptions = ['AMF', 'Brunswick', 'VIA', 'XIMA', 'другое'];

  GlobalKey<FormState> get formKey => _formKey;
  int get step => _step;

  void nextStep() {
    if (_step < 1) {
      setState(() => _step++);
    }
  }

  void prevStep() {
    if (_step > 0) {
      setState(() => _step--);
    }
  }

  @override
  void dispose() {
    [_fio, _phone, _inn, _club, _addr, _lanes, _skills, _customEquipment].forEach((c) => c.dispose());
    super.dispose();
  }

  void _showBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.primary),
    );
  }

  void _nextStepGuarded() {
    if (!(formKey.currentState?.validate() ?? false)) return;
    if (step == 0 && (status == null || status!.isEmpty)) {
      _showBar('Выберите статус');
      return;
    }
    nextStep();
  }

  void _submit() async {
    if (!formKey.currentState!.validate() || status == null || selectedEquipment == null) {
      if (status == null) _showBar('Выберите статус');
      if (selectedEquipment == null) _showBar('Выберите оборудование');
      return;
    }

    final data = {
      'phone': _phone.text.trim(),
      'password': 'password123',
      'inn': _inn.text.trim(),
      'legalName': _club.text.trim(),
      'contactPerson': _fio.text.trim(),
      'contactPhone': _phone.text.trim(),
      'contactEmail': 'example@example.com',
    };

    final success = await AuthService.registerOwner(data);

    if (success) {
      _showBar('Регистрация владельца выполнена');
    } else {
      _showBar('Ошибка регистрации');
    }
  }

  @override
  Widget build(BuildContext ctx) {
    final steps = [_buildStepOne(ctx), _buildStepTwo(ctx)];
    final isLast = step == steps.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: formKey,
                  child: steps[step],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: isLast
                  ? CustomButton(text: 'Зарегистрироваться', onPressed: _submit)
                  : CustomButton(text: 'Далее', onPressed: _nextStepGuarded),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepOne(BuildContext ctx) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.arrow_back, color: AppColors.primary)),
        formStepTitle('Добро пожаловать!'),
        formDescription('Это нужно, чтобы мы знали, каким клубом вы управляете, и могли предоставить вам доступ к инструментам управления.'),
        LabeledTextField(label: 'ФИО', controller: _fio, validator: Validators.notEmpty, icon: Icons.person),
        LabeledTextField(label: 'Номер телефона', controller: _phone, validator: Validators.phone, keyboardType: TextInputType.phone, icon: Icons.phone),
        LabeledTextField(label: 'ИНН организации', controller: _inn, validator: Validators.notEmpty, keyboardType: TextInputType.number, icon: Icons.badge),
        LabeledTextField(label: 'Адрес клуба', controller: _addr, validator: Validators.notEmpty, icon: Icons.location_on),
        formDescription('Ваш статус:'),
        RadioGroupHorizontal(
          options: const ['ИП', 'Самозанятый'],
          groupValue: status,
          onChanged: (v) => setState(() => status = v),
        ),
      ],
    );
  }

  Widget _buildStepTwo(BuildContext ctx) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(onPressed: prevStep, icon: const Icon(Icons.arrow_back, color: AppColors.primary)),
        sectionTitle('Расскажите о Вашем клубе:'),
        formDescription('Укажите количество дорожек и установленное оборудование.'),
        LabeledTextField(label: 'Название клуба', controller: _club, validator: Validators.notEmpty, icon: Icons.sports),
        LabeledTextField(label: 'Количество дорожек', controller: _lanes, validator: Validators.integer, keyboardType: TextInputType.number, icon: Icons.format_list_numbered),
        formDescription('Какое оборудование стоит в клубе:'),
        RadioGroupVertical(
          options: _equipmentOptions,
          groupValue: selectedEquipment,
          onChanged: (v) => setState(() => selectedEquipment = v),
        ),
        if (selectedEquipment == 'другое')
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: LabeledTextField(
              label: 'Уточните',
              controller: _customEquipment,
              validator: Validators.notEmpty,
            ),
          ),
      ],
    );
  }
}
