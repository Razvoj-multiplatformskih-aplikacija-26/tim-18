import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../text/labels.dart';
import 'status_chip.dart';

/// Detail of the selected incident, with what the direction needs to decide:
/// the rider's penalty points and reports that may be duplicates.
class IncidentPanel extends StatelessWidget {
  const IncidentPanel({super.key, required this.incident, required this.all, required this.onClose});

  final Incident incident;

  /// Every incident the direction sees, to compute points and duplicates.
  final List<Incident> all;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final note = statusNote(incident.status);
    final points = penaltyPointsOf(incident.riderId, all);
    final duplicates = possibleDuplicates(incident, all);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            StatusChip(status: incident.status),
            const Spacer(),
            IconButton(
              key: const Key('close-panel'),
              tooltip: 'Zatvori',
              icon: const Icon(Icons.close),
              onPressed: onClose,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(incident.kind.label, style: textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text('Krivina ${incident.turn.value}', style: textTheme.titleMedium),
        const SizedBox(height: 24),
        _Field(label: 'Vozač', value: riderLabel(incident.riderId)),
        _Field(label: 'Prijavljeno u', value: formatTime(incident.reportedAt)),
        _Field(label: 'Opis', value: incident.description.text),
        if (note != null) _Field(label: 'Stanje', value: note),
        _Field(
          label: 'Kazneni poeni vozača',
          value: points >= longLapThreshold
              ? '$points od $longLapThreshold · dostignut prag za long lap'
              : '$points od $longLapThreshold',
        ),
        _Field(
          label: 'Mogući duplikati',
          value: duplicates.isEmpty
              ? 'Nema'
              : duplicates.map((other) => '${other.id.value} (${formatTime(other.reportedAt)})').join(', '),
        ),
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
