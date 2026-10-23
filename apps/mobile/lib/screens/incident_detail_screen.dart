import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../text/labels.dart';
import '../widgets/status_chip.dart';

class IncidentDetailScreen extends StatelessWidget {
  const IncidentDetailScreen({super.key, required this.incidentId});

  final String incidentId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalji incidenta')),
      body: BlocBuilder<IncidentsBloc, IncidentsState>(
        builder: (context, state) => switch (state) {
          IncidentsLoading() => const Center(child: CircularProgressIndicator()),
          IncidentsFailure() => const Center(child: Text('Incidenti nisu učitani.')),
          IncidentsLoaded(:final incidents) => _Body(incident: _find(incidents)),
        },
      ),
    );
  }

  Incident? _find(List<Incident> incidents) {
    return incidents.where((incident) => incident.id.value == incidentId).firstOrNull;
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.incident});

  final Incident? incident;

  @override
  Widget build(BuildContext context) {
    final incident = this.incident;
    if (incident == null) return const Center(child: Text('Incident nije pronađen.'));

    final textTheme = Theme.of(context).textTheme;
    final note = statusNote(incident.status);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: StatusChip(status: incident.status),
        ),
        const SizedBox(height: 12),
        Text(incident.kind.label, style: textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text('Krivina ${incident.turn.value}', style: textTheme.titleMedium),
        const SizedBox(height: 24),
        _Field(label: 'Vozač', value: riderLabel(incident.riderId)),
        _Field(label: 'Prijavljeno u', value: formatTime(incident.reportedAt)),
        _Field(label: 'Opis', value: incident.description.text),
        if (note != null) _Field(label: 'Stanje', value: note),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          Text(value, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}
