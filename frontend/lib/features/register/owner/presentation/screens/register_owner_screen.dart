import 'package:flutter/material.dart';

import '../../../../../core/routing/routes.dart';
import '../../../../../core/services/auth_service.dart';
import '../../../../../core/services/local_auth_storage.dart';
import '../../../../../core/theme/colors.dart';
import '../../../../../core/utils/net_ui.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../../core/utils/phone_utils.dart';
import '../../../../../shared/widgets/buttons/custom_button.dart';
import '../../../../../shared/widgets/chips/radio_group_horizontal.dart';
import '../../../../../shared/widgets/chips/radio_group_vertical.dart';
import '../../../../../shared/widgets/inputs/labeled_text_field.dart';
import '../../../../../shared/widgets/layout/common_ui.dart';

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
  final _email = TextEditingController();
  final _customEquipment = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirm = TextEditingController();

  int _step = 0;
  String? status;
  String? selectedEquipment;

  final List<String> _equipmentOptions = ['AMF', 'Brunswick', 'VIA', 'XIMA', 'другое'];
  // обновлено по замечанию: юридическое лицо добавлено, самозанятый скрыт
  final List<String> _statusOptions = ['ИП', 'Юрлицо (ООО, ПАО, АО)'];

  GlobalKey<FormState> get formKey => _formKey;
  int get step => _step;
  bool get _isLastStep => _step >= 1;

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
  @override
  void initState() {
    super.initState();
    if (_phone.text.isEmpty) {
      _phone.text = '+7 ';
    }
  }

  @override
  void dispose() {
    [
      _fio,
      _phone,
      _inn,
      _club,
      _addr,
      _lanes,
      _email,
      _customEquipment,
      _password,
      _passwordConfirm,
    ].forEach((c) => c.dispose());
    super.dispose();
  }

  void _showBar(String msg, {bool success = false}) {
    showSnack(context, msg, success: success);
  }

  void _nextStepGuarded() {
    if (!(formKey.currentState?.validate() ?? false)) {
      _showBar('Заполните обязательные поля');
      return;
    }
    if (step == 0 && (status == null || status!.isEmpty)) {
      _showBar('Выберите статус');
      return;
    }
    nextStep();
  }

  Future<void> _submit() async {
    if (!formKey.currentState!.validate() || status == null) {
      if (status == null) _showBar('Выберите статус');
      else _showBar('Заполните обязательные поля');
      return;
    }
    final equipment = selectedEquipment == null
        ? null
        : selectedEquipment == 'другое'
            ? _customEquipment.text.trim()
            : selectedEquipment;
    if (equipment == null || equipment.isEmpty) {
      _showBar('Выберите оборудование');
      return;
    }

    final trimmedFullName = _fio.text.trim();
    final trimmedInn = _inn.text.trim();
    final trimmedClub = _club.text.trim();
    final trimmedAddress = _addr.text.trim();
    final trimmedEmail = _email.text.trim();
    final trimmedLanes = _lanes.text.trim();
    final trimmedStatus = status?.trim();
    final normalizedPhone = PhoneUtils.normalize(_phone.text);
    final password = _password.text.trim();
    final confirmPassword = _passwordConfirm.text.trim();

    final passwordError = Validators.password(password);
    final confirmError = confirmPassword.isEmpty
        ? 'Повторите пароль'
        : (password != confirmPassword ? 'Пароли не совпадают' : null);

    if (passwordError != null) {
      _showBar(passwordError);
      return;
    }
    if (confirmError != null) {
      _showBar(confirmError);
      return;
    }

    final lanesCount = int.tryParse(trimmedLanes);
    if (lanesCount == null || lanesCount <= 0) {
      _showBar('Количество дорожек должно быть положительным числом');
      return;
    }

    final data = {
      'phone': normalizedPhone,
      'password': password,
      'inn': trimmedInn,
      'legalName': trimmedClub,
      'contactPerson': trimmedFullName,
      'contactPhone': normalizedPhone,
      'contactEmail': trimmedEmail,
      'clubName': trimmedClub,
      'clubAddress': trimmedAddress,
      'lanesCount': lanesCount,
      'clubPhone': normalizedPhone,
    };

    final clubs = <String>[];
    if (trimmedClub.isNotEmpty) {
      clubs.add(trimmedClub);
    }

    final profileSnapshot = {
      'fullName': trimmedFullName,
      'phone': normalizedPhone,
      'clubName': trimmedClub,
      'address': trimmedAddress,
      'status': 'Собственник',
      if (trimmedStatus != null && trimmedStatus.isNotEmpty) 'businessStatus': trimmedStatus,
      'clubs': clubs,
      'email': trimmedEmail,
      'inn': trimmedInn,
      'lanes': trimmedLanes,
      'equipment': equipment,
      'workplaceVerified': false,
    };

    final result = await withLoader<bool?>(context, () async {
      final success = await AuthService.registerOwner(data);
      if (!success) {
        throw Exception('Не удалось зарегистрировать владельца. Попробуйте ещё раз.');
      }

      final loginResult = await AuthService.login(phone: normalizedPhone, password: password);
      if (loginResult == null) {
        throw Exception('Регистрация выполнена, но не удалось войти. Попробуйте выполнить вход вручную.');
      }

      await LocalAuthStorage.clearMechanicState();
      await LocalAuthStorage.saveOwnerProfile(profileSnapshot);
      await LocalAuthStorage.setOwnerRegistered(true);
      await LocalAuthStorage.setRegisteredRole('owner');
      return true;
    });

    if (result == true && mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(Routes.profileOwner, (route) => false);
    }
  }

  @override
  Widget build(BuildContext ctx) {
    final steps = [_buildStepOne(ctx), _buildStepTwo(ctx)];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.of(ctx).pushNamedAndRemoveUntil(Routes.welcome, (route) => false);
                },
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary),
                label: const Text('Назад к входу', style: TextStyle(color: AppColors.primary)),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
            ),
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
              child: _isLastStep
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
        TextButton.icon(
          onPressed: () {
            final navigator = Navigator.of(ctx);
            if (navigator.canPop()) {
              navigator.pop();
            }
          },
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          label: const Text('Шаг назад', style: TextStyle(color: AppColors.primary)),
          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
        ),
        formStepTitle('Добро пожаловать!'),
        formDescription('Это нужно, чтобы мы знали, каким клубом вы управляете, и могли предоставить вам доступ к инструментам управления.'),
        LabeledTextField(
            label: 'ФИО/Наименование организации',
            controller: _fio,
            validator: Validators.notEmpty,
            icon: Icons.person,
            isRequired: true),
        LabeledTextField(label: 'Номер телефона', controller: _phone, validator: Validators.phone, keyboardType: TextInputType.phone, icon: Icons.phone, isRequired: true),
        LabeledTextField(label: 'Email', controller: _email, validator: Validators.email, keyboardType: TextInputType.emailAddress, icon: Icons.email, isRequired: true),
        LabeledTextField(label: 'ИНН организации', controller: _inn, validator: Validators.notEmpty, keyboardType: TextInputType.number, icon: Icons.badge, isRequired: true),
        LabeledTextField(label: 'Адрес клуба', controller: _addr, validator: Validators.notEmpty, icon: Icons.location_on, isRequired: true),
        LabeledTextField(
          label: 'Пароль',
          controller: _password,
          validator: Validators.password,
          keyboardType: TextInputType.visiblePassword,
          obscureText: true,
          icon: Icons.lock,
          isRequired: true,
        ),
        LabeledTextField(
          label: 'Повторите пароль',
          controller: _passwordConfirm,
          validator: (value) {
            final text = value?.trim() ?? '';
            if (text.isEmpty) return 'Повторите пароль';
            if (text.length < 8) return 'Пароль должен содержать не менее 8 символов';
            if (_password.text.trim() != text) return 'Пароли не совпадают';
            return null;
          },
          keyboardType: TextInputType.visiblePassword,
          obscureText: true,
          icon: Icons.lock_outline,
          isRequired: true,
        ),
        formDescription('Ваш статус:'),
        RadioGroupHorizontal(
          options: _statusOptions,
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
        TextButton.icon(
          onPressed: prevStep,
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          label: const Text('Шаг назад', style: TextStyle(color: AppColors.primary)),
          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
        ),
        sectionTitle('Расскажите о Вашем клубе:'),
        formDescription('Укажите количество дорожек и установленное оборудование.'),
        LabeledTextField(label: 'Название клуба', controller: _club, validator: Validators.notEmpty, icon: Icons.sports, isRequired: true),
        LabeledTextField(label: 'Количество дорожек', controller: _lanes, validator: Validators.integer, keyboardType: TextInputType.number, icon: Icons.format_list_numbered, isRequired: true),
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
              isRequired: true,
            ),
          ),
      ],
    );
  }
}
