import 'package:flutter/material.dart';

import '../../../../../core/repositories/specialists_repository.dart';
import '../../../../../models/mechanic_directory_models.dart';

class AttestationApplicationsScreen extends StatefulWidget {
  const AttestationApplicationsScreen({super.key});

  @override
  State<AttestationApplicationsScreen> createState() => _AttestationApplicationsScreenState();
}

class _AttestationApplicationsScreenState extends State<AttestationApplicationsScreen> {
  final SpecialistsRepository _repository = SpecialistsRepository();
  Future<List<AttestationApplication>>? _future;

  @override
  void initState() {
    super.initState();
    _future = _repository.getAttestationApplications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Заявки на аттестацию')),
      body: FutureBuilder<List<AttestationApplication>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Не удалось загрузить заявки'));
          }
          final data = snapshot.data ?? [];
          if (data.isEmpty) {
            return const Center(child: Text('Заявок на аттестацию пока нет'));
          }
          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (_, index) => _buildTile(data[index]),
          );
        },
      ),
    );
  }

  Widget _buildTile(AttestationApplication app) {
    final subtitle = <String>[];
    if (app.status != null) subtitle.add('Статус: ${app.status}');
    if (app.submittedAt != null) subtitle.add('Подача: ${app.submittedAt}');
    if (app.comment != null && app.comment!.isNotEmpty) subtitle.add('Комментарий: ${app.comment}');

    return Card(
      child: ListTile(
        title: Text('Заявка #${app.id}'),
        subtitle: subtitle.isNotEmpty ? Text(subtitle.join(' • ')) : null,
        trailing: app.requestedGrade != null ? Chip(label: Text(app.requestedGrade!)) : null,
      ),
    );
  }
}

