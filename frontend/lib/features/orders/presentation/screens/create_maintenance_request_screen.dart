import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/repositories/maintenance_repository.dart';
import '../../../../core/repositories/inventory_repository.dart';
import '../../../../core/repositories/user_repository.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/net_ui.dart';
import '../../../../core/utils/user_club_resolver.dart';
import '../../../../core/models/user_club.dart';
import '../../../../models/part_request_dto.dart';
import '../../../../models/part_dto.dart';
import '../../../../shared/widgets/buttons/custom_button.dart';

/// Экран создания новой заявки на обслуживание
class CreateMaintenanceRequestScreen extends StatefulWidget {
  final int? initialClubId;

  const CreateMaintenanceRequestScreen({super.key, this.initialClubId});

  @override
  State<CreateMaintenanceRequestScreen> createState() => _CreateMaintenanceRequestScreenState();
}

class _CreateMaintenanceRequestScreenState extends State<CreateMaintenanceRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = MaintenanceRepository();
  final _userRepository = UserRepository();
  final _inventoryRepository = InventoryRepository();

  final _notesController = TextEditingController();
  final _laneController = TextEditingController();
  final _catalogNumberController = TextEditingController();
  final _partNameController = TextEditingController();
  final _quantityController = TextEditingController();
  Timer? _partsSearchDebounce;

  bool _isLoading = true;
  bool _hasError = false;
  int? _mechanicProfileId;
  int? _selectedClubId;
  int? _selectedLane;
  List<UserClub> _clubs = const [];

  List<RequestedPartDto> requestedParts = [];
  List<PartDto> _partSuggestions = const <PartDto>[];
  bool _isSearchingParts = false;
  PartDto? _selectedCatalogPart;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _laneController.dispose();
    _catalogNumberController.dispose();
    _partNameController.dispose();
    _quantityController.dispose();
    _partsSearchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final me = await _userRepository.me();
      if (!mounted) return;
      final clubs = resolveUserClubs(me);
      final mechanicProfileId = _extractMechanicProfileId(me);
      final resolvedClubId = _resolveInitialClubId(clubs, widget.initialClubId);
      setState(() {
        _mechanicProfileId = mechanicProfileId;
        _clubs = clubs;
        _selectedClubId = resolvedClubId;
        _selectedLane = null;
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

  void _addPart() {
    final name = _partNameController.text.trim();
    if (name.isEmpty) {
      showSnack(context, 'Укажите название запчасти');
      return;
    }

    final quantity = int.tryParse(_quantityController.text.trim());
    if (quantity == null || quantity <= 0) {
      showSnack(context, 'Укажите корректное количество');
      return;
    }

    final selected = _selectedCatalogPart;
    final catalogNumberInput = _catalogNumberController.text.trim();
    final resolvedCatalogNumber = catalogNumberInput.isNotEmpty
        ? catalogNumberInput
        : (selected != null ? _resolveCatalogNumber(selected) : null);

    setState(() {
      final newItem = RequestedPartDto(
        inventoryId: selected?.inventoryId,
        catalogId: selected?.catalogId,
        catalogNumber: resolvedCatalogNumber,
        partName: name,
        quantity: quantity,
        warehouseId: selected?.warehouseId ?? _selectedClubId,
        location: selected?.location,
      );

      if (newItem.inventoryId != null) {
        final existingIndex = requestedParts.indexWhere((item) => item.inventoryId == newItem.inventoryId);
        if (existingIndex >= 0) {
          final existing = requestedParts[existingIndex];
          requestedParts[existingIndex] = RequestedPartDto(
            inventoryId: existing.inventoryId,
            catalogId: existing.catalogId ?? newItem.catalogId,
            catalogNumber: existing.catalogNumber ?? newItem.catalogNumber,
            partName: existing.partName,
            quantity: existing.quantity + quantity,
            warehouseId: existing.warehouseId ?? newItem.warehouseId,
            location: existing.location ?? newItem.location,
          );
        } else {
          requestedParts.add(newItem);
        }
      } else {
        requestedParts.add(newItem);
      }

      _catalogNumberController.clear();
      _partNameController.clear();
      _quantityController.clear();
      _selectedCatalogPart = null;
      _partSuggestions = const <PartDto>[];
    });
  }

  void _removePart(int index) {
    setState(() {
      requestedParts.removeAt(index);
    });
  }

  String _resolvePartDisplayName(PartDto part) {
    final names = [part.commonName, part.officialNameRu, part.officialNameEn];
    for (final name in names) {
      if (name != null && name.trim().isNotEmpty) {
        return name.trim();
      }
    }
    return part.catalogNumber;
  }

  String _resolveCatalogNumber(PartDto part) {
    final candidate = part.catalogNumber.trim();
    if (candidate.isNotEmpty) {
      return candidate;
    }
    return part.catalogId.toString();
  }

  void _onPartNameChanged(String value) {
    _partsSearchDebounce?.cancel();
    _selectedCatalogPart = null;
    _catalogNumberController.clear();
    final trimmed = value.trim();
    if (trimmed.length < 2) {
      setState(() {
        _partSuggestions = const <PartDto>[];
        _isSearchingParts = false;
      });
      return;
    }
    _partsSearchDebounce = Timer(const Duration(milliseconds: 350), () {
      _searchParts(trimmed);
    });
  }

  Future<void> _searchParts(String query) async {
    setState(() {
      _isSearchingParts = true;
    });
    try {
      final results = await _inventoryRepository.search(query, clubId: _selectedClubId);
      if (!mounted) return;
      setState(() {
        _partSuggestions = results.take(10).toList();
        _isSearchingParts = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _partSuggestions = const <PartDto>[];
        _isSearchingParts = false;
      });
    }
  }

  void _selectSuggestedPart(PartDto part) {
    _partsSearchDebounce?.cancel();
    setState(() {
      _selectedCatalogPart = part;
      _partNameController.text = _resolvePartDisplayName(part);
      _catalogNumberController.text = _resolveCatalogNumber(part);
      _partSuggestions = const <PartDto>[];
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedClubId == null) {
      showSnack(context, 'Выберите клуб, к которому вы привязаны');
      return;
    }

    if (_mechanicProfileId == null) {
      showSnack(context, 'Не удалось определить профиль механика. Перезайдите в приложение.');
      return;
    }

    if (requestedParts.isEmpty) {
      showSnack(context, 'Добавьте хотя бы одну запчасть');
      return;
    }

    final laneOptions = _availableLaneNumbers;
    int? lane = laneOptions.isNotEmpty ? _selectedLane : int.tryParse(_laneController.text.trim());

    if (lane == null || lane <= 0) {
      showSnack(context, 'Укажите корректный номер дорожки');
      return;
    }

    final laneLimit = _laneLimitForSelectedClub();
    if (laneLimit != null && lane > laneLimit) {
      showSnack(context, 'В клубе только $laneLimit дорожек');
      return;
    }

    final request = PartRequestDto(
      clubId: _selectedClubId!,
      mechanicId: _mechanicProfileId!,
      laneNumber: lane,
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
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Не удалось загрузить данные профиля',
                style: TextStyle(color: AppColors.darkGray),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: 'Повторить попытку',
                onPressed: _loadUserData,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _logout,
                child: const Text('Выйти из аккаунта'),
              ),
            ],
          ),
        ),
      );
    }
    if (_clubs.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          SizedBox(height: 80),
          Center(
            child: Text(
              'Вы не привязаны ни к одному клубу. Обратитесь к администратору для назначения.',
              style: TextStyle(color: AppColors.darkGray, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }

    if (_mechanicProfileId == null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          SizedBox(height: 80),
          Center(
            child: Text(
              'Не удалось определить профиль механика. Обратитесь к администратору.',
              style: TextStyle(color: AppColors.darkGray, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Клуб *',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            value: _selectedClubId,
            decoration: _inputDecoration(),
            items: _clubs
                .map(
                  (club) => DropdownMenuItem<int>(
                    value: club.id,
                    child: Text(
                      club.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() {
              _selectedClubId = value;
              _selectedLane = null;
              _laneController.clear();
            }),
            validator: (value) => value == null ? 'Выберите клуб' : null,
          ),
          const SizedBox(height: 16),

          // Номер дорожки
          _buildLaneField(),
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
            decoration: _inputDecoration(hint: 'Дополнительная информация (опционально)'),
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

          // Название запчасти
          _buildPartNameSelector(),
          const SizedBox(height: 16),

          // Каталожный номер
          _buildTextField(
            label: 'Каталожный номер',
            hint: 'Укажите номер (если известен)',
            controller: _catalogNumberController,
            validator: (_) => null,
          ),
          const SizedBox(height: 16),

          // Количество
          _buildTextField(
            label: 'Количество *',
            hint: 'Введите количество',
            keyboardType: TextInputType.number,
            controller: _quantityController,
            validator: (value) {
              if (requestedParts.isNotEmpty) {
                return null;
              }
              if (value == null || value.trim().isEmpty) {
                return 'Укажите количество';
              }
              final qty = int.tryParse(value.trim());
              if (qty == null || qty <= 0) {
                return 'Количество должно быть больше нуля';
              }
              return null;
            },
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
                                Text(
                                  'Кат. №: ${part.catalogNumber != null && part.catalogNumber!.trim().isNotEmpty ? part.catalogNumber : "—"}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.darkGray),
                                ),
                                if (part.location != null && part.location!.isNotEmpty)
                                  Text(
                                    'Локация: ${part.location}',
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
    );
  }

  Widget _buildLaneField() {
    final options = _availableLaneNumbers;
    if (options.isEmpty) {
      return _buildTextField(
        label: 'Номер дорожки *',
        hint: 'Введите номер дорожки',
        keyboardType: TextInputType.number,
        controller: _laneController,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Укажите номер дорожки';
          }
          final lane = int.tryParse(value.trim());
          if (lane == null || lane <= 0) {
            return 'Номер дорожки должен быть больше нуля';
          }
          final limit = _laneLimitForSelectedClub();
          if (limit != null && (lane < 1 || lane > limit)) {
            return 'Доступно дорожек: $limit';
          }
          return null;
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Номер дорожки *',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: _selectedLane,
          decoration: _inputDecoration(),
          hint: const Text('Выберите дорожку'),
          items: options
              .map(
                (lane) => DropdownMenuItem<int>(
                  value: lane,
                  child: Text('Дорожка $lane'),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => _selectedLane = value),
          validator: (value) => value == null ? 'Выберите дорожку' : null,
        ),
      ],
    );
  }

  Widget _buildPartNameSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Название запчасти *',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _partNameController,
          decoration: _inputDecoration(hint: 'Начните вводить название запчасти'),
          validator: (value) {
            if (requestedParts.isNotEmpty) {
              return null;
            }
            if (value == null || value.trim().isEmpty) {
              return 'Укажите название запчасти';
            }
            return null;
          },
          onChanged: _onPartNameChanged,
        ),
        if (_isSearchingParts)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        if (_partSuggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.lightGray),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final part = _partSuggestions[index];
                final quantity = part.quantity;
                final subtitleBuffer = StringBuffer(part.catalogNumber);
                if (quantity != null) {
                  subtitleBuffer.write(' · Остаток: $quantity');
                }
                final location = part.location;
                if (location != null && location.trim().isNotEmpty) {
                  subtitleBuffer.write(' · ${location.trim()}');
                }
                final subtitle = subtitleBuffer.toString();
                return ListTile(
                  leading: const Icon(Icons.settings_suggest_rounded, color: AppColors.primary),
                  title: Text(_resolvePartDisplayName(part)),
                  subtitle: Text(subtitle),
                  onTap: () => _selectSuggestedPart(part),
                );
              },
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemCount: _partSuggestions.length,
            ),
          ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    TextEditingController? controller,
    bool readOnly = false,
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
          readOnly: readOnly,
          decoration: _inputDecoration(hint: hint),
          validator: validator,
          onChanged: onChanged,
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
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
    );
  }

  UserClub? get _currentClub {
    final id = _selectedClubId;
    if (id == null) return null;
    for (final club in _clubs) {
      if (club.id == id) return club;
    }
    return null;
  }

  int? _laneLimitForSelectedClub() {
    final club = _currentClub;
    if (club == null) return null;
    return _parseLaneCount(club.lanes);
  }

  List<int> get _availableLaneNumbers {
    final limit = _laneLimitForSelectedClub();
    if (limit == null || limit <= 0) {
      return const [];
    }
    return List<int>.generate(limit, (index) => index + 1);
  }

  int? _parseLaneCount(String? raw) {
    if (raw == null) return null;
    final matches = RegExp(r'\d+').allMatches(raw);
    if (matches.isEmpty) {
      return int.tryParse(raw.trim());
    }
    final match = matches.first;
    return int.tryParse(match.group(0)!);
  }

  int? _extractMechanicProfileId(Map<String, dynamic>? me) {
    if (me == null) {
      return null;
    }

    final direct = me['mechanicProfileId'];
    if (direct is num) {
      return direct.toInt();
    }
    if (direct is String) {
      final parsed = int.tryParse(direct);
      if (parsed != null) {
        return parsed;
      }
    }

    final profile = me['mechanicProfile'];
    if (profile is Map) {
      final map = Map<String, dynamic>.from(profile);
      final candidates = [map['profileId'], map['id']];
      for (final candidate in candidates) {
        if (candidate is num) {
          return candidate.toInt();
        }
        if (candidate is String) {
          final parsed = int.tryParse(candidate);
          if (parsed != null) {
            return parsed;
          }
        }
      }
    }

    return null;
  }

  int? _resolveInitialClubId(List<UserClub> clubs, int? desiredId) {
    if (clubs.isEmpty) {
      return null;
    }
    if (desiredId != null) {
      for (final club in clubs) {
        if (club.id == desiredId) {
          return desiredId;
        }
      }
    }
    return clubs.first.id;
  }
}
