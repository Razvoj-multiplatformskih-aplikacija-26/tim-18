import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../text/error_messages.dart';
import '../text/labels.dart';

/// Asks for the kind and points of a penalty. Pops `(kind, points)`, or null
/// when the direction backs out. The points are checked by the domain rule.
class PenaltyDialog extends StatefulWidget {
  const PenaltyDialog({super.key});

  @override
  State<PenaltyDialog> createState() => _PenaltyDialogState();
}

class _PenaltyDialogState extends State<PenaltyDialog> {
  final _formKey = GlobalKey<FormState>();
  final _pointsController = TextEditingController();
  PenaltyKind _kind = PenaltyKind.warning;

  @override
  void dispose() {
    _pointsController.dispose();
    super.dispose();
  }

  String? _validatePoints(String? input) {
    final points = int.tryParse(input?.trim() ?? '');
    if (points == null) return 'Unesite broj kaznenih poena.';
    return Penalty.parse(_kind, points).errorOrNull?.message;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop((_kind, int.parse(_pointsController.text.trim())));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Izreci kaznu'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<PenaltyKind>(
              key: const Key('penalty-kind'),
              initialValue: _kind,
              decoration: const InputDecoration(labelText: 'Vrsta kazne'),
              items: [for (final kind in PenaltyKind.values) DropdownMenuItem(value: kind, child: Text(kind.label))],
              onChanged: (kind) => _kind = kind ?? _kind,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('penalty-points'),
              controller: _pointsController,
              decoration: InputDecoration(labelText: 'Kazneni poeni', hintText: '0–${Penalty.maxPoints}'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: _validatePoints,
              onFieldSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Odustani')),
        FilledButton(key: const Key('penalty-submit'), onPressed: _submit, child: const Text('Izreci kaznu')),
      ],
    );
  }
}
