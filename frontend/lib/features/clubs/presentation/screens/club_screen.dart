import 'package:flutter/material.dart';

import '../../../../core/models/order_status.dart';
import '../../../../core/models/user_club.dart';
import '../../../../core/repositories/clubs_repository.dart';
import '../../../../core/repositories/maintenance_repository.dart';
import '../../../../core/repositories/support_repository.dart';
import '../../../../core/repositories/user_repository.dart';
import '../../../../core/routing/route_args.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/authz/acl.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/bottom_nav.dart';
import '../../../../core/utils/net_ui.dart';
import '../../../../core/utils/user_club_resolver.dart';
import '../../../../models/maintenance_request_response_dto.dart';
import '../../../../models/support_appeal_request_dto.dart';
import '../../../../shared/widgets/buttons/custom_button.dart';
import '../../../../shared/widgets/layout/common_ui.dart';
import '../../../../shared/widgets/layout/section_list.dart';
import '../../../../shared/widgets/nav/app_bottom_nav.dart';
import '../../../orders/presentation/screens/add_parts_to_order_screen.dart';

class ClubScreen extends StatefulWidget {
  final int? initialClubId;

  const ClubScreen({Key? key, this.initialClubId}) : super(key: key);

  @override
  State<ClubScreen> createState() => _ClubScreenState();
}

class _ClubScreenState extends State<ClubScreen> {
  final _userRepository = UserRepository();
  final _clubsRepository = ClubsRepository();
  final _supportRepository = SupportRepository();

  bool _isLoading = true;
  bool _hasError = false;
  List<UserClub> _clubs = const [];
  List<UserClub> _availableClubs = const [];
  int? _selectedIndex;
  UserAccessScope? _scope;
  static const List<String> _equipmentOptions = ['AMF', 'Brunswick', 'VIA', 'XIMA', 'Другое'];
  static const Map<String, List<String>> _equipmentModels = {
    'AMF': ['82/70XLi', '82/90XLi', 'HVO'],
    'Brunswick': ['A2', 'GS-X', 'GS-X Lite', 'NXT'],
    'VIA': ['VIA Vector', 'VIA Edge'],
    'XIMA': ['XIMA Phoenix', 'XIMA Evo'],
  };

  @override
  void initState() {
    super.initState();
    _loadClubs();
  }

  Future<void> _loadClubs() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final me = await _userRepository.me();
      final scope = await UserAccessScope.fromProfile(me);
      if (!mounted) return;

      List<UserClub> clubs;
      if (scope.isAdmin) {
        final summaries = await _clubsRepository.getClubs();
        clubs = summaries
            .map(
              (club) => UserClub(
                id: club.id,
                name: club.name,
                address: club.address,
                lanes: club.lanesCount?.toString(),
                phone: club.contactPhone,
                email: club.contactEmail,
              ),
            )
            .toList();
      } else {
        clubs = resolveUserClubs(me);
      }
      int? selectedIndex;
      if (widget.initialClubId != null) {
        final index = clubs.indexWhere((club) => club.id == widget.initialClubId);
        if (index >= 0) {
          selectedIndex = index;
        }
      }

      List<UserClub> availableClubs = const [];
      if (scope.isMechanic && clubs.isEmpty) {
        final summaries = await _clubsRepository.getClubs();
        availableClubs = summaries
            .map(
              (club) => UserClub(
                id: club.id,
                name: club.name,
                address: club.address,
                lanes: club.lanesCount?.toString(),
                phone: club.contactPhone,
                email: club.contactEmail,
              ),
            )
            .toList()
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      }

      setState(() {
        _clubs = clubs;
        _selectedIndex = selectedIndex ?? (clubs.isNotEmpty ? 0 : null);
        _scope = scope;
        _availableClubs = availableClubs;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      showApiError(context, e);
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, Routes.welcome, (route) => false);
  }

  void _onSelect(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
  }

  void _openWarehouse() {
    final selected = _selectedIndex != null ? _clubs[_selectedIndex!] : null;
    if (selected == null) {
      showSnack(context, 'Выберите клуб');
      return;
    }
    final scope = _scope;
    if (scope != null && !scope.canActOnClub(selected)) {
      showSnack(context, 'Нет доступа к выбранному клубу');
      return;
    }
    Navigator.pushNamed(
      context,
      Routes.warehouseSelector,
      arguments: WarehouseSelectorArgs(preferredClubId: selected.id),
    );
  }

