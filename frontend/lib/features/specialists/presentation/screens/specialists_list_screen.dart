import 'package:flutter/material.dart';

import '../../../../../core/repositories/specialists_repository.dart';
import '../../../../../models/mechanic_directory_models.dart';
import 'specialist_detail_screen.dart';

class SpecialistsListScreen extends StatefulWidget {
  const SpecialistsListScreen({super.key});

  @override
  State<SpecialistsListScreen> createState() => _SpecialistsListScreenState();
}

class _SpecialistsListScreenState extends State<SpecialistsListScreen> {
  final SpecialistsRepository _repository = SpecialistsRepository();
  final TextEditingController _queryCtrl = TextEditingController();
  final TextEditingController _regionCtrl = TextEditingController();
  final TextEditingController _certCtrl = TextEditingController();

  Future<List<MechanicDirectoryItem>>? _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _queryCtrl.dispose();
    _regionCtrl.dispose();
    _certCtrl.dispose();
    super.dispose();
  }

  void _load() {
    setState(() {
      _future = _repository.search(
        query: _queryCtrl.text,
        region: _regionCtrl.text,
        certification: _certCtrl.text,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Специалисты (база техников)')),
      body: RefreshIndicator(
        onRefresh: () async => _load(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildFilters(),
            const SizedBox(height: 12),
            FutureBuilder<List<MechanicDirectoryItem>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Text('Не удалось загрузить список специалистов');
                }
                final data = snapshot.data ?? [];
                if (data.isEmpty) {
                  return const Text('База специалистов пока пуста или не найдено по фильтрам');
                }
                return Column(
                  children: data.map(_buildTile).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _queryCtrl,
          decoration: const InputDecoration(
            labelText: 'Поиск по ФИО или навыкам',
            prefixIcon: Icon(Icons.search),
          ),
          onSubmitted: (_) => _load(),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _regionCtrl,
          decoration: const InputDecoration(
            labelText: 'Регион (TODO поле в анкете)',
            prefixIcon: Icon(Icons.place_outlined),
          ),
          onSubmitted: (_) => _load(),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _certCtrl,
          decoration: const InputDecoration(
            labelText: 'Квалификация / сертификация (TODO)',
            prefixIcon: Icon(Icons.verified_outlined),
          ),
          onSubmitted: (_) => _load(),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.filter_alt),
            label: const Text('Применить'),
          ),
        ),
      ],
    );
  }

  Widget _buildTile(MechanicDirectoryItem item) {
    final subtitleParts = <String>[];
    if (item.specialization != null && item.specialization!.isNotEmpty) {
      subtitleParts.add(item.specialization!);
    }
    if (item.region != null && item.region!.isNotEmpty) {
      subtitleParts.add('Регион: ${item.region}');
    }
    if (item.clubs.isNotEmpty) {
      subtitleParts.add('Клубы: ${item.clubs.join(', ')}');
    }
    return Card(
      child: ListTile(
        title: Text(item.fullName ?? 'Без имени'),
        subtitle: subtitleParts.isNotEmpty ? Text(subtitleParts.join(' • ')) : null,
        trailing: item.rating != null ? Text('★ ${item.rating!.toStringAsFixed(1)}') : null,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SpecialistDetailScreen(profileId: item.profileId),
            ),
          );
        },
      ),
    );
  }
}

