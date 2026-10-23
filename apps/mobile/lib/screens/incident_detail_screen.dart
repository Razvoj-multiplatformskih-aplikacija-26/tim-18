import 'package:flutter/material.dart';

/// Placeholder until step 2.4 shows the real incident here.
class IncidentDetailScreen extends StatelessWidget {
  const IncidentDetailScreen({super.key, required this.incidentId});

  final String incidentId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalji incidenta')),
      body: Center(child: Text('Incident $incidentId')),
    );
  }
}
