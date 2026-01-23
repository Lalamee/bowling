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
  final _addr = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirm = TextEditingController();

  String? status;
  // обновлено по замечанию: юридическое лицо добавлено, самозанятый скрыт
  final List<String> _statusOptions = ['ИП', 'Юрлицо (ООО, ПАО, АО)'];
  GlobalKey<FormState> get formKey => _formKey;

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
      _addr,
      _email,
      _password,
      _passwordConfirm,
    ].forEach((c) => c.dispose());
    super.dispose();
  }

  void _showBar(String msg, {bool success = false}) {
    showSnack(context, msg, success: success);
  }

  Future<void> _submit() async {
    if (!formKey.currentState!.validate() || status == null) {
      if (status == null) _showBar('Выберите статус');
      else _showBar('Заполните обязательные поля');
      return;
    }

    final trimmedFullName = _fio.text.trim();
    final trimmedInn = _inn.text.trim();
    final trimmedAddress = _addr.text.trim();
    final trimmedEmail = _email.text.trim();
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

    final data = {
      'phone': normalizedPhone,
      'password': password,
      'inn': trimmedInn,
      'legalName': trimmedFullName,
      'contactPerson': trimmedFullName,
      'contactPhone': normalizedPhone,
      'contactEmail': trimmedEmail,
      'address': trimmedAddress,
    };

    final profileSnapshot = {
      'fullName': trimmedFullName,
      'phone': normalizedPhone,
      'address': trimmedAddress,
      'status': 'Владелец',
      if (trimmedStatus != null && trimmedStatus.isNotEmpty) 'businessStatus': trimmedStatus,
      'email': trimmedEmail,
      'inn': trimmedInn,
      'workplaceVerified': false,
    };

    final result = await withLoader<bool?>(context, () async {
      final success = await AuthService.registerOwner(data);
      if (!success) {
        throw Exception('Не удалось зарегистрировать владельца. Попробуйте ещё раз.');
      }
      return true;
    });

    if (result == true && mounted) {
      await LocalAuthStorage.clearMechanicState();
      await LocalAuthStorage.saveOwnerProfile(profileSnapshot);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заявка отправлена. Дождитесь подтверждения администрацией сервиса.')),
      );
      Navigator.of(context).pushNamedAndRemoveUntil(Routes.welcome, (route) => false);
    }
  }

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 12, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStepBackButton(ctx),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pushNamedAndRemoveUntil(Routes.welcome, (route) => false);
                    },
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary),
                    label: const Text('Назад к входу', style: TextStyle(color: AppColors.primary)),
                    style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: formKey,
                  child: _buildForm(ctx),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: CustomButton(text: 'Зарегистрироваться', onPressed: _submit),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepBackButton(BuildContext ctx) {
    return TextButton.icon(
      onPressed: () {
        final navigator = Navigator.of(ctx);
        if (navigator.canPop()) {
          navigator.pop();
        }
      },
      icon: const Icon(Icons.arrow_back, color: AppColors.primary),
      label: const Text('Шаг назад', style: TextStyle(color: AppColors.primary)),
      style: TextButton.styleFrom(foregroundColor: AppColors.primary),
    );
  }

  Widget _buildForm(BuildContext ctx) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        formStepTitle('Добро пожаловать!'),
        formDescription('Заполните данные, чтобы мы смогли подтвердить вашу регистрацию.'),
        LabeledTextField(
          label: 'ФИО/Наименование организации',
          controller: _fio,
          validator: Validators.notEmpty,
          icon: Icons.person,
          isRequired: true,
        ),
        LabeledTextField(label: 'Номер телефона', controller: _phone, validator: Validators.phone, keyboardType: TextInputType.phone, icon: Icons.phone, isRequired: true),
        LabeledTextField(label: 'Email', controller: _email, validator: Validators.email, keyboardType: TextInputType.emailAddress, icon: Icons.email, isRequired: true),
        LabeledTextField(label: 'ИНН организации/ИП', controller: _inn, validator: Validators.notEmpty, keyboardType: TextInputType.number, icon: Icons.badge, isRequired: true),
        LabeledTextField(label: 'Адрес организации/ИП', controller: _addr, validator: Validators.notEmpty, icon: Icons.location_on, isRequired: true),
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
}
