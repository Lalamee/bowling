import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../shared/widgets/chips/radio_group_horizontal.dart';
import '../../../../shared/widgets/nav/app_bottom_nav.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/repositories/club_staff_repository.dart';
import '../../../../core/utils/net_ui.dart';

class ClubStaffScreen extends StatefulWidget {
  final int? clubId;
  
  const ClubStaffScreen({Key? key, this.clubId}) : super(key: key);

  @override
  State<ClubStaffScreen> createState() => _ClubStaffScreenState();
}

class _ClubStaffScreenState extends State<ClubStaffScreen> {
  final _repo = ClubStaffRepository();
  int _navIndex = 3;
  bool _isLoading = true;
  List<_Employee> _employees = [];

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    if (widget.clubId == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final data = await _repo.getClubStaff(widget.clubId!);
      if (mounted) {
        setState(() {
          _employees = data.map((item) {
            return _Employee(
              userId: item['userId'],
              fio: item['fullName'] ?? 'Без имени',
              workplaces: ['Боулинг клуб'],
              address: 'г. Воронеж, ул. Тверская, д. 45',
              phone: item['phone'] ?? '+7 (XXX) XXX-XX-XX',
              role: _mapRoleToRussian(item['role'] ?? 'MECHANIC'),
            );
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        showApiError(context, e);
      }
    }
  }

  String _mapRoleToRussian(String role) {
    switch (role) {
      case 'MANAGER':
        return 'Менеджер';
      case 'MECHANIC':
        return 'Механик';
      case 'OWNER':
        return 'Владелец';
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

  Widget _suffixEdit(VoidCallback onPressed) {
    return IconButton(
      onPressed: onPressed,
      icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
      splashRadius: 20,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
    );
  }

  Future<void> _openAssignSheet() async {
    final result = await showModalBottomSheet<_Employee>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AssignEmployeeSheet(dec: _dec, suffixEdit: _suffixEdit),
    );
    if (result != null) {
      setState(() => _employees.add(result));
    }
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
            onPressed: _loadStaff,
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNav(currentIndex: _navIndex, onTap: _onNavTap),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _openAssignSheet,
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
            key: ValueKey(e.fio),
            employee: e,
            dec: _dec,
            suffixEdit: _suffixEdit,
            onDelete: () => setState(() => _employees.remove(e)),
            onChangeRole: (v) => setState(() => e.role = v),
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
  String role;

  _Employee({
    this.userId,
    required this.fio,
    required this.workplaces,
    required this.address,
    required this.phone,
    required this.role,
  });
}

class _EmployeeCard extends StatefulWidget {
  final _Employee employee;
  final InputDecoration Function({String? hint, Color? fill, bool enabled, bool focusedRed, Widget? suffix}) dec;
  final Widget Function(VoidCallback onPressed) suffixEdit;
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
              decoration: widget.dec(focusedRed: true, suffix: widget.suffixEdit(() {})),
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
                    Expanded(child: TextField(controller: _works[i], decoration: widget.dec(hint: 'Боулинг клуб'))),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 44,
                      width: 44,
                      child: ElevatedButton(
                        onPressed: () {},
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
            TextField(controller: _addr, decoration: widget.dec(hint: 'г. Воронеж, ул. Тверская, д. 45')),
            const SizedBox(height: 16),
            const Text('Номер телефона', style: TextStyle(fontSize: 13, color: AppColors.darkGray)),
            const SizedBox(height: 6),
            TextField(controller: _phone, decoration: widget.dec(fill: const Color(0xFFF0DADF), suffix: widget.suffixEdit(() {}))),
            const SizedBox(height: 16),
            const Text('Статус:', style: TextStyle(fontSize: 13, color: AppColors.darkGray)),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: RadioGroupHorizontal(
                options: const ['Менеджер', 'Механик'],
                groupValue: widget.employee.role,
                onChanged: (v) {
                  if (v == null) return;
                  widget.onChangeRole(v);
                  setState(() {});
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.onDelete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Удалить сотрудника'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssignEmployeeSheet extends StatefulWidget {
  final InputDecoration Function({String? hint, Color? fill, bool enabled, bool focusedRed, Widget? suffix}) dec;
  final Widget Function(VoidCallback onPressed) suffixEdit;

  const _AssignEmployeeSheet({Key? key, required this.dec, required this.suffixEdit}) : super(key: key);

  @override
  State<_AssignEmployeeSheet> createState() => _AssignEmployeeSheetState();
}

class _AssignEmployeeSheetState extends State<_AssignEmployeeSheet> {
  final _fio = TextEditingController(text: 'Менеджер Иван Иванович');
  final _phone = TextEditingController(text: '+7 (980) 001 01 01');
  final List<TextEditingController> _work = [TextEditingController(text: 'Боулинг клуб "Кегли"')];
  String _role = 'Менеджер';

  @override
  void dispose() {
    _fio.dispose();
    _phone.dispose();
    for (final c in _work) c.dispose();
    super.dispose();
  }

  void _addWork() {
    setState(() => _work.add(TextEditingController()));
  }

  void _removeWork(int i) {
    if (_work.length <= 1) return;
    setState(() {
      final c = _work.removeAt(i);
      c.dispose();
    });
  }

  void _submit() {
    if (_fio.text.trim().isEmpty) return;
    final emp = _Employee(
      fio: _fio.text.trim(),
      workplaces: _work.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList(),
      address: 'г. Воронеж, ул. Тверская, д. 45',
      phone: _phone.text.trim(),
      role: _role,
    );
    Navigator.pop(context, emp);
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
            const Text('Место работы', style: TextStyle(fontSize: 13, color: AppColors.darkGray)),
            const SizedBox(height: 6),
            ...List.generate(_work.length, (i) {
              final isLast = i == _work.length - 1;
              return Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
                child: Row(
                  children: [
                    Expanded(child: TextField(controller: _work[i], decoration: dec(hint: 'Боулинг клуб'))),
                    const SizedBox(width: 8),
                    if (_work.length > 1)
                      SizedBox(
                        height: 44,
                        width: 44,
                        child: ElevatedButton(
                          onPressed: () => _removeWork(i),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: AppColors.lightGray),
                            ),
                          ),
                          child: const Icon(Icons.remove, color: AppColors.textDark),
                        ),
                      ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _addWork,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.white,
                  foregroundColor: AppColors.primary,
                  elevation: 0,
                  side: const BorderSide(color: AppColors.lightGray),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add),
                    SizedBox(width: 8),
                    Text('Добавить клуб'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Номер телефона', style: TextStyle(fontSize: 13, color: AppColors.darkGray)),
            const SizedBox(height: 6),
            TextField(controller: _phone, decoration: dec(suffix: widget.suffixEdit(() {}))),
            const SizedBox(height: 16),
            const Text('Ваш статус:', style: TextStyle(fontSize: 13, color: AppColors.darkGray)),
            const SizedBox(height: 8),
            RadioGroupHorizontal(
              options: const ['Механик', 'Менеджер'],
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
