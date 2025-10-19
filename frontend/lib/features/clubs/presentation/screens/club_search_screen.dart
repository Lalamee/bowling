import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../shared/widgets/inputs/adaptive_text.dart';
import '../../../../core/repositories/parts_repository.dart';
import '../../../../core/utils/net_ui.dart';

class ClubSearchScreen extends StatefulWidget {
  final String query;
  const ClubSearchScreen({Key? key, this.query = ''}) : super(key: key);

  @override
  State<ClubSearchScreen> createState() => _ClubSearchScreenState();
}

class _ClubSearchScreenState extends State<ClubSearchScreen> {
  final _ctrl = TextEditingController();
  final _repo = PartsRepository();
  List<dynamic> _parts = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _ctrl.text = widget.query;
    _loadParts();
  }

  Future<void> _loadParts() async {
    setState(() => _isLoading = true);
    try {
      final data = await _repo.all();
      if (mounted) {
        setState(() {
          _parts = data;
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

  Future<void> _searchParts() async {
    final query = _ctrl.text.trim();
    if (query.isEmpty) {
      _loadParts();
      return;
    }

    setState(() => _isLoading = true);
    try {
      final data = await _repo.search(query);
      if (mounted) {
        setState(() {
          _parts = data;
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

  List<String> get _filtered {
    return _parts
        .map((p) => (p is Map ? (p['partName'] ?? p['name'] ?? '') : p.toString()))
        .where((s) => s.isNotEmpty)
        .cast<String>()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 56,
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.primary, width: 1.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      onChanged: (_) => _searchParts(),
                      decoration: const InputDecoration(
                        hintText: 'Поиск по складу',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(onPressed: _loadParts, icon: const Icon(Icons.refresh, color: AppColors.primary)),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filtered.isEmpty
                      ? const Center(child: Text('Нет результатов', style: TextStyle(color: AppColors.darkGray)))
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemBuilder: (_, i) {
                            final item = _filtered[i];
                            final accent = i == 0;
                            return InkWell(
                              onTap: () => Navigator.pop(context, item),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                height: 44,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                alignment: Alignment.centerLeft,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: accent ? AppColors.primary : const Color(0xFFEDEDED), width: 1.5),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: AdaptiveText(
                                        item,
                                        style: const TextStyle(fontSize: 14, color: AppColors.textDark, fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                    if (accent) const Icon(Icons.edit, size: 16, color: AppColors.primary),
                                  ],
                                ),
                              ),
                            );
                          },
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemCount: _filtered.length,
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