  void _openLanesOverview() {
    final selected = _selectedIndex != null ? _clubs[_selectedIndex!] : null;
    if (selected == null) {
      showSnack(context, 'Выберите клуб');
      return;
    }
    final scope = _scope;
    if (scope != null && !scope.canActOnClub(selected)) {
      showSnack(context, 'Нет доступа к выбранному клубу');
      return;
    }
    final laneCount = _parseLaneCount(selected.lanes);
    Navigator.pushNamed(
      context,
      Routes.clubLanes,
      arguments: ClubLanesArgs(
        clubId: selected.id,
        clubName: selected.name,
        lanesCount: laneCount,
      ),
    );
  }

  Future<void> _openAddPartFlow() async {
    final selected = _selectedIndex != null ? _clubs[_selectedIndex!] : null;
    if (selected == null) {
      showSnack(context, 'Выберите клуб');
      return;
    }
    final scope = _scope;
    if (scope != null && !scope.canActOnClub(selected)) {
      showSnack(context, 'Нет доступа к выбранному клубу');
      return;
    }
    final selectedOrder = await showModalBottomSheet<MaintenanceRequestResponseDto>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _OrderSelectionSheet(clubId: selected.id, clubName: selected.name),
    );

    if (!mounted || selectedOrder == null) return;

    final result = await Navigator.push<MaintenanceRequestResponseDto>(
      context,
      MaterialPageRoute(builder: (_) => AddPartsToOrderScreen(order: selectedOrder)),
    );

