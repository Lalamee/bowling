import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DebugPanel extends StatefulWidget {
  const DebugPanel({super.key});

  @override
  State<DebugPanel> createState() => _DebugPanelState();
}

class _DebugPanelState extends State<DebugPanel> {
  bool firstRun = false;
  bool loggedIn = false;
  String role = 'mechanic';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sp = await SharedPreferences.getInstance();
    setState(() {
      firstRun = !(sp.getBool('first_run_done') ?? false);
      loggedIn = sp.getBool('logged_in') ?? false;
      role = sp.getString('user_role') ?? 'mechanic';
    });
  }

  Future<void> _apply() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool('first_run_done', !firstRun);
    await sp.setBool('logged_in', loggedIn);
    await sp.setString('user_role', role);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Первый запуск'),
              value: firstRun,
              onChanged: (v) => setState(() => firstRun = v),
            ),
            SwitchListTile(
              title: const Text('Вход выполнен'),
              value: loggedIn,
              onChanged: (v) => setState(() => loggedIn = v),
            ),
            DropdownButtonFormField<String>(
              value: role,
              items: const [
                DropdownMenuItem(value: 'mechanic', child: Text('Механик')),
                DropdownMenuItem(value: 'owner', child: Text('Владелец')),
              ],
              onChanged: (v) => setState(() => role = v ?? 'mechanic'),
              decoration: const InputDecoration(labelText: 'Роль'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _apply, child: const Text('Apply')),
          ],
        ),
      ),
    );
  }
}
