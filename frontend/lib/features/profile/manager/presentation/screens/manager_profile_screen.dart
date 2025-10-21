import '../../../../../core/repositories/user_repository.dart';
import 'package:flutter/material.dart';
import '../../../../../core/theme/colors.dart';
import '../../../../../shared/widgets/tiles/profile_tile.dart';
import '../../../../knowledge_base/presentation/screens/knowledge_base_screen.dart';
import '../../../../../shared/widgets/nav/app_bottom_nav.dart';
import '../../../../../core/utils/bottom_nav.dart';
import '../../../../../core/routing/routes.dart';

class ManagerProfileScreen extends StatefulWidget {
  const ManagerProfileScreen({Key? key}) : super(key: key);

  @override
  State<ManagerProfileScreen> createState() => _ManagerProfileScreenState();
}

class _ManagerProfileScreenState extends State<ManagerProfileScreen> {
  final UserRepository _repo = UserRepository();
  String fullName = '—';
  String phone = '—';
  String email = '';
  String clubName = '—';
  String address = '—';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final me = await _repo.me();
    if (!mounted) return;

    setState(() {
      fullName = _asString(me?['fullName']) ?? _asString(me?['phone']) ?? fullName;
      phone = _asString(me?['phone']) ?? phone;
      email = _asString(me?['email']) ?? email;

      final ownerProfile = me?['ownerProfile'];
      final mechanicProfile = me?['mechanicProfile'];
      final managerProfile = me?['managerProfile'];

      if (managerProfile is Map) {
        final map = Map<String, dynamic>.from(managerProfile);
        fullName = _asString(map['fullName']) ?? fullName;
        phone = _asString(map['contactPhone']) ?? phone;
        email = _asString(map['contactEmail']) ?? email;
      }

      final clubs = _resolveClubs([ownerProfile, mechanicProfile, managerProfile, me]);
      if (clubs.isNotEmpty) {
        clubName = clubs.first;
      }

      if (managerProfile is Map) {
        final map = Map<String, dynamic>.from(managerProfile);
        final managerClub = _asString(map['clubName']);
        if (managerClub != null && managerClub.isNotEmpty) {
          clubName = managerClub;
        }
      }

      final resolvedAddress = _resolveAddress([managerProfile, ownerProfile, mechanicProfile, me]);
      if (resolvedAddress != null) {
        address = resolvedAddress;
      }
    });
  }

  String? _asString(dynamic value) {
    if (value == null) return null;
    final str = value.toString().trim();
    return str.isEmpty ? null : str;
  }

  List<String> _resolveClubs(List<dynamic> sources) {
    final result = <String>[];
    final seen = <String>{};

    for (final source in sources) {
      if (source is Map) {
        final map = Map<String, dynamic>.from(source);
        final clubName = _asString(map['clubName']);
        if (clubName != null && seen.add(clubName)) {
          result.add(clubName);
        }

        final clubs = map['clubs'];
        if (clubs is Iterable) {
          for (final club in clubs) {
            final value = _asString(club);
            if (value != null && seen.add(value)) {
              result.add(value);
            }
          }
        } else if (clubs is String) {
          for (final part in clubs.split(',')) {
            final value = _asString(part);
            if (value != null && seen.add(value)) {
              result.add(value);
            }
          }
        }
      }
    }

    return result;
  }

  String? _resolveAddress(List<dynamic> sources) {
    for (final source in sources) {
      if (source is Map) {
        final map = Map<String, dynamic>.from(source);
        final value = _asString(map['address']);
        if (value != null) {
          return value;
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Личный кабинет', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textDark)),
        centerTitle: false,
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.sync), color: AppColors.primary)],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          ProfileTile(icon: Icons.person, text: fullName, onEdit: () {}),
          const SizedBox(height: 10),
          ProfileTile(icon: Icons.phone, text: phone, onEdit: () {}),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 10),
            ProfileTile(icon: Icons.email_outlined, text: email, onEdit: () {}),
          ],
          const SizedBox(height: 10),
          ProfileTile(icon: Icons.menu_book_rounded, text: 'База знаний', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KnowledgeBaseScreen()))),
          const SizedBox(height: 10),
          ProfileTile(icon: Icons.location_searching_rounded, text: clubName, onTap: () {}),
          const SizedBox(height: 10),
          ProfileTile(icon: Icons.location_on_rounded, text: address, onEdit: () {}),
          const SizedBox(height: 10),
          ProfileTile(icon: Icons.history_rounded, text: 'История заказов', onTap: () => Navigator.pushNamed(context, Routes.managerOrdersHistory)),
          const SizedBox(height: 10),
          ProfileTile(icon: Icons.notifications_active_outlined, text: 'Оповещения', onTap: () => Navigator.pushNamed(context, Routes.managerNotifications)),
          const SizedBox(height: 10),
          ProfileTile(icon: Icons.exit_to_app_rounded, text: 'Выход', danger: true, onTap: () {}),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 3,
        onTap: (i) => BottomNavDirect.go(context, 3, i),
      ),
    );
  }
}