    if (result != null && mounted) {
      showSnack(context, 'Детали добавлены в заявку №${result.requestId}');
    }
  }

  void _openOwnerDashboard() {
    final selected = _selectedIndex != null ? _clubs[_selectedIndex!] : null;
    if (selected == null) {
      showSnack(context, 'Выберите клуб');
      return;
    }
    Navigator.pushNamed(context, Routes.ownerDashboard, arguments: selected.id);
  }

  void _openClubStaff() {
    final selected = _selectedIndex != null ? _clubs[_selectedIndex!] : null;
    if (selected == null) {
      showSnack(context, 'Выберите клуб');
      return;
    }
    final scope = _scope;
    if (scope != null && !scope.canActOnClub(selected)) {
      showSnack(context, 'Нет доступа к выбранному клубу');
      return;
    }
    Navigator.pushNamed(context, Routes.clubStaff, arguments: selected.id);
  }

  Future<void> _openClubRequestSheet() async {
    final clubOptions = _clubs.isNotEmpty ? _clubs : _availableClubs;
    if (clubOptions.isEmpty) {
      showSnack(context, 'Список клубов пуст');
      return;
    }

    final commentController = TextEditingController();
    final types = <String>[
      'Аккредитация (переход в клубные механики)',
      'Временный доступ к технической информации',
    ];
    int selectedIndex = _selectedIndex ?? 0;
    if (selectedIndex >= clubOptions.length) {
      selectedIndex = 0;
    }
    String selectedType = types.first;
    bool submitting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Заявка в клуб',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: selectedIndex,
                    decoration: const InputDecoration(labelText: 'Клуб'),
                    items: List.generate(
                      clubOptions.length,
                      (index) => DropdownMenuItem(
                        value: index,
                        child: Text(clubOptions[index].name, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                    onChanged: submitting
                        ? null
                        : (value) {
                            if (value == null) return;
                            setModalState(() => selectedIndex = value);
                          },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: const InputDecoration(labelText: 'Тип заявки'),
                    items: types
                        .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                        .toList(),
                    onChanged: submitting
                        ? null
                        : (value) {
                            if (value == null) return;
                            setModalState(() => selectedType = value);
                          },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: commentController,
                    decoration: const InputDecoration(
                      labelText: 'Комментарий (опционально)',
                      hintText: 'Опишите пожелания или сроки',
                    ),
                    maxLines: 3,
                    enabled: !submitting,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: submitting
                          ? null
                          : () async {
                              final club = clubOptions[selectedIndex];
                              setModalState(() => submitting = true);
                              try {
                                final message = StringBuffer()
                                  ..writeln('Клуб: ${club.name}')
                                  ..writeln('Тип заявки: $selectedType');
                                final comment = commentController.text.trim();
                                if (comment.isNotEmpty) {
                                  message.writeln('Комментарий: $comment');
                                }
                                final dto = SupportAppealRequestDto(
                                  subject: 'Заявка в клуб',
                                  message: message.toString(),
                                );
                                await _supportRepository.submitAppeal(dto);
                                if (!mounted) return;
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Заявка отправлена')),
                                );
                              } catch (e) {
                                if (!mounted) return;
                                showApiError(context, e);
                              } finally {
                                if (mounted) {
                                  setModalState(() => submitting = false);
                                }
                              }
                            },
                      child: submitting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Отправить заявку'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openCreateObjectSheet() async {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final lanesController = TextEditingController();
    final customEquipmentController = TextEditingController();
    final customModelController = TextEditingController();
    String? selectedEquipment;
    String? selectedModel;
    final formKey = GlobalKey<FormState>();
    bool submitting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> submit() async {
              if (!formKey.currentState!.validate()) return;
              final equipment = selectedEquipment == null
                  ? null
                  : selectedEquipment == 'Другое'
                      ? customEquipmentController.text.trim()
                      : selectedEquipment;
              if (equipment == null || equipment.isEmpty) {
                showSnack(context, 'Укажите производителя');
                return;
              }
              final model = selectedEquipment == null
                  ? null
                  : selectedEquipment == 'Другое'
                      ? customModelController.text.trim()
                      : selectedModel;
              if (model == null || model.isEmpty) {
                showSnack(context, 'Укажите модель оборудования');
                return;
              }
              final lanes = int.tryParse(lanesController.text.trim());
              if (lanes == null || lanes <= 0) {
                showSnack(context, 'Количество дорожек должно быть положительным числом');
                return;
              }

              setModalState(() => submitting = true);
              try {
                final message = StringBuffer()
                  ..writeln('Название объекта: ${nameController.text.trim()}')
                  ..writeln('Адрес: ${addressController.text.trim()}')
                  ..writeln('Количество дорожек: $lanes')
                  ..writeln('Производитель: $equipment')
                  ..writeln('Модель: $model');
                final dto = SupportAppealRequestDto(
                  subject: 'Создание объекта',
                  message: message.toString(),
                );
                await _supportRepository.submitAppeal(dto);
                if (!mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Заявка на создание объекта отправлена')),
                );
              } catch (e) {
                if (!mounted) return;
                showApiError(context, e);
              } finally {
                if (mounted) {
                  setModalState(() => submitting = false);
                }
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Создать объект',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Название объекта'),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Введите название объекта' : null,
                      enabled: !submitting,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: addressController,
                      decoration: const InputDecoration(labelText: 'Адрес'),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Введите адрес' : null,
                      enabled: !submitting,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: lanesController,
                      decoration: const InputDecoration(labelText: 'Количество дорожек'),
                      keyboardType: TextInputType.number,
                      validator: (value) => value == null || value.trim().isEmpty ? 'Введите количество дорожек' : null,
                      enabled: !submitting,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedEquipment,
                      decoration: const InputDecoration(labelText: 'Производитель'),
                      items: _equipmentOptions
                          .map((option) => DropdownMenuItem(value: option, child: Text(option)))
                          .toList(),
                      onChanged: submitting
                          ? null
                          : (value) => setModalState(() {
                                selectedEquipment = value;
                                selectedModel = null;
                              }),
                    ),
                    if (selectedEquipment != null && selectedEquipment != 'Другое')
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: DropdownButtonFormField<String>(
                          value: selectedModel,
                          decoration: const InputDecoration(labelText: 'Модель оборудования'),
                          items: (_equipmentModels[selectedEquipment] ?? const [])
                              .map((model) => DropdownMenuItem(value: model, child: Text(model)))
                              .toList(),
                          validator: (value) => value == null || value.trim().isEmpty ? 'Выберите модель оборудования' : null,
                          onChanged: submitting ? null : (value) => setModalState(() => selectedModel = value),
                        ),
                      ),
                    if (selectedEquipment == 'Другое')
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: TextFormField(
                          controller: customEquipmentController,
                          decoration: const InputDecoration(labelText: 'Уточните производителя'),
                          validator: (value) => value == null || value.trim().isEmpty ? 'Уточните производителя' : null,
                          enabled: !submitting,
                        ),
                      ),
                    if (selectedEquipment == 'Другое')
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: TextFormField(
                          controller: customModelController,
                          decoration: const InputDecoration(labelText: 'Модель оборудования'),
                          validator: (value) => value == null || value.trim().isEmpty ? 'Укажите модель оборудования' : null,
                          enabled: !submitting,
                        ),
                      ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: submitting ? null : submit,
                        child: submitting
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Отправить'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openAddExistingObjectSheet() async {
    List<UserClub> publicClubs = [];
    try {
      final summaries = await _clubsRepository.getClubs();
      publicClubs = summaries
          .map(
            (club) => UserClub(
              id: club.id,
              name: club.name,
              address: club.address,
              lanes: club.lanesCount?.toString(),
              phone: club.contactPhone,
              email: club.contactEmail,
            ),
          )
          .toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } catch (e) {
      if (!mounted) return;
      showApiError(context, e);
      return;
    }

    if (publicClubs.isEmpty) {
      showSnack(context, 'Список клубов пуст');
      return;
    }

    int selectedIndex = 0;
    bool? isOwner;
    bool submitting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> submit() async {
              if (isOwner == null) {
                showSnack(context, 'Ответьте на вопрос о владельце клуба');
                return;
              }
              if (!isOwner!) {
                showSnack(context, 'Добавление доступно только владельцам клуба');
                return;
              }
              setModalState(() => submitting = true);
              try {
                final club = publicClubs[selectedIndex];
                final message = StringBuffer()
                  ..writeln('Клуб: ${club.name}')
                  ..writeln('ID: ${club.id}')
                  ..writeln('Адрес: ${club.address ?? '—'}')
                  ..writeln('Ответ: Да, являюсь владельцем');
                final dto = SupportAppealRequestDto(
                  subject: 'Запрос на добавление объекта',
                  message: message.toString(),
                );
                await _supportRepository.submitAppeal(dto);
                if (!mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Заявка на добавление объекта отправлена')),
                );
              } catch (e) {
                if (!mounted) return;
                showApiError(context, e);
              } finally {
                if (mounted) {
                  setModalState(() => submitting = false);
                }
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Добавить объект из списка',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: selectedIndex,
                    decoration: const InputDecoration(labelText: 'Клуб'),
                    items: List.generate(
                      publicClubs.length,
                      (index) => DropdownMenuItem(
                        value: index,
                        child: Text(publicClubs[index].name, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                    onChanged: submitting
                        ? null
                        : (value) {
                            if (value == null) return;
                            setModalState(() => selectedIndex = value);
                          },
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Вы являетесь владельцем клуба?',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  RadioListTile<bool>(
                    value: true,
                    groupValue: isOwner,
                    onChanged: submitting ? null : (value) => setModalState(() => isOwner = value),
                    title: const Text('Да'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  RadioListTile<bool>(
                    value: false,
                    groupValue: isOwner,
                    onChanged: submitting ? null : (value) => setModalState(() => isOwner = value),
                    title: const Text('Нет'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: submitting ? null : submit,
                      child: submitting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Отправить'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  int? _parseLaneCount(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final direct = int.tryParse(trimmed);
    if (direct != null) return direct;
    final digits = RegExp(r'\d+').firstMatch(trimmed);
    return digits != null ? int.tryParse(digits.group(0)!) : null;
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 64, color: AppColors.darkGray),
            const SizedBox(height: 12),
            const Text('Не удалось загрузить информацию о клубах', style: TextStyle(color: AppColors.darkGray)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadClubs,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Повторить'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _logout,
              child: const Text('Выйти из аккаунта'),
            ),
          ],
        ),
      );
    }
    if (_clubs.isEmpty) {
      if (_scope?.role == 'owner') {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'У вас пока нет объектов.',
                  style: TextStyle(color: AppColors.darkGray),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                CustomButton(text: 'Создать объект', onPressed: _openCreateObjectSheet),
                const SizedBox(height: 12),
                CustomButton(
                  text: 'Добавить объект из списка действующих клубов',
                  isOutlined: true,
                  onPressed: _openAddExistingObjectSheet,
                ),
              ],
            ),
          ),
        );
      }
      final canRequestClub = _scope?.isMechanic == true;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Для вашего аккаунта нет привязанных объектов',
                style: TextStyle(color: AppColors.darkGray),
                textAlign: TextAlign.center,
              ),
              if (canRequestClub) ...[
                const SizedBox(height: 16),
                CustomButton(text: 'Подать заявку в клуб', onPressed: _openClubRequestSheet),
              ],
            ],
          ),
        ),
      );
    }

    final items = _clubs.map((club) => club.name).toList();
    final selectedClub = _selectedIndex != null ? _clubs[_selectedIndex!] : null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        CommonUI.card(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Объекты',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textDark),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.primary),
                onPressed: _loadClubs,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionList(
          items: items,
          selected: _selectedIndex ?? -1,
          onSelect: _onSelect,
        ),
        const SizedBox(height: 16),
        if (selectedClub != null) _ClubDetailsCard(club: selectedClub),
        const SizedBox(height: 20),
        if (_scope?.isMechanic == true && _clubs.isEmpty) ...[
          CustomButton(text: 'Подать заявку в клуб', onPressed: _openClubRequestSheet),
          const SizedBox(height: 12),
        ],
        if (_scope?.role == 'owner' || _scope?.role == 'manager' || _scope?.role == 'admin') ...[
          CustomButton(text: 'Техинформация и ТО', onPressed: _openOwnerDashboard),
          const SizedBox(height: 12),
          CustomButton(text: 'Сотрудники', onPressed: _openClubStaff),
          const SizedBox(height: 12),
        ],
        CustomButton(text: 'Дорожки и ТО', onPressed: _openLanesOverview),
        const SizedBox(height: 12),
        CustomButton(text: 'Добавить деталь в заказ', onPressed: _openAddPartFlow),
        const SizedBox(height: 12),
        CustomButton(text: 'Открыть склад', isOutlined: true, onPressed: _openWarehouse),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: _buildBody()),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 2,
        onTap: (i) => BottomNavDirect.go(context, 2, i),
      ),
    );
  }
}

