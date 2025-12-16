import 'package:flutter/material.dart';

import '../../../../../api/api_core.dart' show ApiException;
import '../../../../../core/repositories/clubs_repository.dart';
import '../../../../../core/routing/routes.dart';
import '../../../../../core/services/auth_service.dart';
import '../../../../../core/theme/colors.dart';
import '../../../../../core/utils/phone_utils.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../../models/club_summary_dto.dart';
import '../../../../../shared/widgets/buttons/custom_button.dart';
import '../../../../../shared/widgets/inputs/labeled_text_field.dart';
import '../../../../../shared/widgets/layout/common_ui.dart';

class RegisterManagerScreen extends StatefulWidget {
  const RegisterManagerScreen({super.key});

  @override
  State<RegisterManagerScreen> createState() => _RegisterManagerScreenState();
}

class _RegisterManagerScreenState extends State<RegisterManagerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fio = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirm = TextEditingController();

  bool _isSubmitting = false;
  late final ClubsRepository _clubsRepository = ClubsRepository();
  List<ClubSummaryDto> _clubs = const <ClubSummaryDto>[];
  bool _isLoadingClubs = true;
  String? _clubsError;
  ClubSummaryDto? _selectedClub;

  @override
  void initState() {
    super.initState();
    if (_phone.text.isEmpty) {
      _phone.text = '+7 ';
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadClubs());
  }

  @override
  void dispose() {
    _fio.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    _passwordConfirm.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.primary),
    );
  }

  Future<void> _loadClubs() async {
    setState(() {
      _isLoadingClubs = true;
      _clubsError = null;
    });
    try {
      final clubs = await _clubsRepository.getClubs();
      if (!mounted) return;
      setState(() {
        _clubs = clubs;
        _isLoadingClubs = false;
        if (_selectedClub != null && !_clubs.any((club) => club.id == _selectedClub!.id)) {
          _selectedClub = null;
        }
        if (_selectedClub == null && _clubs.length == 1) {
          _selectedClub = _clubs.first;
        }
        if (clubs.isEmpty) {
          _clubsError = 'Список клубов пуст. Обратитесь к администратору.';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingClubs = false;
        _clubsError = 'Не удалось загрузить список клубов';
      });
    }
  }

  void _handleClubChange(int? clubId) {
    ClubSummaryDto? selected;
    if (clubId != null) {
      try {
        selected = _clubs.firstWhere((club) => club.id == clubId);
      } catch (_) {
        selected = null;
      }
    }
    setState(() => _selectedClub = selected);
    _formKey.currentState?.validate();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) {
      _showMessage('Заполните обязательные поля');
      return;
    }

    final password = _password.text.trim();
    final confirm = _passwordConfirm.text.trim();

    final passwordError = Validators.password(password);
    final confirmError = confirm.isEmpty
        ? 'Повторите пароль'
        : (password != confirm ? 'Пароли не совпадают' : null);

    if (passwordError != null) {
      _showMessage(passwordError);
      return;
    }
    if (confirmError != null) {
      _showMessage(confirmError);
      return;
    }

    final normalizedPhone = PhoneUtils.normalize(_phone.text);
    final email = _email.text.trim();
    final selectedClub = _selectedClub;

    if (selectedClub == null) {
      _showMessage('Выберите клуб, в котором вы работаете');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final success = await AuthService.registerHeadMechanic({
        'fio': _fio.text.trim(),
        'phone': normalizedPhone,
        'email': email.isEmpty ? null : email,
        'password': password,
        'clubId': selectedClub.id,
        'clubName': selectedClub.name,
        'clubAddress': selectedClub.address,
      });

      if (!success) {
        throw ApiException('Не удалось зарегистрироваться. Попробуйте позже.');
      }

      if (!mounted) return;
      Navigator.of(context)
          .pushNamedAndRemoveUntil(Routes.profileManager, (route) => false);
    } on ApiException catch (e) {
      _showMessage(e.message);
    } catch (_) {
      _showMessage('Ошибка при регистрации. Попробуйте позже.');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String? _optionalEmailValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return Validators.email(value);
  }

  @override
  Widget build(BuildContext context) {
    final selectedClub = _selectedClub;
    final selectedClubAddress = selectedClub?.address?.trim();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                      label: const Text('Шаг назад', style: TextStyle(color: AppColors.primary)),
                      style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                    ),
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(Routes.welcome, (route) => false),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary),
                      label: const Text('Назад к входу', style: TextStyle(color: AppColors.primary)),
                      style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                sectionTitle('Регистрация менеджера'),
                const SizedBox(height: 16),
                LabeledTextField(
                  label: 'ФИО *',
                  controller: _fio,
                  validator: Validators.notEmpty,
                  isRequired: true,
                ),
                LabeledTextField(
                  label: 'Телефон *',
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  validator: Validators.phone,
                  isRequired: true,
                ),
                LabeledTextField(
                  label: 'Email',
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  validator: _optionalEmailValidator,
                ),
                LabeledTextField(
                  label: 'Пароль *',
                  controller: _password,
                  obscureText: true,
                  validator: Validators.password,
                  isRequired: true,
                ),
                LabeledTextField(
                  label: 'Повторите пароль *',
                  controller: _passwordConfirm,
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Повторите пароль';
                    }
                    if (value.trim() != _password.text.trim()) {
                      return 'Пароли не совпадают';
                    }
                    return null;
                  },
                  isRequired: true,
                ),
                const SizedBox(height: 16),
                sectionTitle('Рабочее место'),
                formDescription(
                    'Выберите клуб, в котором вы работаете. Без выбора регистрация невозможна.'),
                const SizedBox(height: 8),
                if (_isLoadingClubs)
                  const Center(child: CircularProgressIndicator())
                else if (_clubsError != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _clubsError!,
                        style: const TextStyle(color: Colors.red),
                      ),
                      TextButton(onPressed: _loadClubs, child: const Text('Повторить попытку')),
                    ],
                  )
                else
                  DropdownButtonFormField<int>(
                    value: selectedClub?.id,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (value) => value == null ? 'Выберите клуб' : null,
                    items: _clubs
                        .map(
                          (club) {
                            final address = club.address?.trim();
                            final hasAddress = address != null && address.isNotEmpty;
                            final title = hasAddress ? '${club.name} — $address' : club.name;
                            return DropdownMenuItem<int>(
                              value: club.id,
                              child: Text(title),
                            );
                          },
                        )
                        .toList(),
                    onChanged: _handleClubChange,
                    decoration: const InputDecoration(labelText: 'Клуб *'),
                  ),
                if (selectedClub != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Вы выбрали: ${selectedClub.name}',
                    style: const TextStyle(color: Colors.black87),
                  ),
                  if (selectedClubAddress != null && selectedClubAddress.isNotEmpty)
                    Text(
                      selectedClubAddress,
                      style: const TextStyle(color: Colors.black54),
                    ),
                ],
                const SizedBox(height: 24),
                CustomButton(
                  text: _isSubmitting ? 'Отправка...' : 'Зарегистрироваться',
                  onPressed: _isSubmitting ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
