import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../router.dart';
import '../widgets/debug_menu.dart';
import '../widgets/incident_tile.dart';

class IncidentsScreen extends StatelessWidget {
  const IncidentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Incidenti'), actions: const [DebugMenu()]),
      body: BlocBuilder<IncidentsBloc, IncidentsState>(
        builder: (context, state) => switch (state) {
          IncidentsLoading() => const Center(child: CircularProgressIndicator()),
          IncidentsFailure() => _ErrorView(
            onRetry: () => context.read<IncidentsBloc>().add(const IncidentsRequested()),
          ),
          IncidentsLoaded(isEmpty: true) => const _EmptyView(),
          IncidentsLoaded(:final incidents) => _IncidentList(incidents: incidents),
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.goNamed(Routes.report),
        icon: const Icon(Icons.add),
        label: const Text('Prijavi incident'),
      ),
    );
  }
}

class _IncidentList extends StatelessWidget {
  const _IncidentList({required this.incidents});

  final List<Incident> incidents;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 96),
      itemCount: incidents.length,
      itemBuilder: (context, index) => IncidentTile(incident: incidents[index]),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [Icon(Icons.flag_outlined, size: 48), SizedBox(height: 12), Text('Nema prijavljenih incidenata.')],
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