class _ClubDetailsCard extends StatelessWidget {
  final UserClub club;

  const _ClubDetailsCard({required this.club});

  @override
  Widget build(BuildContext context) {
    return CommonUI.card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            club.name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textDark),
          ),
          const SizedBox(height: 12),
          _InfoRow(icon: Icons.location_on_rounded, label: 'Адрес', value: club.address ?? 'Не указан'),
          if (club.lanes != null && club.lanes!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            _InfoRow(icon: Icons.format_list_numbered, label: 'Дорожек', value: club.lanes!),
          ],
          if (club.equipment != null && club.equipment!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            _InfoRow(icon: Icons.memory_rounded, label: 'Оборудование', value: club.equipment!),
          ],
          if (club.phone != null && club.phone!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            _InfoRow(icon: Icons.phone, label: 'Телефон', value: club.phone!),
          ],
          if (club.email != null && club.email!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            _InfoRow(icon: Icons.email_outlined, label: 'Email', value: club.email!),
          ],
        ],
      ),
    );
  }
}

class _OrderSelectionSheet extends StatefulWidget {
  final int clubId;
  final String clubName;

  const _OrderSelectionSheet({required this.clubId, required this.clubName});

  @override
  State<_OrderSelectionSheet> createState() => _OrderSelectionSheetState();
}

