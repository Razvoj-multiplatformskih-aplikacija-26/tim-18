import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../shortcuts.dart';
import '../text/labels.dart';

Future<void> showShortcutsDialog(BuildContext context) {
  return showDialog<void>(context: context, builder: (_) => const _ShortcutsDialog());
}

class _ShortcutsDialog extends StatelessWidget {
  const _ShortcutsDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Prečice na tastaturi'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Row(keys: '↑ / ↓', text: 'Prethodni / sledeći incident'),
          const _Row(keys: 'Home / End', text: 'Prvi / poslednji incident'),
          const _Row(keys: 'Esc', text: 'Zatvori panel'),
          for (final decision in Decision.values) _Row(keys: decision.keyLabel, text: decision.label),
          const _Row(keys: 'F1', text: 'Ova pomoć'),
        ],
      ),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Zatvori'))],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.keys, required this.text});

  final String keys;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(keys, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          Text(text),
        ],
      ),
    );
  }
}
