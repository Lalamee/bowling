import 'package:flutter/material.dart';
import '../../../../core/models/user_club.dart';
import '../../../../core/theme/colors.dart';
import '../../../../shared/widgets/chips/radio_group_horizontal.dart';
import '../../../../shared/widgets/nav/app_bottom_nav.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/repositories/club_staff_repository.dart';
import '../../../../core/repositories/user_repository.dart';
import '../../../../core/utils/net_ui.dart';
import '../../../../core/utils/phone_utils.dart';
import '../../../../core/utils/user_club_resolver.dart';

class ClubStaffScreen extends StatefulWidget {
  final int? clubId;
  
  const ClubStaffScreen({Key? key, this.clubId}) : super(key: key);

  @override
  State<ClubStaffScreen> createState() => _ClubStaffScreenState();
}

class _ClubStaffScreenState extends State<ClubStaffScreen> {
  final _repo = ClubStaffRepository();
  final _userRepo = UserRepository();
  int _navIndex = 3;
  bool _isLoading = true;
  List<UserClub> _ownerClubs = const [];
  int? _selectedClubId;
  List<_Employee> _employees = [];
  final Map<int, String> _pendingPasswords = {};

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _loadOwnerClubs();
    await _loadStaff();
  }

  Future<void> _loadOwnerClubs() async {
    try {
      final data = await _userRepo.me();
      if (!mounted || data == null) return;

      final clubs = resolveUserClubs(data);
      int? desiredClubId = widget.clubId;
      if (desiredClubId != null && clubs.every((club) => club.id != desiredClubId)) {
        desiredClubId = null;
      }
      desiredClubId ??= _selectedClubId;
      if (desiredClubId == null && clubs.isNotEmpty) {
        desiredClubId = clubs.first.id;
      }

      setState(() {
        _ownerClubs = clubs;
        _selectedClubId = desiredClubId;
      });
    } catch (e) {
      if (mounted) {
        showApiError(context, e);
      }
    }
  }

  Future<void> _loadStaff({int? clubId}) async {
    final id = clubId ?? _selectedClubId;
    if (id == null) {
      if (mounted) {
        setState(() {
          _employees = [];
          _isLoading = false;
        });
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _selectedClubId = id;
    });

    try {
      final data = await _repo.getClubStaff(id);
      if (!mounted) return;

      final club = _clubById(id);
      setState(() {
        _employees = data.map((raw) {
          final item = raw is Map ? Map<String, dynamic>.from(raw as Map) : <String, dynamic>{};
          final userId = (item['userId'] as num?)?.toInt();
          final tempPassword = userId != null ? _pendingPasswords.remove(userId) : null;
          final rawRole = (item['role']?.toString() ?? 'MECHANIC').toUpperCase();
          final roleLabel = _mapRoleToRussian(rawRole);
          final email = (item['email'] as String?)?.trim();
          final phone = (item['phone'] as String?)?.trim();
          final fio = (item['fullName'] as String?)?.trim();
          final isActive = item['isActive'] is bool ? item['isActive'] as bool : true;

          return _Employee(
            userId: userId,
            fio: (fio != null && fio.isNotEmpty) ? fio : 'Без имени',
            workplaces: club != null ? [club.name] : ['Боулинг клуб'],
            address: club?.address ?? '—',
            phone: (phone != null && phone.isNotEmpty) ? phone : '+7 (XXX) XXX-XX-XX',
            roleLabel: roleLabel,
            roleKey: rawRole,
            email: email,
            isActive: isActive,
            isOwner: rawRole == 'OWNER',
            tempPassword: tempPassword,
          );
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        showApiError(context, e);
      }
    }
  }

  UserClub? _clubById(int id) {
    for (final club in _ownerClubs) {
      if (club.id == id) return club;
    }
    return null;
  }

  void _onClubChanged(int? id) {
    if (id == null || id == _selectedClubId) return;
    setState(() {
      _selectedClubId = id;
    });
    _loadStaff(clubId: id);
  }

  String _roleKeyForRequest(String role) {
    final normalized = role.toLowerCase();
    if (normalized.contains('admin') || normalized.contains('админ')) {
      return 'ADMINISTRATOR';
    }
    if (normalized.contains('manager') || normalized.contains('менедж')) {
      return 'MANAGER';
    }
    if (normalized.contains('mechanic') || normalized.contains('механ')) {
      return 'MECHANIC';
    }
    if (normalized.contains('owner') || normalized.contains('влад')) {
      return 'OWNER';
    }
    return role.toUpperCase();
  }

  String _mapRoleToRussian(String role) {
    switch (role) {
      case 'ADMINISTRATOR':
      case 'STAFF':
      case 'ADMIN':
        return 'Администратор';
      case 'HEAD_MECHANIC':
      case 'MANAGER':
        return 'Менеджер';
      case 'MECHANIC':
        return 'Механик';
      case 'CLUB_OWNER':
      case 'OWNER':
        return 'Владелец клуба';
      default:
        return 'Механик';
    }
  }

  InputDecoration _dec({
    String? hint,
    Color? fill,
    bool enabled = true,
    bool focusedRed = false,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      enabled: enabled,
      fillColor: fill ?? AppColors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      suffixIcon: suffix,
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
        borderSide: BorderSide(color: focusedRed ? AppColors.primary : AppColors.primary, width: 1.4),
      ),
    );
  }

  Widget _suffixEdit(VoidCallback? onPressed) {
    return IconButton(
      onPressed: onPressed,
      icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
      splashRadius: 20,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
    );
  }

  Future<void> _openAssignSheet() async {
    if (_ownerClubs.isEmpty) {
      showSnack(context, 'Сначала добавьте клуб');
      return;
    }

    final draft = await showModalBottomSheet<_StaffDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AssignEmployeeSheet(
        dec: _dec,
        suffixEdit: _suffixEdit,
        clubs: _ownerClubs,
        initialClubId: _selectedClubId,
      ),
    );
    if (draft == null) return;

    await _createStaff(draft);
  }

  void _onNavTap(int i) {
    if (_navIndex == i) return;
    setState(() => _navIndex = i);
    switch (i) {
      case 0:
        Navigator.pushReplacementNamed(context, Routes.orders);
        break;
      case 1:
        Navigator.pushReplacementNamed(context, Routes.clubSearch);
        break;
      case 2:
        Navigator.pushReplacementNamed(context, Routes.club);
        break;
      case 3:
        Navigator.pushReplacementNamed(context, Routes.profileMechanic);
        break;
    }
  }

  Future<void> _createStaff(_StaffDraft draft) async {
    final clubId = draft.clubId;

    setState(() {
      _selectedClubId = clubId;
    });

    final normalizedPhone = PhoneUtils.normalize(draft.phone);
    final roleKey = _roleKeyForRequest(draft.role);
    final result = await handleApiCall<Map<String, dynamic>?>(
      context,
      () => _repo.createStaff(
        clubId,
        fullName: draft.fullName,
        phone: normalizedPhone,
        role: roleKey,
        email: draft.email,
      ),
      successMessage: '${draft.role} добавлен',
    );

    if (!mounted || result == null) return;

    final password = result['password']?.toString() ?? '';
    final phone = result['phone']?.toString() ?? normalizedPhone;
    final userId = (result['userId'] as num?)?.toInt();

    if (userId != null && password.isNotEmpty) {
      _pendingPasswords[userId] = password;
    }

    await _loadStaff(clubId: clubId);

    if (!mounted) return;

    if (password.isNotEmpty) {
      await _showCredentialsDialog(phone, password);
    }
  }

  Future<void> _showCredentialsDialog(String phone, String password) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Доступы сотрудника'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Передайте сотруднику данные для входа:'),
            const SizedBox(height: 12),
            Text('Телефон: $phone', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('Пароль: $password', style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Готово')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark),
        ),
        title: const Text('Сотрудники клуба', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textDark)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: () async {
              await _loadOwnerClubs();
              await _loadStaff();
            },
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNav(currentIndex: _navIndex, onTap: _onNavTap),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          if (_ownerClubs.isNotEmpty) ...[
            const Text('Клуб', style: TextStyle(fontSize: 13, color: AppColors.darkGray)),
            const SizedBox(height: 6),
            DropdownButtonFormField<int>(
              value: _selectedClubId,
              items: _ownerClubs
                  .map((club) => DropdownMenuItem(value: club.id, child: Text(club.name)))
                  .toList(),
              onChanged: _onClubChanged,
              decoration: _dec(),
            ),
            const SizedBox(height: 16),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.lightGray),
              ),
              child: const Text(
                'Добавьте клуб в профиле владельца, чтобы назначать сотрудников.',
                style: TextStyle(color: AppColors.darkGray),
              ),
            ),
            const SizedBox(height: 16),
          ],
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _ownerClubs.isEmpty ? null : _openAssignSheet,
              icon: const Icon(Icons.add, color: AppColors.white),
              label: const Text('Назначить сотрудника'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkGray,
                foregroundColor: AppColors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ..._employees.map((e) => _EmployeeCard(
            key: ValueKey(e.userId ?? e.fio),
            employee: e,
            dec: _dec,
            suffixEdit: _suffixEdit,
            onDelete: () => setState(() => _employees.remove(e)),
            onChangeRole: (v) => setState(() {
              e.roleLabel = v;
              e.roleKey = _roleKeyForRequest(v);
            }),
          )),
        ],
      ),
    );
  }
}

