import '../identifiers.dart';
import 'incident_status.dart';
import 'penalty.dart';

/// What the direction can do with an incident.
enum Decision { confirm, startReview, issuePenalty, dismiss }

const _nobody = UserId('');

/// The decisions open for an incident in [status]. It asks [canTransition],
/// so the allowed moves are written down in one place only.
List<Decision> decisionsFor(IncidentStatus status) {
  final epoch = DateTime.utc(1970);
  IncidentStatus target(Decision decision) => switch (decision) {
    Decision.confirm => Confirmed(by: _nobody, at: epoch),
    Decision.startReview => UnderReview(by: _nobody, at: epoch),
    Decision.issuePenalty => PenaltyIssued(penalty: Penalty.automaticLongLap, by: _nobody, at: epoch),
    Decision.dismiss => Dismissed(reason: '', by: _nobody, at: epoch),
  };

  return [
    for (final decision in Decision.values)
      if (canTransition(status, target(decision))) decision,
  ];
}
