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
  final TextEditingController _regionCtrl = TextEditingController();
  final TextEditingController _specializationCtrl = TextEditingController();
  final TextEditingController _ratingCtrl = TextEditingController(text: '0');
  MechanicGrade? _grade;

  Future<List<SpecialistCard>>? _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _regionCtrl.dispose();
    _specializationCtrl.dispose();
    _ratingCtrl.dispose();
    super.dispose();
  }

  void _load() {
    setState(() {
      final specializationId = int.tryParse(_specializationCtrl.text.trim());
      final rating = double.tryParse(_ratingCtrl.text.trim());
      _future = _repository.specialistBase(
        region: _regionCtrl.text,
        specializationId: specializationId,
        grade: _grade,
        minRating: rating,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('База аттестованных специалистов')),
      body: RefreshIndicator(
        onRefresh: () async => _load(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildFilters(),
            const SizedBox(height: 12),
            FutureBuilder<List<SpecialistCard>>(
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
          controller: _regionCtrl,
          decoration: const InputDecoration(
            labelText: 'Регион',
            prefixIcon: Icon(Icons.place_outlined),
          ),
          onSubmitted: (_) => _load(),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _specializationCtrl,
          decoration: const InputDecoration(
            labelText: 'ID специализации',
            prefixIcon: Icon(Icons.build_circle_outlined),
          ),
          keyboardType: TextInputType.number,
          onSubmitted: (_) => _load(),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<MechanicGrade?>(
          value: _grade,
          decoration: const InputDecoration(
            labelText: 'Подтверждённый грейд',
            prefixIcon: Icon(Icons.verified_outlined),
          ),
          items: [
            const DropdownMenuItem<MechanicGrade?>(value: null, child: Text('Любой')),
            ...MechanicGrade.values
                .map((g) => DropdownMenuItem<MechanicGrade?>(
                      value: g,
                      child: Text(g.toApiValue()),
                    ))
                .toList(),
          ],
          onChanged: (value) => setState(() => _grade = value),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _ratingCtrl,
          decoration: const InputDecoration(
            labelText: 'Мин. рейтинг',
            prefixIcon: Icon(Icons.star_half),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
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

  Widget _buildTile(SpecialistCard item) {
    final subtitleParts = <String>[];
    if (item.attestedGrade != null) subtitleParts.add('Грейд: ${item.attestedGrade!.toApiValue()}');
    if (item.region != null && item.region!.isNotEmpty) subtitleParts.add('Регион: ${item.region}');
    if (item.totalExperienceYears != null) subtitleParts.add('Стаж: ${item.totalExperienceYears} лет');
    if (item.skills != null && item.skills!.isNotEmpty) subtitleParts.add(item.skills!);
    if (item.isEntrepreneur == true) subtitleParts.add('Формат: свободный / самозанятый');
    if (item.clubs.isNotEmpty) subtitleParts.add('Клубы: ${item.clubs.join(', ')}');
    return Card(
      child: ListTile(
        title: Text(item.fullName ?? 'Без имени'),
        subtitle: subtitleParts.isNotEmpty ? Text(subtitleParts.join(' • ')) : null,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (item.rating != null) Text('★ ${item.rating!.toStringAsFixed(1)}'),
            if (item.accountType != null) Text(item.accountType!, style: const TextStyle(fontSize: 12)),
          ],
        ),
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