class _Employee {
  int? userId;
  String fio;
  List<String> workplaces;
  String address;
  String phone;
  String roleLabel;
  String roleKey;
  String? email;
  bool isActive;
  bool isOwner;
  String? tempPassword;

  bool get canModify => !isOwner;

  _Employee({
    this.userId,
    required this.fio,
    required this.workplaces,
    required this.address,
    required this.phone,
    required this.roleLabel,
    required this.roleKey,
    this.email,
    this.isActive = true,
    this.isOwner = false,
    this.tempPassword,
  });
}

class _StaffDraft {
  final String fullName;
  final String phone;
  final String? email;
  final String role;
  final int clubId;
  final String clubName;

  const _StaffDraft({
    required this.fullName,
    required this.phone,
    required this.role,
    required this.clubId,
    required this.clubName,
    this.email,
  });
}

class _EmployeeCard extends StatefulWidget {
  final _Employee employee;
  final InputDecoration Function({String? hint, Color? fill, bool enabled, bool focusedRed, Widget? suffix}) dec;
  final Widget Function(VoidCallback? onPressed) suffixEdit;
  final VoidCallback onDelete;
  final ValueChanged<String> onChangeRole;

  const _EmployeeCard({
    Key? key,
    required this.employee,
    required this.dec,
    required this.suffixEdit,
    required this.onDelete,
    required this.onChangeRole,
  }) : super(key: key);

