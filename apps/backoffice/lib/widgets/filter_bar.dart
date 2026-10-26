import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../data/seed_data.dart';
import '../text/labels.dart';

class FilterBar extends StatelessWidget {
  const FilterBar({
    super.key,
    required this.stage,
    required this.rider,
    required this.onStageChanged,
    required this.onRiderChanged,
    required this.shown,
    required this.total,
  });

  final IncidentStage? stage;
  final Rider? rider;
  final ValueChanged<IncidentStage?> onStageChanged;
  final ValueChanged<Rider?> onRiderChanged;
  final int shown;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Sva stanja'),
                selected: stage == null,
                onSelected: (_) => onStageChanged(null),
              ),
              for (final value in IncidentStage.values)
                ChoiceChip(
                  label: Text(value.label),
                  selected: stage == value,
                  onSelected: (_) => onStageChanged(value),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 24,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              DropdownButton<Rider?>(
                key: const Key('rider-filter'),
                value: rider,
                items: [
                  const DropdownMenuItem<Rider?>(value: null, child: Text('Svi vozači')),
                  for (final value in riders) DropdownMenuItem<Rider?>(value: value, child: Text(riderLabel(value.id))),
                ],
                onChanged: onRiderChanged,
              ),
              Text('Prikazano $shown od $total'),
            ],
          ),
        ],
      ),
    );
  }
}
