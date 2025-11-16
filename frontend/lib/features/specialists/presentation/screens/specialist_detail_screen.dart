import 'package:flutter/material.dart';

import '../../../../../core/repositories/specialists_repository.dart';
import '../../../../../models/mechanic_directory_models.dart';

class SpecialistDetailScreen extends StatefulWidget {
  final int profileId;
  const SpecialistDetailScreen({super.key, required this.profileId});

  @override
  State<SpecialistDetailScreen> createState() => _SpecialistDetailScreenState();
}

class _SpecialistDetailScreenState extends State<SpecialistDetailScreen> {
  final SpecialistsRepository _repository = SpecialistsRepository();
  Future<MechanicDirectoryDetail?>? _future;

  @override
  void initState() {
    super.initState();
    _future = _repository.getDetail(widget.profileId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Карточка специалиста')),
      body: FutureBuilder<MechanicDirectoryDetail?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null) {
            return const Center(child: Text('Не удалось загрузить данные специалиста'));
          }
          final detail = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(detail.fullName ?? 'Без имени', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              _infoRow('Телефон', detail.contactPhone ?? '—'),
              _infoRow('Специализация', detail.specialization ?? '—'),
              _infoRow('Статус', detail.status ?? '—'),
              _infoRow('Регион', detail.region ?? 'TODO: поле региона в анкете'),
              _infoRow('Рейтинг', detail.rating?.toStringAsFixed(1) ?? '—'),
              _infoRow('Общий стаж', detail.totalExperienceYears?.toString() ?? '—'),
              _infoRow('Опыт в боулинге', detail.bowlingExperienceYears?.toString() ?? '—'),
              _infoRow('Статус данных', detail.isDataVerified == true ? 'Проверено' : 'Не проверено'),
              _infoRow('Аттестация', detail.attestationStatus ?? 'TODO: статус аттестации'),
              const SizedBox(height: 12),
              const Text('Связанные клубы'),
              const SizedBox(height: 8),
              if (detail.relatedClubs.isEmpty)
                const Text('Нет привязанных клубов')
              else
                ...detail.relatedClubs.map((club) => ListTile(
                      title: Text(club.fullName ?? 'Клуб'),
                      subtitle: club.region != null ? Text('Регион: ${club.region}') : null,
                    )),
              const SizedBox(height: 12),
              const Text('Опыт и навыки'),
              const SizedBox(height: 8),
              if (detail.workPlaces != null) Text('Места работы: ${detail.workPlaces}') else const SizedBox(),
              if (detail.workPeriods != null) Text('Периоды работы: ${detail.workPeriods}') else const SizedBox(),
              if (detail.certifications.isNotEmpty)
                Text('Сертификации: ${detail.certifications.join(', ')}')
              else
                const Text('Сертификации: TODO — ожидание модели'),
            ],
          );
        },
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

