import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../app_dependencies.dart';
import '../router.dart';
import '../text/error_messages.dart';
import '../text/labels.dart';
import '../widgets/status_chip.dart';

class IncidentDetailScreen extends StatelessWidget {
  const IncidentDetailScreen({super.key, required this.incidentId});

  final String incidentId;

  void _onSubmission(BuildContext context, IncidentsState state) {
    if (state is! IncidentsLoaded) return;
    final messenger = ScaffoldMessenger.of(context);
    switch (state.submission) {
      case SubmissionStatus.idle || SubmissionStatus.inProgress:
        break;
      case SubmissionStatus.succeeded:
        messenger.showSnackBar(const SnackBar(content: Text('Prijava je povučena.')));
        context.goNamed(Routes.incidents);
      case SubmissionStatus.rejected:
        messenger.showSnackBar(
          SnackBar(content: Text(state.submissionError?.message ?? 'Server nije prihvatio ovu radnju.')),
        );
      case SubmissionStatus.failed:
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Radnja nije izvršena. Proverite vezu i pokušajte ponovo; '
              'ako se ponavlja, ažurirajte aplikaciju.',
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<IncidentsBloc, IncidentsState>(
      listenWhen: (previous, current) =>
          current is IncidentsLoaded && (previous is! IncidentsLoaded || previous.submission != current.submission),
      listener: _onSubmission,
      child: Scaffold(
        appBar: AppBar(title: const Text('Detalji incidenta')),
        body: BlocBuilder<IncidentsBloc, IncidentsState>(
          builder: (context, state) => switch (state) {
            IncidentsLoading() => const Center(child: CircularProgressIndicator()),
            IncidentsFailure() => const Center(child: Text('Incidenti nisu učitani.')),
            final IncidentsLoaded loaded => _Body(
              incident: _find(loaded.incidents),
              busy: loaded.submission == SubmissionStatus.inProgress,
            ),
          },
        ),
      ),
    );
  }

  Incident? _find(List<Incident> incidents) {
    return incidents.where((incident) => incident.id.value == incidentId).firstOrNull;
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.incident, required this.busy});

  final Incident? incident;
  final bool busy;

  /// Takes back a report of the signed-in marshal. It asks first, because the
  /// report is gone afterwards.
  Future<void> _withdraw(BuildContext context, Incident incident) async {
    final bloc = context.read<IncidentsBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Povući prijavu?'),
        content: const Text('Prijava će biti uklonjena i to se ne može poništiti.'),
        actions: [
          TextButton(
            key: const Key('cancel-withdraw'),
            onPressed: () => Navigator.of(dialog).pop(false),
            child: const Text('Odustani'),
          ),
          FilledButton(
            key: const Key('confirm-withdraw'),
            onPressed: () => Navigator.of(dialog).pop(true),
            child: const Text('Povuci'),
          ),
        ],
      ),
    );
    if (confirmed == true) bloc.add(IncidentWithdrawn(incident.id));
  }

  @override
  Widget build(BuildContext context) {
    final incident = this.incident;
    if (incident == null) return const Center(child: Text('Incident nije pronađen.'));

    final textTheme = Theme.of(context).textTheme;
    final note = statusNote(incident.status);
    final user = context.read<AppDependencies>().user;
    final canWithdraw = isWithdrawable(incident) && AccessPolicy.canWithdraw(user, incident);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: StatusChip(status: incident.status),
        ),
        const SizedBox(height: 12),
        Text(incident.kind.label, style: textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text('Krivina ${incident.turn.value}', style: textTheme.titleMedium),
        const SizedBox(height: 24),
        _Field(label: 'Vozač', value: riderLabel(incident.riderId)),
        _Field(label: 'Prijavljeno u', value: formatTime(incident.reportedAt)),
        _Field(label: 'Opis', value: incident.description.text),
        if (note != null) _Field(label: 'Stanje', value: note),
        if (canWithdraw)
          OutlinedButton.icon(
            key: const Key('withdraw-button'),
            onPressed: busy ? null : () => _withdraw(context, incident),
            icon: const Icon(Icons.undo),
            label: const Text('Povuci prijavu'),
          ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          Text(value, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}
