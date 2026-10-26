import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../text/labels.dart';

/// Asks for a last confirmation before a report is sent, because a report
/// cannot be withdrawn. When the domain finds similar recent reports it says so.
class ConfirmReportDialog extends StatelessWidget {
  const ConfirmReportDialog({super.key, required this.duplicates});

  final List<Incident> duplicates;

  @override
  Widget build(BuildContext context) {
    final similar = duplicates.isNotEmpty;
    return AlertDialog(
      title: Text(similar ? 'Moguć duplikat' : 'Pošalji prijavu?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (similar) ...[
            const Text('Već ste prijavili sličan incident:'),
            const SizedBox(height: 8),
            for (final other in duplicates)
              Text(
                '• ${other.kind.label}, krivina ${other.turn.value}, '
                '${riderLabel(other.riderId)} (${formatTime(other.reportedAt)})',
              ),
            const SizedBox(height: 12),
          ],
          const Text('Prijava se ne može povući.'),
        ],
      ),
      actions: [
        TextButton(
          key: const Key('cancel-report'),
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Odustani'),
        ),
        FilledButton(
          key: const Key('confirm-report'),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(similar ? 'Ipak prijavi' : 'Pošalji'),
        ),
      ],
    );
  }
}
