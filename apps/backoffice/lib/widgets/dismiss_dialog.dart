import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../text/error_messages.dart';

/// Asks for the reason of a dismissal. Pops the reason, or null when the
/// direction backs out. The reason is checked by the domain rule.
class DismissDialog extends StatefulWidget {
  const DismissDialog({super.key});

  @override
  State<DismissDialog> createState() => _DismissDialogState();
}

class _DismissDialogState extends State<DismissDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(_reasonController.text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Odbaci incident'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          key: const Key('dismiss-reason'),
          controller: _reasonController,
          decoration: const InputDecoration(labelText: 'Razlog'),
          minLines: 2,
          maxLines: 4,
          validator: (input) => parseDismissalReason(input ?? '').errorOrNull?.message,
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Odustani')),
        FilledButton(key: const Key('dismiss-submit'), onPressed: _submit, child: const Text('Odbaci')),
      ],
    );
  }
}