  @override
  State<_EmployeeCard> createState() => _EmployeeCardState();
}

class _EmployeeCardState extends State<_EmployeeCard> {
  late final TextEditingController _fio;
  late final TextEditingController _addr;
  late final TextEditingController _phone;
  late final List<TextEditingController> _works;

  @override
  void initState() {
    super.initState();
    _fio = TextEditingController(text: widget.employee.fio);
    _addr = TextEditingController(text: widget.employee.address);
    _phone = TextEditingController(text: widget.employee.phone);
    _works = widget.employee.workplaces.map((w) => TextEditingController(text: w)).toList();
  }

  @override
  void dispose() {
    _fio.dispose();
    _addr.dispose();
    _phone.dispose();
    for (final c in _works) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ФИО', style: TextStyle(fontSize: 13, color: AppColors.darkGray)),
            const SizedBox(height: 6),
            TextField(
              controller: _fio,
              enabled: widget.employee.canModify,
              decoration: widget.dec(
                focusedRed: true,
                suffix: widget.suffixEdit(widget.employee.canModify ? () {} : null),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Место работы', style: TextStyle(fontSize: 13, color: AppColors.darkGray)),
            const SizedBox(height: 6),
            ...List.generate(_works.length, (i) {
              final isLast = i == _works.length - 1;
              return Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _works[i],
                        enabled: widget.employee.canModify,
                        decoration: widget.dec(hint: 'Боулинг клуб', enabled: widget.employee.canModify),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 44,
                      width: 44,
                      child: ElevatedButton(
                        onPressed: widget.employee.canModify ? () {} : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: AppColors.lightGray),
                          ),
                        ),
                        child: const Icon(Icons.add, color: AppColors.textDark),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 12),
            TextField(
              controller: _addr,
              enabled: widget.employee.canModify,
              decoration: widget.dec(
                hint: 'г. Воронеж, ул. Тверская, д. 45',
                enabled: widget.employee.canModify,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Номер телефона', style: TextStyle(fontSize: 13, color: AppColors.darkGray)),
            const SizedBox(height: 6),
            TextField(
              controller: _phone,
              enabled: widget.employee.canModify,
              decoration: widget.dec(
                fill: const Color(0xFFF0DADF),
                suffix: widget.suffixEdit(widget.employee.canModify ? () {} : null),
                enabled: widget.employee.canModify,
              ),
            ),
            if (widget.employee.email != null && widget.employee.email!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Email', style: TextStyle(fontSize: 13, color: AppColors.darkGray)),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.lightGray),
                ),
                child: Text(
                  widget.employee.email!,
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Text('Статус:', style: TextStyle(fontSize: 13, color: AppColors.darkGray)),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: RadioGroupHorizontal(
                options: widget.employee.isOwner
                    ? const ['Владелец клуба']
                    : const ['Механик', 'Менеджер', 'Администратор'],
                groupValue: widget.employee.isOwner ? 'Владелец клуба' : widget.employee.roleLabel,
                onChanged: widget.employee.canModify
                    ? (v) {
                        if (v == null) return;
                        widget.onChangeRole(v);
                        setState(() {});
                      }
                    : (_) {},
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  widget.employee.isActive ? Icons.check_circle_outline : Icons.remove_circle_outline,
                  color: widget.employee.isActive ? const Color(0xFF2E7D32) : const Color(0xFFB00020),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.employee.isActive ? 'Аккаунт активен' : 'Аккаунт отключен',
                  style: const TextStyle(fontSize: 13, color: AppColors.darkGray),
                ),
              ],
            ),
            if (widget.employee.tempPassword != null && widget.employee.tempPassword!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.lightGray),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Пароль для входа', style: TextStyle(fontSize: 13, color: AppColors.darkGray)),
                    const SizedBox(height: 6),
                    Text(
                      widget.employee.tempPassword!,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.employee.canModify ? widget.onDelete : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(widget.employee.canModify ? 'Удалить сотрудника' : 'Удаление недоступно'),
              ),
            ),
            if (!widget.employee.canModify) ...[
              const SizedBox(height: 6),
              const Text(
                'Владелец клуба не может быть удалён из списка сотрудников.',
                style: TextStyle(fontSize: 12, color: AppColors.darkGray),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AssignEmployeeSheet extends StatefulWidget {
  final InputDecoration Function({String? hint, Color? fill, bool enabled, bool focusedRed, Widget? suffix}) dec;
  final Widget Function(VoidCallback? onPressed) suffixEdit;
  final List<UserClub> clubs;
  final int? initialClubId;

  const _AssignEmployeeSheet({
    Key? key,
    required this.dec,
    required this.suffixEdit,
    required this.clubs,
    this.initialClubId,
  }) : super(key: key);

  @override
  State<_AssignEmployeeSheet> createState() => _AssignEmployeeSheetState();
}

class _AssignEmployeeSheetState extends State<_AssignEmployeeSheet> {
  final _fio = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  String _role = 'Менеджер';
  int? _selectedClubId;
  String? _clubError;

  @override
  void initState() {
    super.initState();
    _selectedClubId = widget.initialClubId ?? (widget.clubs.isNotEmpty ? widget.clubs.first.id : null);
  }

  @override
  void dispose() {
    _fio.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _fio.text.trim();
    final phone = _phone.text.trim();
    if (name.isEmpty || phone.isEmpty) return;
    UserClub? club;
    if (_selectedClubId != null) {
      for (final c in widget.clubs) {
        if (c.id == _selectedClubId) {
          club = c;
          break;
        }
      }
    }
    club ??= widget.clubs.isNotEmpty ? widget.clubs.first : null;
    if (club == null) {
      setState(() => _clubError = 'Выберите клуб');
      return;
    }
    final draft = _StaffDraft(
      fullName: name,
      phone: phone,
      email: _email.text.trim().isEmpty ? null : _email.text.trim(),
      role: _role,
      clubId: club.id,
      clubName: club.name,
    );
    Navigator.pop(context, draft);
  }

  @override
  Widget build(BuildContext context) {
    final dec = widget.dec;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: ListView(
          controller: controller,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Назначить сотрудника', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                ),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: AppColors.textDark)),
              ],
            ),
            const SizedBox(height: 8),
            const Text('ФИО', style: TextStyle(fontSize: 13, color: AppColors.darkGray)),
            const SizedBox(height: 6),
            TextField(controller: _fio, decoration: dec(focusedRed: true, suffix: widget.suffixEdit(() {}))),
            const SizedBox(height: 16),
            const Text('Клуб', style: TextStyle(fontSize: 13, color: AppColors.darkGray)),
            const SizedBox(height: 6),
            DropdownButtonFormField<int>(
              value: _selectedClubId,
              items: widget.clubs
                  .map((club) => DropdownMenuItem(value: club.id, child: Text(club.name)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedClubId = value;
                  _clubError = null;
                });
              },
              decoration: dec(),
            ),
            if (_clubError != null) ...[
              const SizedBox(height: 4),
              Text(_clubError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
            ],
            const SizedBox(height: 16),
            const Text('Номер телефона', style: TextStyle(fontSize: 13, color: AppColors.darkGray)),
            const SizedBox(height: 6),
            TextField(controller: _phone, decoration: dec(suffix: widget.suffixEdit(() {}))),
            const SizedBox(height: 16),
            const Text('Email', style: TextStyle(fontSize: 13, color: AppColors.darkGray)),
            const SizedBox(height: 6),
            TextField(
              controller: _email,
              decoration: dec(hint: 'email@example.com'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            const Text('Ваш статус:', style: TextStyle(fontSize: 13, color: AppColors.darkGray)),
            const SizedBox(height: 8),
            RadioGroupHorizontal(
              options: const ['Механик', 'Менеджер', 'Администратор'],
              groupValue: _role,
              onChanged: (v) => setState(() => _role = v ?? _role),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Назначить сотрудника', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
