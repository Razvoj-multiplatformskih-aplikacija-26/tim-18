import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../text/labels.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final IncidentStatus status;

  @override
  Widget build(BuildContext context) {
    final color = _colorOf(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
      child: Text(
        status.label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }

  static Color _colorOf(IncidentStatus status) => switch (status) {
    Reported() => const Color(0xFF78909C),
    Confirmed() => const Color(0xFF1E88E5),
    UnderReview() => const Color(0xFFF9A825),
    PenaltyIssued() => const Color(0xFFD7263D),
    Dismissed() => const Color(0xFF43A047),
  };
}
