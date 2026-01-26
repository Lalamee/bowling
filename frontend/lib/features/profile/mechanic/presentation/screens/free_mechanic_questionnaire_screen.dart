import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/repositories/clubs_repository.dart';
import '../../../../../core/theme/colors.dart';
import '../../../../../core/theme/text_styles.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../../models/club_summary_dto.dart';
import '../../../../../shared/widgets/layout/common_ui.dart';
import '../../../../../shared/widgets/buttons/custom_button.dart';
import '../../../../../shared/widgets/chips/radio_group_horizontal.dart';
import '../../../../../shared/widgets/chips/radio_group_wrap.dart';
import '../../../../../shared/widgets/inputs/labeled_text_field.dart';
import '../../domain/mechanic_profile.dart';

class FreeMechanicQuestionnaireScreen extends StatefulWidget {
  final MechanicProfile initial;
  final String? initialRegion;
  final Map<String, dynamic>? initialApplication;

  const FreeMechanicQuestionnaireScreen({
    Key? key,
    required this.initial,
    this.initialRegion,
    this.initialApplication,
  }) : super(key: key);

  @override
  State<FreeMechanicQuestionnaireScreen> createState() => _FreeMechanicQuestionnaireScreenState();
}

class _FreeMechanicQuestionnaireScreenState extends State<FreeMechanicQuestionnaireScreen> {
  static const _eduMap = <String, String>{
    'высшее': '1',
    'высшее-профессиональное': '2',
    'среднее': '3',
    'средне-профессиональное': '4',
    'другое': '5',
  };

  final _formKey = GlobalKey<FormState>();
  final _fio = TextEditingController();
  final _birth = TextEditingController();
  final _phone = TextEditingController();
  final _educationName = TextEditingController();
  final _extraEducation = TextEditingController();
  final _workYears = TextEditingController();
  final _bowlingYears = TextEditingController();
  final _bowlingHistory = TextEditingController();
  final _skills = TextEditingController();
  final _region = TextEditingController();

  DateTime? _birthDate;
  String? _educationLevelId;
  String? _status;
  bool? _isEntrepreneur;
  bool _isSubmitting = false;

  late final ClubsRepository _clubsRepository = ClubsRepository();
  List<ClubSummaryDto> _clubs = const <ClubSummaryDto>[];
  bool _isLoadingClubs = true;
  String? _clubsError;
  ClubSummaryDto? _selectedClub;

  static ClubSummaryDto _freeAgentOption() =>
      ClubSummaryDto(id: 0, name: 'Свободный агент (без клуба)');

