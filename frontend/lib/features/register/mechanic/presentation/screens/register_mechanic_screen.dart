import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../api/api_core.dart';
import '../../../../../core/repositories/clubs_repository.dart';
import '../../../../../core/theme/colors.dart';
import '../../../../../core/theme/text_styles.dart';
import '../../../../../models/club_summary_dto.dart';
import '../../../../../shared/widgets/inputs/labeled_text_field.dart';
import '../../../../../shared/widgets/buttons/custom_button.dart';
import '../../../../../shared/widgets/chips/radio_group_wrap.dart';
import '../../../../../shared/widgets/chips/radio_group_horizontal.dart';
import '../../../../../shared/widgets/layout/common_ui.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../../core/utils/phone_utils.dart';
import '../../../../../core/services/auth_service.dart';
import '../../../../../core/services/local_auth_storage.dart';
import '../../../../../core/routing/routes.dart';

class RegisterMechanicScreen extends StatefulWidget {
  const RegisterMechanicScreen({Key? key}) : super(key: key);

  @override
  State<RegisterMechanicScreen> createState() => _RegisterMechanicScreenState();
}

class _RegisterMechanicScreenState extends State<RegisterMechanicScreen> {
  final _formKey = GlobalKey<FormState>();
  int _step = 0;
  
  final _fio = TextEditingController();
  final _birth = TextEditingController();
  final _phone = TextEditingController();
  DateTime? birthDate;

  final _password = TextEditingController();
  final _passwordConfirm = TextEditingController();

  final _educationName = TextEditingController();
  final _extraEducation = TextEditingController();

  final _workYears = TextEditingController();
  final _bowlingYears = TextEditingController();
  final _bowlingHistory = TextEditingController();
  final _skills = TextEditingController();
  final _region = TextEditingController();

  /// здесь храним именно **id** в виде строки, например "1"
  String? educationLevelId;
  String? _status;
  bool? _isEntrepreneur;
  bool _isSubmitting = false;

  late final ClubsRepository _clubsRepository = ClubsRepository();
  List<ClubSummaryDto> _clubs = const <ClubSummaryDto>[];
  bool _isLoadingClubs = true;
  String? _clubsError;
  ClubSummaryDto? _selectedClub;

  /// маппинг названия уровня образования в id
  static const _eduMap = <String, String>{
    'высшее': '1',
    'высшее-профессиональное': '2',
    'среднее': '3',
    'средне-профессиональное': '4',
    'другое': '5',
  };

  GlobalKey<FormState> get formKey => _formKey;
  int get step => _step;

  void nextStep() {
    if (_step < 2) {
      setState(() => _step++);
    }
  }

