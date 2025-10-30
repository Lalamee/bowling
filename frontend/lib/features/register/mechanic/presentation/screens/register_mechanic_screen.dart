import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../api/api_core.dart';
import '../../../../../core/theme/colors.dart';
import '../../../../../core/theme/text_styles.dart';
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
import '../../../../../core/repositories/clubs_repository.dart';
import '../../../../../models/club_summary_dto.dart';

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

  /// здесь храним именно **id** в виде строки, например "1"
  String? educationLevelId;
  String? status;

  final _clubsRepository = ClubsRepository();
  List<ClubSummaryDto> _clubs = [];
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
    _loadClubs();
  }

  @override
  void dispose() {
    [
      _fio, _birth, _phone,
      _password, _passwordConfirm,
      _educationName, _extraEducation,
      _workYears, _bowlingYears,
      _bowlingHistory, _skills
    ].forEach((c) => c.dispose());
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
    for (final club in _clubs) {
      if (club.id == clubId) {
        selected = club;
        break;
      }
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
    if (!formKey.currentState!.validate() || educationLevelId == null) {
      if (educationLevelId == null) _showBar('Выберите уровень образования');
      if (educationLevelId != null) {
        _showBar('Заполните обязательные поля');
      }
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
    if (selectedClub == null) {
      _showBar('Выберите клуб из списка');
      return;
    }

    if (!places.contains(selectedClub.name)) {
      places.insert(0, selectedClub.name);
    }

    final trimmedStatus = status?.trim();
    final normalizedPhone = PhoneUtils.normalize(_phone.text);
    final extraEducation = _extraEducation.text.trim();
    final skills = _skills.text.trim();
    final workPlaces = places.join(', ');
    final workPeriods = periods.join(', ');

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
      'currentClub': selectedClub.name,
      'bowlingHistory': _bowlingHistory.text.trim(),
      'skills': skills.isEmpty ? null : skills,
      'status': trimmedStatus ?? status,
      'workPlaces': workPlaces.isEmpty ? null : workPlaces,
      'workPeriods': workPeriods.isEmpty ? null : workPeriods,
      'clubId': selectedClub.id,
      'clubName': selectedClub.name,
      'clubAddress': selectedClub.address,
    };

    final success = await AuthService.registerMechanic(data);
    if (!success) {
      _showBar('Ошибка при отправке данных');
      return;
    }

    final clubsCache = List<String>.from(places);
    if (!clubsCache.contains(selectedClub.name)) {
      clubsCache.insert(0, selectedClub.name);
    }

    final normalizedStatus = () {
      final trimmed = trimmedStatus?.trim();
      if (trimmed != null && trimmed.isNotEmpty) {
        return trimmed;
      }
      if (status != null && status!.trim().isNotEmpty) {
        return status!.trim();
      }
      return 'Не указан';
    }();

    final profileData = {
      'fullName': _fio.text.trim(),
      'phone': normalizedPhone,
      'clubName': selectedClub.name,
      'address': selectedClub.address ?? '',
      'status': normalizedStatus,
      'birthDate': birthDate?.toIso8601String(),
      'clubs': clubsCache,
      'workplaceVerified': false,
    };
    try {
      final loginResult = await AuthService.login(phone: normalizedPhone, password: passwordValue);
      if (loginResult == null) {
        throw ApiException('Не удалось войти с новыми данными, попробуйте позже');
      }

      await LocalAuthStorage.saveMechanicProfile(profileData);
      await LocalAuthStorage.setMechanicRegistered(true);
      await LocalAuthStorage.clearOwnerState();
      await LocalAuthStorage.clearManagerState();
      await LocalAuthStorage.setRegisteredRole('mechanic');

      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(Routes.profileMechanic, (route) => false);
    } on ApiException catch (e) {
      if (e.statusCode == 403) {
        if (mounted) {
          _showBar('Данные отправлены владельцу клуба. Дождитесь подтверждения аккаунта.');
          Navigator.of(context).pushNamedAndRemoveUntil(Routes.authLogin, (route) => false);
        }
      } else {
        _showBar(e.message);
      }
    } catch (e) {
      _showBar('Не удалось войти с новыми данными, попробуйте позже');
    }
  }

  @override
  Widget build(BuildContext ctx) {
    final steps = [_buildStepOne(ctx), _buildStepTwo(ctx), _buildStepThree(ctx)];
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
    return Column(
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
        formDescription('Выберите клуб, в котором вы работаете:'),
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
            value: _selectedClub?.id,
            items: _clubs
                .map(
                  (club) => DropdownMenuItem<int>(
                    value: club.id,
                    child: Text(
                      club.address != null && club.address!.trim().isNotEmpty
                          ? '${club.name} — ${club.address}'
                          : club.name,
                    ),
                  ),
                )
                .toList(),
            onChanged: _handleClubChange,
            decoration: const InputDecoration(labelText: 'Клуб *'),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (value) {
              if (value == null) {
                return 'Выберите клуб';
              }
              return null;
            },
          ),
        if (_selectedClub != null) ...[
          const SizedBox(height: 8),
          Text(
            _selectedClub!.address != null && _selectedClub!.address!.trim().isNotEmpty
                ? 'Адрес: ${_selectedClub!.address}'
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
        LabeledTextField(label: 'Навыки и преимущества', controller: _skills),
        const SizedBox(height: 16),
        formDescription('Ваш статус (при наличии):'),
        RadioGroupHorizontal(
          options: const ['ИП', 'Самозанятый'],
          groupValue: status,
          onChanged: (v) => setState(() {
            if (status == v) {
              status = null;
            } else {
              status = v;
            }
          }),
        ),
      ],
    );
  }
}