  @override
  void initState() {
    super.initState();
    _prefill();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadClubs());
  }

  void _prefill() {
    final initial = widget.initial;
    _fio.text = initial.fullName;
    _phone.text = initial.phone;
    _birthDate = initial.birthDate;
    if (_birthDate != null) {
      _birth.text = DateFormat('dd.MM.yyyy').format(_birthDate!);
    }
    if (widget.initialRegion != null && widget.initialRegion!.trim().isNotEmpty) {
      _region.text = widget.initialRegion!.trim();
    }
    final app = widget.initialApplication;
    if (app != null) {
      _educationLevelId = app['educationLevelId']?.toString();
      _educationName.text = app['educationName']?.toString() ?? '';
      _extraEducation.text = app['advantages']?.toString() ?? '';
      _workYears.text = app['workYears']?.toString() ?? '';
      _bowlingYears.text = app['bowlingYears']?.toString() ?? '';
      _bowlingHistory.text = app['bowlingHistory']?.toString() ?? '';
      _skills.text = app['skills']?.toString() ?? '';
      final appStatus = app['status']?.toString();
      if (appStatus != null && appStatus.isNotEmpty) {
        _status = appStatus;
        _isEntrepreneur = appStatus.toLowerCase().contains('ип');
      }
    }
  }

  @override
  void dispose() {
    _fio.dispose();
    _birth.dispose();
    _phone.dispose();
    _educationName.dispose();
    _extraEducation.dispose();
    _workYears.dispose();
    _bowlingYears.dispose();
    _bowlingHistory.dispose();
    _skills.dispose();
    _region.dispose();
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
      final allClubs = [_freeAgentOption(), ...clubs];
      setState(() {
        _clubs = allClubs;
        _isLoadingClubs = false;
        _selectedClub ??= _resolveInitialClub(allClubs);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _clubs = [_freeAgentOption()];
        _isLoadingClubs = false;
        _clubsError = 'Не удалось загрузить список клубов';
        _selectedClub ??= _freeAgentOption();
      });
    }
  }

  ClubSummaryDto _resolveInitialClub(List<ClubSummaryDto> clubs) {
    final clubName = widget.initial.clubName.trim();
    if (clubName.isNotEmpty) {
      for (final club in clubs) {
        if (club.name.trim() == clubName) {
          return club;
        }
      }
    }
    return _freeAgentOption();
  }

  void _handleClubChange(int? clubId) {
    if (clubId == null) return;
    final selected = _clubs.firstWhere((club) => club.id == clubId, orElse: _freeAgentOption);
    setState(() => _selectedClub = selected);
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 18),
      firstDate: DateTime(1900),
      lastDate: now,
      locale: const Locale('ru'),
    );
    if (picked != null) {
      setState(() {
        _birthDate = picked;
        _birth.text = DateFormat('dd.MM.yyyy').format(picked);
      });
    }
  }

  void _showBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.primary),
    );
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) {
      _showBar('Заполните обязательные поля');
      return;
    }
    if (_birthDate == null) {
      _showBar('Выберите дату рождения');
      return;
    }
    if (_educationLevelId == null || _educationLevelId!.isEmpty) {
      _showBar('Выберите уровень образования');
      return;
    }
    if (_status == null || _status!.trim().isEmpty) {
      _showBar('Выберите статус: ИП или самозанятый');
      return;
    }
    if (_selectedClub == null) {
      _showBar('Выберите клуб или укажите свободного агента');
      return;
    }

    final entries = Validators.parseEmploymentHistory(_bowlingHistory.text.trim());
    final places = <String>[];
    final periods = <String>[];
    for (final entry in entries) {
      final place = entry.place.trim();
      if (place.isEmpty) continue;
      places.add(place);
      final y1 = entry.from?.year;
      final y2 = entry.to?.year;
      if (y1 != null && y2 != null) {
        periods.add('$y1-$y2');
      } else if (y1 != null && y2 == null) {
        periods.add('$y1-');
      }
    }

    final selectedClub = _selectedClub!;
    final isFreeAgent = selectedClub.id == 0;
    final clubName = isFreeAgent ? '' : selectedClub.name;
    final clubAddress = isFreeAgent ? '' : (selectedClub.address ?? '');
    final skills = _skills.text.trim();

    final applicationData = {
      'fio': _fio.text.trim(),
      'birth': DateFormat('yyyy-MM-dd').format(_birthDate!),
      'phone': _phone.text.trim(),
      'educationLevelId': _educationLevelId,
      'educationName': _educationName.text.trim(),
      'specializationId': '1',
      'advantages': _extraEducation.text.trim(),
      'workYears': _workYears.text.trim(),
      'bowlingYears': _bowlingYears.text.trim(),
      'bowlingHistory': _bowlingHistory.text.trim(),
      'skills': skills,
      'status': _status,
      'workPlaces': places.join(', '),
      'workPeriods': periods.join(', '),
      'clubId': isFreeAgent ? null : selectedClub.id,
      'region': _region.text.trim(),
      'isEntrepreneur': _isEntrepreneur ?? (_status == 'ИП'),
    };

    final profileData = {
      'fullName': _fio.text.trim(),
      'phone': _phone.text.trim(),
      'clubName': clubName,
      'address': clubAddress,
      'region': _region.text.trim(),
      'status': _status,
      'birthDate': _birthDate?.toIso8601String(),
      'clubs': clubName.isNotEmpty ? [clubName] : <String>[],
      'workplaceVerified': false,
      'clubId': isFreeAgent ? null : selectedClub.id,
      'clubAddress': clubAddress,
      'freeAgent': isFreeAgent,
      'ownerApprovalRequired': !isFreeAgent,
    };

    Navigator.of(context).pop({
      'profile': profileData,
      'application': applicationData,
    });
  }

  @override
  Widget build(BuildContext context) {
    final eduOptions = _eduMap.keys.toList();
    final selectedClubAddress = _selectedClub?.address?.trim();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark),
        ),
        title: const Text(
          'Анкета механика',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textDark),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              formDescription('Заполните все поля анкеты, чтобы подтвердить данные профиля.'),
              const SizedBox(height: 12),
              LabeledTextField(label: 'ФИО', controller: _fio, validator: Validators.notEmpty, icon: Icons.person, isRequired: true),
              LabeledTextField(
                label: 'Дата рождения',
                controller: _birth,
                validator: Validators.birth(_birthDate),
                readOnly: true,
                onTap: _pickBirthDate,
                icon: Icons.calendar_today,
                isRequired: true,
              ),
              LabeledTextField(
                label: 'Номер телефона',
                controller: _phone,
                validator: Validators.phone,
                keyboardType: TextInputType.phone,
                readOnly: true,
                icon: Icons.phone,
                isRequired: true,
              ),
              sectionTitle('Образование'),
              const SizedBox(height: 12),
              RadioGroupWrap(
                options: eduOptions,
                groupValue: _educationLevelId == null
                    ? null
                    : eduOptions.firstWhere(
                        (title) => _eduMap[title] == _educationLevelId,
                        orElse: () => eduOptions.first,
                      ),
                onChanged: (selectedTitle) {
                  final id = _eduMap[selectedTitle ?? ''];
                  setState(() => _educationLevelId = id);
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
                validator: Validators.notEmpty,
                isRequired: true,
              ),
              sectionTitle('Стаж работы'),
              const SizedBox(height: 8),
              LabeledTextField(
                label: 'Общий стаж работы',
                controller: _workYears,
                validator: Validators.integer,
                keyboardType: TextInputType.number,
                isRequired: true,
              ),
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
              formDescription('Укажите клуб, в котором работаете, или отметьте себя свободным агентом.'),
              const SizedBox(height: 8),
              if (_isLoadingClubs)
                const Center(child: CircularProgressIndicator())
              else if (_clubsError != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_clubsError!, style: AppTextStyles.formHint.copyWith(color: Colors.red)),
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
                          child: Text(club.address?.trim().isNotEmpty == true ? '${club.name} — ${club.address}' : club.name),
                        ),
                      )
                      .toList(),
                  onChanged: _handleClubChange,
                  decoration: const InputDecoration(labelText: 'Клуб'),
                  validator: (value) => value == null ? 'Выберите клуб' : null,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
              if (_selectedClub != null && _selectedClub!.id != 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    selectedClubAddress != null && selectedClubAddress.isNotEmpty ? 'Адрес: $selectedClubAddress' : 'Адрес не указан',
                    style: AppTextStyles.formHint,
                  ),
                ),
              const SizedBox(height: 16),
              LabeledTextField(
                label: 'Где и когда работали в боулинге',
                controller: _bowlingHistory,
                validator: Validators.notEmpty,
                isRequired: true,
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  '${Validators.bowlingHistoryHelper}\nНапример: ${Validators.bowlingHistoryHintExample}',
                  style: AppTextStyles.formHint,
                ),
              ),
              LabeledTextField(
                label: 'Регион (город/область)',
                controller: _region,
                validator: Validators.notEmpty,
                isRequired: true,
              ),
              LabeledTextField(
                label: 'Навыки и преимущества',
                controller: _skills,
                validator: Validators.notEmpty,
                isRequired: true,
              ),
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
              const SizedBox(height: 20),
              if (_status == null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Выберите статус: ИП или самозанятый.',
                    style: AppTextStyles.formHint.copyWith(color: Colors.red),
                  ),
                ),
              CustomButton(
                text: _isSubmitting ? 'Сохранение...' : 'Сохранить анкету',
                onPressed: _isSubmitting ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
