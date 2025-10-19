import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/colors.dart';
import '../../../../../core/theme/text_styles.dart';
import '../../../../../shared/widgets/inputs/labeled_text_field.dart';
import '../../../../../shared/widgets/buttons/custom_button.dart';
import '../../../../../shared/widgets/chips/radio_group_wrap.dart';
import '../../../../../shared/widgets/chips/radio_group_horizontal.dart';
import '../../../../../shared/widgets/layout/common_ui.dart';
import '../../../../../core/utils/validators.dart';
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

  final _educationName = TextEditingController();
  final _extraEducation = TextEditingController();

  final _workYears = TextEditingController();
  final _bowlingYears = TextEditingController();
  final _currentClub = TextEditingController();
  final _bowlingHistory = TextEditingController();
  final _skills = TextEditingController();

  /// здесь храним именно **id** в виде строки, например "1"
  String? educationLevelId;
  String? status;

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
  void dispose() {
    [
      _fio, _birth, _phone,
      _educationName, _extraEducation,
      _workYears, _bowlingYears,
      _currentClub, _bowlingHistory, _skills
    ].forEach((c) => c.dispose());
    super.dispose();
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
    if (!(formKey.currentState?.validate() ?? false)) return;
    if (step == 1 && (educationLevelId == null || educationLevelId!.isEmpty)) {
      _showBar('Выберите уровень образования');
      return;
    }
    if (step == 2 && (status == null || status!.isEmpty)) {
      _showBar('Выберите статус');
      return;
    }
    nextStep();
  }

  Future<void> _submit() async {
    if (!formKey.currentState!.validate() || educationLevelId == null || status == null) {
      if (educationLevelId == null) _showBar('Выберите уровень образования');
      if (status == null) _showBar('Выберите статус');
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

    if (places.isEmpty && _currentClub.text.trim().isNotEmpty) {
      places.add(_currentClub.text.trim());
    }

    final trimmedStatus = status?.trim();

    final data = {
      'fio': _fio.text.trim(),
      'birth': DateFormat('yyyy-MM-dd').format(birthDate!),
      'phone': _phone.text.trim(),
      'password': 'password123',
      'educationLevelId': educationLevelId!, // уже "1".."5"
      'educationName': _educationName.text.trim(),
      'specializationId': '1',
      'advantages': _extraEducation.text.trim(),
      'workYears': _workYears.text.trim(),
      'bowlingYears': _bowlingYears.text.trim(),
      'currentClub': _currentClub.text.trim(),
      'bowlingHistory': _bowlingHistory.text.trim(),
      'skills': _skills.text.trim(),
      'status': trimmedStatus ?? status,
      'workPlaces': places.join(', '),
      'workPeriods': periods.join(', '),
    };

    final success = await AuthService.registerMechanic(data);
    if (!success) {
      _showBar('Ошибка при отправке данных');
      return;
    }

    final trimmedPhone = _phone.text.trim();
    final trimmedClub = _currentClub.text.trim();

    String resolvedClubName = trimmedClub;
    String? resolvedClubAddress;

    if (trimmedClub.contains('\n')) {
      final parts = trimmedClub
          .split(RegExp(r'[\r\n]+'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (parts.isNotEmpty) {
        resolvedClubName = parts.first;
        if (parts.length > 1) {
          resolvedClubAddress = parts.sublist(1).join(', ');
        }
      }
    }

    if (resolvedClubAddress == null && trimmedClub.contains(',')) {
      final index = trimmedClub.indexOf(',');
      final first = trimmedClub.substring(0, index).trim();
      final rest = trimmedClub.substring(index + 1).trim();
      if (first.isNotEmpty) {
        resolvedClubName = first;
      }
      if (rest.isNotEmpty) {
        resolvedClubAddress = rest;
      }
    }

    if (resolvedClubAddress == null) {
      final dashMatch = RegExp(r'\s[—–-]\s').firstMatch(trimmedClub);
      if (dashMatch != null) {
        final index = dashMatch.start;
        final first = trimmedClub.substring(0, index).trim();
        final rest = trimmedClub.substring(dashMatch.end).trim();
        if (first.isNotEmpty) {
          resolvedClubName = first;
        }
        if (rest.isNotEmpty) {
          resolvedClubAddress = rest;
        }
      }
    }

    final displayClubName = resolvedClubName.trim().isNotEmpty
        ? resolvedClubName.trim()
        : trimmedClub;
    final displayAddress = () {
      final addr = resolvedClubAddress?.trim();
      if (addr != null && addr.isNotEmpty) {
        return addr;
      }
      // если адрес распознать не удалось, сохраняем исходное значение,
      // чтобы в профиле не показывался дефолтный адрес-заглушка
      return trimmedClub;
    }();

    final clubsCache = <String>[];
    void addClub(String? value) {
      final trimmed = value?.trim();
      if (trimmed == null || trimmed.isEmpty) return;
      if (!clubsCache.contains(trimmed)) {
        clubsCache.add(trimmed);
      }
    }

    for (final place in places) {
      addClub(place);
    }
    addClub(trimmedClub);
    addClub(displayClubName);

    if (displayClubName.isNotEmpty) {
      clubsCache.remove(displayClubName);
      clubsCache.insert(0, displayClubName);
    }

    final profileData = {
      'fullName': _fio.text.trim(),
      'phone': trimmedPhone,
      'clubName': displayClubName,
      'address': displayAddress,
      'status': trimmedStatus ?? 'Самозанятый',
      'birthDate': birthDate?.toIso8601String(),
      'clubs': clubsCache,
      'workplaceVerified': false,
    };
    await LocalAuthStorage.saveMechanicProfile(profileData);
    await LocalAuthStorage.setMechanicRegistered(true);

    final password = data['password']?.toString() ?? 'password123';
    final loginResult = await AuthService.login(phone: trimmedPhone, password: password);
    if (loginResult == null) {
      _showBar('Не удалось войти с новыми данными, попробуйте позже');
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(Routes.profileMechanic, (route) => false);
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
        IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.arrow_back, color: AppColors.primary)),
        formStepTitle('Добро пожаловать!'),
        formDescription('Пожалуйста, заполните форму — это нужно, чтобы мы знали, где вы работаете и могли подключить Вас к системе.'),
        LabeledTextField(label: 'ФИО', controller: _fio, validator: Validators.notEmpty, icon: Icons.person),
        LabeledTextField(label: 'Дата рождения', controller: _birth, validator: Validators.birth(birthDate), readOnly: true, onTap: _pickBirthDate, icon: Icons.calendar_today),
        LabeledTextField(label: 'Номер телефона', controller: _phone, validator: Validators.phone, keyboardType: TextInputType.phone, icon: Icons.phone),
      ],
    );
  }

  Widget _buildStepTwo(BuildContext ctx) {
    final eduOptions = _eduMap.keys.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(onPressed: prevStep, icon: const Icon(Icons.arrow_back, color: AppColors.primary)),
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
        ),
        LabeledTextField(
          label: 'Дополнительное образование (курсы и т.д.)',
          controller: _extraEducation,
          validator: Validators.notEmpty,
        ),
      ],
    );
  }

  Widget _buildStepThree(BuildContext ctx) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(onPressed: prevStep, icon: const Icon(Icons.arrow_back, color: AppColors.primary)),
        sectionTitle('Стаж работы'),
        const SizedBox(height: 8),
        LabeledTextField(label: 'Общий стаж работы', controller: _workYears, validator: Validators.integer, keyboardType: TextInputType.number),
        LabeledTextField(
          label: 'Стаж в боулинге',
          controller: _bowlingYears,
          validator: (v) {
            final basic = Validators.integer(v);
            if (basic != null) return basic;
            return Validators.validateExperience(_workYears.text, v);
          },
          keyboardType: TextInputType.number,
        ),
        LabeledTextField(label: 'Текущее место работы', controller: _currentClub, validator: Validators.notEmpty),
        LabeledTextField(label: 'Где и когда работали в боулинге', controller: _bowlingHistory, validator: Validators.bowlingHistorySoft),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            '${Validators.bowlingHistoryHelper}\nНапример: ${Validators.bowlingHistoryHintExample}',
            style: AppTextStyles.formHint,
          ),
        ),
        LabeledTextField(label: 'Навыки и преимущества', controller: _skills, validator: Validators.notEmpty),
        const SizedBox(height: 16),
        formDescription('Ваш статус:'),
        RadioGroupHorizontal(
          options: const ['ИП', 'Самозанятый'],
          groupValue: status,
          onChanged: (v) => setState(() => status = v),
        ),
      ],
    );
  }
}
