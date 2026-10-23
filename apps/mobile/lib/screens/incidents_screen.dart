import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router.dart';

/// Placeholder until step 2.4 puts the real list here.
class IncidentsScreen extends StatelessWidget {
  const IncidentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Incidenti')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Lista incidenata dolazi u sledećem koraku.'),
            const SizedBox(height: 16),
            FilledButton(onPressed: () => context.goNamed(Routes.report), child: const Text('Prijavi incident')),
            TextButton(
              onPressed: () => context.goNamed(Routes.incident, pathParameters: {'id': 'i-01'}),
              child: const Text('Detalji incidenta i-01'),
            ),
          ],
        ),
      ),
    );
  }
}
