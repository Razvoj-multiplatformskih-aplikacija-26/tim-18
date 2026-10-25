import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../text/labels.dart';
import 'dismiss_dialog.dart';
import 'penalty_dialog.dart';

/// The buttons for the decisions the domain allows for this incident. The
/// buttons only send events; the domain decides whether they take effect.
class DecisionBar extends StatelessWidget {
  const DecisionBar({super.key, required this.incident, required this.busy});

  final Incident incident;

  /// A decision is being saved; the buttons wait.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final decisions = decisionsFor(incident.status);
    if (decisions.isEmpty) return const Text('Za ovaj incident nema daljih odluka.');
    return Wrap(spacing: 8, runSpacing: 8, children: [for (final decision in decisions) _button(context, decision)]);
  }

  Widget _button(BuildContext context, Decision decision) {
    final key = Key('decision-${decision.name}');
    final onPressed = busy ? null : () => _run(context, decision);
    return switch (decision) {
      Decision.dismiss => OutlinedButton(key: key, onPressed: onPressed, child: Text(decision.label)),
      _ => FilledButton(key: key, onPressed: onPressed, child: Text(decision.label)),
    };
  }

  Future<void> _run(BuildContext context, Decision decision) async {
    final bloc = context.read<IncidentsBloc>();
    switch (decision) {
      case Decision.confirm:
        bloc.add(IncidentConfirmed(incident.id));
      case Decision.startReview:
        bloc.add(IncidentReviewStarted(incident.id));
      case Decision.issuePenalty:
        final penalty = await showDialog<(PenaltyKind, int)>(context: context, builder: (_) => const PenaltyDialog());
        if (penalty == null) return;
        bloc.add(IncidentPenalized(incidentId: incident.id, kind: penalty.$1, points: penalty.$2));
      case Decision.dismiss:
        final reason = await showDialog<String>(context: context, builder: (_) => const DismissDialog());
        if (reason == null) return;
        bloc.add(IncidentDismissed(incidentId: incident.id, reason: reason));
    }
  }
}
