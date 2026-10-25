import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../text/labels.dart';
import 'status_chip.dart';

/// Column widths as flex factors, shared by the header and every row.
const _flexTime = 1;
const _flexRider = 3;
const _flexKind = 3;
const _flexTurn = 1;
const _flexStatus = 2;

class IncidentTable extends StatelessWidget {
  const IncidentTable({super.key, required this.incidents, required this.selectedId, required this.onSelected});

  final List<Incident> incidents;
  final IncidentId? selectedId;
  final ValueChanged<Incident> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _HeaderRow(),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            itemCount: incidents.length,
            itemBuilder: (context, index) {
              final incident = incidents[index];
              return IncidentRow(
                key: ValueKey('row-${incident.id.value}'),
                incident: incident,
                selected: incident.id == selectedId,
                onTap: () => onSelected(incident),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: _flexTime,
            child: Text('Vreme', style: style),
          ),
          Expanded(
            flex: _flexRider,
            child: Text('Vozač', style: style),
          ),
          Expanded(
            flex: _flexKind,
            child: Text('Vrsta', style: style),
          ),
          Expanded(
            flex: _flexTurn,
            child: Text('Krivina', style: style),
          ),
          Expanded(
            flex: _flexStatus,
            child: Text('Stanje', style: style),
          ),
        ],
      ),
    );
  }
}

class IncidentRow extends StatelessWidget {
  const IncidentRow({super.key, required this.incident, required this.selected, required this.onTap});

  final Incident incident;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Theme.of(context).colorScheme.secondaryContainer : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(flex: _flexTime, child: Text(formatTime(incident.reportedAt))),
              Expanded(
                flex: _flexRider,
                child: Text(riderLabel(incident.riderId), overflow: TextOverflow.ellipsis),
              ),
              Expanded(
                flex: _flexKind,
                child: Text(incident.kind.label, overflow: TextOverflow.ellipsis),
              ),
              Expanded(flex: _flexTurn, child: Text('${incident.turn.value}')),
              Expanded(
                flex: _flexStatus,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: StatusChip(status: incident.status),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
