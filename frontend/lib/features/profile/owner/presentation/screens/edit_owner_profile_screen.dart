import '../../../../../core/repositories/user_repository.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/colors.dart';
import '../../domain/owner_profile.dart';
import '../../../../../shared/widgets/chips/radio_group_horizontal.dart';
import 'owner_profile_screen.dart' show OwnerEditFocus;

class EditOwnerProfileScreen extends StatefulWidget {
  final OwnerProfile? initial;
  final OwnerEditFocus focus;

  const EditOwnerProfileScreen({
    Key? key,
    this.initial,
    this.focus = OwnerEditFocus.none,
  }) : super(key: key);

  @override
  State<EditOwnerProfileScreen> createState() => _EditOwnerProfileScreenState();
}

class _EditOwnerProfileScreenState extends State<EditOwnerProfileScreen> {
  final UserRepository _repo = UserRepository();
  String fullName = '—';
  String phone = '—';
  String email = '';
  final _fio = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _birth = TextEditingController();

  final List<TextEditingController> _clubCtrls = [];

  final _fioFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _addrFocus = FocusNode();

  String _status = 'Собственник';
  int _navIndex = 3;

  @override
  void initState() {
    super.initState();

    final p = widget.initial;
    if (p != null) {
      _fio.text = p.fullName;
      _address.text = p.address;
      _phone.text = p.phone;
      _birth.text = DateFormat('dd.MM.yyyy').format(p.birthDate);
      _status = p.status;
      final clubs = (p.clubs.isEmpty ? [p.clubName] : p.clubs);
      for (final c in clubs) {
        _clubCtrls.add(TextEditingController(text: c));
      }
    } else {
      _clubCtrls.add(TextEditingController());
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      switch (widget.focus) {
        case OwnerEditFocus.name:
          _fioFocus.requestFocus();
          break;
        case OwnerEditFocus.phone:
          _phoneFocus.requestFocus();
          break;
        case OwnerEditFocus.address:
          _addrFocus.requestFocus();
          break;
        case OwnerEditFocus.none:
          break;
      }
    });
    
    _load();
  }

  Future<void> _load() async {
    final me = await _repo.me();
    if (mounted) {
      setState(() {
        fullName = (me?['fullName'] ?? me?['phone'] ?? 'Профиль').toString();
        phone = (me?['phone'] ?? '—').toString();
        email = (me?['email'] ?? '').toString();
      });
    }
  }

  @override
  void dispose() {
    _fio.dispose();
    _address.dispose();
    _phone.dispose();
    _birth.dispose();
    for (final c in _clubCtrls) c.dispose();
    _fioFocus.dispose();
    _phoneFocus.dispose();
    _addrFocus.dispose();
    super.dispose();
  }

  InputDecoration _dec({String? hint, Color? fill}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: fill ?? AppColors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
        borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
      ),
    );
  }

  void _addClubField() {
    setState(() => _clubCtrls.add(TextEditingController()));
  }

  void _removeClubField(int i) {
    if (_clubCtrls.length <= 1) return;
    setState(() {
      final ctrl = _clubCtrls.removeAt(i);
      ctrl.dispose();
    });
  }

  Future<void> _pickBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Выберите дату рождения',
      locale: const Locale('ru'),
    );
    if (picked != null) {
      _birth.text = DateFormat('dd.MM.yyyy').format(picked);
    }
  }

  void _saveAndPop() {
    if (widget.initial == null) {
      Navigator.pop(context);
      return;
    }
    final clubs = _clubCtrls.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();
    final clubName = clubs.isNotEmpty ? clubs.first : '';
    final updated = widget.initial!.copyWith(
      fullName: _fio.text.trim(),
      address: _address.text.trim(),
      phone: _phone.text.trim(),
      clubName: clubName,
      clubs: clubs,
      status: _status,
      birthDate: DateFormat('dd.MM.yyyy').parse(_birth.text),
    );
    Navigator.pop(context, updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,
        leading: IconButton(
          onPressed: _saveAndPop,
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark),
        ),
        title: const Text(
          'Персональная информация',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textDark),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const SizedBox(height: 6),
          const Text(
            'Для редактирования информации нажмите на поле ввода',
            style: TextStyle(fontSize: 13, color: AppColors.darkGray),
          ),
          const SizedBox(height: 18),

          const Text('ФИО', style: TextStyle(fontSize: 13, color: AppColors.darkGray)),
          const SizedBox(height: 6),
          TextField(controller: _fio, focusNode: _fioFocus, decoration: _dec()),
          const SizedBox(height: 16),

          const Text('Место работы', style: TextStyle(fontSize: 13, color: AppColors.darkGray)),
          const SizedBox(height: 6),
          ...List.generate(_clubCtrls.length, (i) {
            final isLast = i == _clubCtrls.length - 1;
            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
              child: Row(
                children: [
                  Expanded(child: TextField(controller: _clubCtrls[i], decoration: _dec(hint: 'Боулинг клуб'))),
                  const SizedBox(width: 8),
                  if (_clubCtrls.length > 1)
                    SizedBox(
                      height: 48,
                      width: 48,
                      child: ElevatedButton(
                        onPressed: () => _removeClubField(i),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.white,
                          foregroundColor: AppColors.primary,
                          elevation: 0,
                          side: const BorderSide(color: AppColors.lightGray),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: EdgeInsets.zero,
                        ),
                        child: const Icon(Icons.remove),
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
              onPressed: _addClubField,
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
          const SizedBox(height: 12),

          const Text('Адрес', style: TextStyle(fontSize: 13, color: AppColors.darkGray)),
          const SizedBox(height: 6),
          TextField(controller: _address, focusNode: _addrFocus, decoration: _dec(hint: 'г. Воронеж, ул. Тверская, д. 45')),
          const SizedBox(height: 16),

          const Text('Ваш статус:', style: TextStyle(fontSize: 13, color: AppColors.darkGray)),
          const SizedBox(height: 8),
          RadioGroupHorizontal(
            options: const ['Собственник', 'Механик'],
            groupValue: _status,
            onChanged: (v) => setState(() => _status = v ?? _status),
          ),
          const SizedBox(height: 20),

          const SizedBox(height: 18),

          const Text('Дата рождения', style: TextStyle(fontSize: 13, color: AppColors.darkGray)),
          const SizedBox(height: 6),
          TextField(controller: _birth, readOnly: true, onTap: _pickBirth, decoration: _dec()),
          const SizedBox(height: 12),

          const Text('Номер телефона', style: TextStyle(fontSize: 13, color: AppColors.darkGray)),
          const SizedBox(height: 6),
          TextField(controller: _phone, focusNode: _phoneFocus, readOnly: true, decoration: _dec(fill: const Color(0xFFF0DADF))),
          const SizedBox(height: 8),

          const Text(
            'Чтобы изменить номер телефона, обратитесь в службу поддержки 8 800 000 00 00.',
            style: TextStyle(fontSize: 13, color: AppColors.darkGray),
          ),
          const SizedBox(height: 28),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.darkGray,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Заказы'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Поиск'),
          BottomNavigationBarItem(icon: Icon(Icons.storefront_outlined), label: 'Клуб'),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle_outlined), label: 'Профиль'),
        ],
      ),
    );
  }
}
