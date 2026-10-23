import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router.dart';
import '../text/labels.dart';
import 'status_chip.dart';

class IncidentTile extends StatelessWidget {
  const IncidentTile({super.key, required this.incident});

  final Incident incident;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        onTap: () => context.goNamed(Routes.incident, pathParameters: {'id': incident.id.value}),
        title: Text(
          '${incident.kind.label} · krivina ${incident.turn.value}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text('${riderLabel(incident.riderId)} · ${formatTime(incident.reportedAt)}'),
        trailing: StatusChip(status: incident.status),
      ),
    );
  }
}