  void prevStep() {
    if (_step > 0) {
      setState(() => _step--);
    }
  }

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
    final controllers = [
      _fio,
      _birth,
      _phone,
      _password,
      _passwordConfirm,
      _educationName,
      _extraEducation,
      _workYears,
      _bowlingYears,
      _bowlingHistory,
      _skills,
      _region,
    ];
    for (final controller in controllers) {
      controller.dispose();
    }
    super.dispose();
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
    if (clubId == null) {
      setState(() => _selectedClub = null);
      return;
    }
    ClubSummaryDto? selected;
    try {
      selected = _clubs.firstWhere((club) => club.id == clubId);
    } catch (_) {
      selected = null;
    }
    setState(() => _selectedClub = selected);
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: birthDate ?? DateTime(now.year - 18),
      firstDate: DateTime(1900),
      lastDate: now,
      locale: const Locale('ru'),
    );
    if (picked != null) {
      setState(() {
        birthDate = picked;
        _birth.text = DateFormat('dd.MM.yyyy').format(picked);
      });
    }
  }

  void _showBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.primary),
    );
  }

  void _nextStepGuarded() {
    if (!(formKey.currentState?.validate() ?? false)) {
      _showBar('Заполните обязательные поля');
      return;
    }
    if (step == 1 && (educationLevelId == null || educationLevelId!.isEmpty)) {
      _showBar('Выберите уровень образования');
      return;
    }
    nextStep();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    if (!formKey.currentState!.validate() || educationLevelId == null) {
      if (educationLevelId == null) _showBar('Выберите уровень образования');
      if (educationLevelId != null) {
        _showBar('Заполните обязательные поля');
      }
      return;
    }

    if (birthDate == null) {
      _showBar('Выберите дату рождения');
      return;
    }

    final passwordValue = _password.text.trim();
    final confirmPasswordValue = _passwordConfirm.text.trim();

    final passwordError = Validators.password(passwordValue);
    final confirmError = confirmPasswordValue.isEmpty
        ? 'Повторите пароль'
        : (passwordValue != confirmPasswordValue ? 'Пароли не совпадают' : null);

    if (passwordError != null) {
      _showBar(passwordError);
      return;
    }
    if (confirmError != null) {
      _showBar(confirmError);
      return;
    }

    final entries = Validators.parseEmploymentHistory(_bowlingHistory.text.trim());
    final places = <String>[];
    final periods = <String>[];

    for (final e in entries) {
      final place = e.place.trim();
      if (place.isEmpty) continue;
      places.add(place);
      final y1 = e.from?.year;
      final y2 = e.to?.year;
      if (y1 != null && y2 != null) {
        periods.add('$y1-$y2');
      } else if (y1 != null && y2 == null) {
        periods.add('$y1-');
      }
    }

    final selectedClub = _selectedClub;
    final selectedClubName = selectedClub?.name;
    final hasSelectedClub = selectedClubName != null && selectedClubName.isNotEmpty;

    if (selectedClubName != null && !places.contains(selectedClubName)) {
      places.insert(0, selectedClubName);
    }

    final profileClubs = <String>[];
    if (selectedClubName != null && selectedClubName.isNotEmpty) {
      profileClubs.add(selectedClubName);
    }
    for (final place in places) {
      if (!profileClubs.contains(place)) {
        profileClubs.add(place);
      }
    }

    final trimmedStatus = _status?.trim();
    final normalizedPhone = PhoneUtils.normalize(_phone.text);
    final extraEducation = _extraEducation.text.trim();
    final skills = _skills.text.trim();
    final workPlaces = places.join(', ');
    final workPeriods = periods.join(', ');
    final region = _region.text.trim();
    if (region.isEmpty) {
      _showBar('Укажите регион работы');
      return;
    }

    final selfEmployment = _isEntrepreneur ?? (() {
      final normalized = (_status ?? '').toLowerCase();
      if (normalized.contains('ип')) return true;
      if (normalized.contains('самозан')) return false;
      return null;
    })();
    if (selfEmployment == null) {
      _showBar('Выберите статус: ИП или самозанятый');
      return;
    }

    final data = {
      'fio': _fio.text.trim(),
      'birth': DateFormat('yyyy-MM-dd').format(birthDate!),
      'phone': normalizedPhone,
      'password': passwordValue,
      'educationLevelId': educationLevelId!,
      'educationName': _educationName.text.trim(),
      'specializationId': '1',
      'advantages': extraEducation.isEmpty ? null : extraEducation,
      'workYears': _workYears.text.trim(),
      'bowlingYears': _bowlingYears.text.trim(),
      'bowlingHistory': _bowlingHistory.text.trim(),
      'skills': skills.isEmpty ? null : skills,
      'status': trimmedStatus ?? _status,
      'workPlaces': workPlaces.isEmpty ? null : workPlaces,
      'workPeriods': workPeriods.isEmpty ? null : workPeriods,
      'clubId': selectedClub?.id,
      'region': region,
      'isEntrepreneur': selfEmployment,
    };

    setState(() => _isSubmitting = true);

    try {
      await AuthService.registerMechanic(data);
    } on ApiException catch (e) {
      _showBar(e.message);
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
      return;
    } catch (_) {
      _showBar('Ошибка при отправке данных');
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
      return;
    }

    final normalizedStatus = () {
      final trimmed = trimmedStatus?.trim();
      if (trimmed != null && trimmed.isNotEmpty) {
        return trimmed;
      }
      if (_status != null && _status!.trim().isNotEmpty) {
        return _status!.trim();
      }
      return 'Не указан';
    }();

    final profileData = {
      'fullName': _fio.text.trim(),
      'phone': normalizedPhone,
      'clubName': selectedClubName ?? (profileClubs.isNotEmpty ? profileClubs.first : ''),
      'address': selectedClub?.address ?? '',
      'status': normalizedStatus,
      'birthDate': birthDate?.toIso8601String(),
      'clubs': profileClubs,
      'workplaceVerified': false,
      'clubId': selectedClub?.id,
      'clubAddress': selectedClub?.address,
      'freeAgent': !hasSelectedClub,
    };
    final awaitingAdmin = !hasSelectedClub;
    if (awaitingAdmin) {
      _showBar('Заявка отправлена. Дождитесь проверки администрацией сервиса.');
    }

    Future<void> persistProfile() async {
      await LocalAuthStorage.saveMechanicProfile(profileData);
      await LocalAuthStorage.setMechanicRegistered(true);
      await LocalAuthStorage.clearOwnerState();
      await LocalAuthStorage.clearManagerState();
      await LocalAuthStorage.setRegisteredRole('mechanic');
      if (awaitingAdmin) {
        await LocalAuthStorage.setRegisteredAccountType('FREE_MECHANIC_BASIC');
      }
    }

    try {
      final loginResult = await AuthService.login(phone: normalizedPhone, password: passwordValue);
      if (loginResult == null) {
        throw ApiException('Не удалось войти с новыми данными, попробуйте позже');
      }

      await persistProfile();

      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(Routes.profileMechanic, (route) => false);
    } on ApiException catch (e) {
      if (e.statusCode == 403) {
        if (mounted) {
          final approvalMessage = hasSelectedClub
              ? 'Данные отправлены владельцу клуба. Дождитесь подтверждения аккаунта.'
              : 'Данные отправлены администрацией приложения. Дождитесь подтверждения аккаунта.';
          _showBar(approvalMessage);
          await persistProfile();
          Navigator.of(context).pushNamedAndRemoveUntil(Routes.profileMechanic, (route) => false);
        }
      } else {
        _showBar(e.message);
      }
    } catch (e) {
      _showBar('Не удалось войти с новыми данными, попробуйте позже');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext ctx) {
    final steps = [
      _buildStepOne(ctx),
      _buildStepTwo(ctx),
      _buildStepThree(ctx),
    ];
    final isLast = step == steps.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 12, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
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
                  child: steps[step],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: isLast
                  ? CustomButton(
                      text: _isSubmitting ? 'Отправка…' : 'Зарегистрироваться',
                      onPressed: _isSubmitting ? null : _submit,
                    )
                  : CustomButton(text: 'Далее', onPressed: _nextStepGuarded),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepOne(BuildContext ctx) {
    return Column(
      key: const ValueKey('register_mechanic_step_1'),
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
        formDescription('Пожалуйста, заполните форму — это нужно, чтобы мы знали, где вы работаете и могли подключить Вас к системе.'),
        LabeledTextField(label: 'ФИО', controller: _fio, validator: Validators.notEmpty, icon: Icons.person, isRequired: true),
        LabeledTextField(label: 'Дата рождения', controller: _birth, validator: Validators.birth(birthDate), readOnly: true, onTap: _pickBirthDate, icon: Icons.calendar_today, isRequired: true),
        LabeledTextField(label: 'Номер телефона', controller: _phone, validator: Validators.phone, keyboardType: TextInputType.phone, icon: Icons.phone, isRequired: true),
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
      ],
    );
  }

  Widget _buildStepTwo(BuildContext ctx) {
    final eduOptions = _eduMap.keys.toList();
    return Column(
      key: const ValueKey('register_mechanic_step_2'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: prevStep,
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          label: const Text('Шаг назад', style: TextStyle(color: AppColors.primary)),
          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
        ),
        sectionTitle('Какое у Вас образование?'),
        const SizedBox(height: 16),
        // показываем пользователю текст, а сохраняем id
        RadioGroupWrap(
          options: eduOptions,
          groupValue: educationLevelId == null
              ? null
              : eduOptions.firstWhere(
                (title) => _eduMap[title] == educationLevelId,
            orElse: () => eduOptions.first,
          ),
          onChanged: (selectedTitle) {
            final id = _eduMap[selectedTitle ?? ''];
            setState(() => educationLevelId = id);
          },
        ),
        const SizedBox(height: 16),
        LabeledTextField(
          label: 'Наименование образовательного учреждения',
          controller: _educationName,
          validator: Validators.notEmpty,
          isRequired: true,
        ),
        LabeledTextField(
          label: 'Дополнительное образование (курсы и т.д.)',
          controller: _extraEducation,
        ),
      ],
    );
  }

  Widget _buildStepThree(BuildContext ctx) {
    final selectedClub = _selectedClub;
    final selectedClubAddress = selectedClub?.address?.trim();
    return Column(
      key: const ValueKey('register_mechanic_step_3'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: prevStep,
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          label: const Text('Шаг назад', style: TextStyle(color: AppColors.primary)),
          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
        ),
        sectionTitle('Стаж работы'),
        const SizedBox(height: 8),
        LabeledTextField(label: 'Общий стаж работы', controller: _workYears, validator: Validators.integer, keyboardType: TextInputType.number, isRequired: true),
        LabeledTextField(
          label: 'Стаж в боулинге',
          controller: _bowlingYears,
          validator: (v) {
            final basic = Validators.integer(v);
            if (basic != null) return basic;
            return Validators.validateExperience(_workYears.text, v);
          },
          keyboardType: TextInputType.number,
          isRequired: true,
        ),
        const SizedBox(height: 16),
        formDescription(
            'Если вы уже работаете в клубе, выберите его из списка. Без выбора вы зарегистрируетесь как свободный агент.'),
        const SizedBox(height: 8),
        if (_isLoadingClubs)
          const Center(child: CircularProgressIndicator())
        else if (_clubsError != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _clubsError!,
                style: AppTextStyles.formHint.copyWith(color: Colors.red),
              ),
              TextButton(onPressed: _loadClubs, child: const Text('Повторить попытку')),
            ],
          )
        else
          DropdownButtonFormField<int>(
            value: selectedClub?.id,
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
            decoration:
                const InputDecoration(labelText: 'Клуб (по желанию)'),
            autovalidateMode: AutovalidateMode.onUserInteraction,
          ),
        if (selectedClub == null) ...[
          const SizedBox(height: 8),
          Text(
            'В случае выбора клуба вы получите доступ к сервису после подтверждения вашей заявки владельцем(менеджером) клуба. \n'
            'В случае, если клуб не выбран Вашу заявку на подключение должен подтвердить администратор сервиса, ждите обратного звонка.',
            style: AppTextStyles.formHint,
          ),
        ],
        if (selectedClub != null) ...[
          const SizedBox(height: 8),
          Text(
            selectedClubAddress != null && selectedClubAddress.isNotEmpty
                ? 'Адрес: $selectedClubAddress'
                : 'Адрес не указан',
            style: AppTextStyles.formHint,
          ),
        ],
        const SizedBox(height: 16),
        LabeledTextField(
          label: 'Где и когда работали в боулинге',
          controller: _bowlingHistory,
          validator: Validators.bowlingHistorySoft,
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            '${Validators.bowlingHistoryHelper}\nНапример: ${Validators.bowlingHistoryHintExample}',
            style: AppTextStyles.formHint,
          ),
        ),
        LabeledTextField(label: 'Регион (город/область)', controller: _region, validator: Validators.notEmpty, isRequired: true),
        LabeledTextField(label: 'Навыки и преимущества', controller: _skills),
        const SizedBox(height: 16),
        formDescription('Ваш статус (при наличии):'),
        RadioGroupHorizontal(
          options: const ['ИП', 'Самозанятый'],
          groupValue: _status,
          onChanged: (v) => setState(() {
            if (_status == v) {
              _status = null;
              _isEntrepreneur = null;
            } else {
              _status = v;
              _isEntrepreneur = v == 'ИП';
            }
          }),
        ),
      ],
    );
  }
}
