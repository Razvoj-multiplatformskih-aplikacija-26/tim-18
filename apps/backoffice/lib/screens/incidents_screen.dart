import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../widgets/debug_menu.dart';
import '../widgets/filter_bar.dart';
import '../widgets/incident_panel.dart';
import '../widgets/incident_table.dart';

class IncidentsScreen extends StatefulWidget {
  const IncidentsScreen({super.key});

  @override
  State<IncidentsScreen> createState() => _IncidentsScreenState();
}

class _IncidentsScreenState extends State<IncidentsScreen> {
  IncidentStage? _stage;
  Rider? _rider;
  IncidentId? _selectedId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Race Direction · Direkcija'), actions: const [DebugMenu()]),
      body: BlocBuilder<IncidentsBloc, IncidentsState>(
        builder: (context, state) => switch (state) {
          IncidentsLoading() => const Center(child: CircularProgressIndicator()),
          IncidentsFailure() => _ErrorView(
            onRetry: () => context.read<IncidentsBloc>().add(const IncidentsRequested()),
          ),
          IncidentsLoaded(isEmpty: true) => const _Message(
            icon: Icons.flag_outlined,
            text: 'Nema prijavljenih incidenata.',
          ),
          IncidentsLoaded(:final incidents) => _workspace(incidents),
        },
      ),
    );
  }

  Widget _workspace(List<Incident> incidents) {
    final shown = filterIncidents(incidents, stage: _stage, riderId: _rider?.id);
    final selected = incidents.where((incident) => incident.id == _selectedId).firstOrNull;

    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              FilterBar(
                stage: _stage,
                rider: _rider,
                onStageChanged: (stage) => setState(() => _stage = stage),
                onRiderChanged: (rider) => setState(() => _rider = rider),
                shown: shown.length,
                total: incidents.length,
              ),
              const Divider(height: 1),
              Expanded(
                child: shown.isEmpty
                    ? const _Message(icon: Icons.filter_alt_off_outlined, text: 'Nema incidenata za izabrane filtere.')
                    : IncidentTable(
                        incidents: shown,
                        selectedId: _selectedId,
                        onSelected: (incident) => setState(() => _selectedId = incident.id),
                      ),
              ),
            ],
          ),
        ),
        if (selected != null) ...[
          const VerticalDivider(width: 1),
          SizedBox(
            width: 360,
            child: IncidentPanel(incident: selected, all: incidents, onClose: () => setState(() => _selectedId = null)),
          ),
        ],
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [Icon(icon, size: 48), const SizedBox(height: 12), Text(text)],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            const Text('Incidenti nisu učitani.'),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Pokušaj ponovo')),
          ],
        ),
      ),
    );
  }
}