class _OrderSelectionSheetState extends State<_OrderSelectionSheet> {
  final _repository = MaintenanceRepository();
  bool _isLoading = true;
  bool _hasError = false;
  List<MaintenanceRequestResponseDto> _orders = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final orders = await _repository.getRequestsByClub(widget.clubId);
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      showApiError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.8,
        child: Container(
          padding: EdgeInsets.fromLTRB(16, 12, 16, bottom + 16),
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.lightGray,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Выберите заказ для клуба "${widget.clubName}"',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: AppColors.darkGray),
            const SizedBox(height: 12),
            const Text('Не удалось загрузить заказы', style: TextStyle(color: AppColors.darkGray)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }
    if (_orders.isEmpty) {
      return const Center(
        child: Text(
          'Для выбранного клуба пока нет заявок',
          style: TextStyle(color: AppColors.darkGray),
          textAlign: TextAlign.center,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          final order = _orders[index];
          return ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            tileColor: Colors.white,
            title: Text(
              'Заявка №${order.requestId}',
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (order.laneNumber != null)
                  Text('Дорожка ${order.laneNumber}', style: const TextStyle(color: AppColors.darkGray)),
                if (order.status != null && order.status!.isNotEmpty)
                  Text(
                    'Статус: ${describeOrderStatus(order.status!)}',
                    style: const TextStyle(color: AppColors.darkGray),
                  ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.darkGray),
            onTap: () => Navigator.pop(context, order),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemCount: _orders.length,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 13, color: AppColors.darkGray)),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textDark),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
