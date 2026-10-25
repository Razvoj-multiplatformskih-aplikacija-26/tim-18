import '../errors.dart';
import '../result.dart';
import '../user.dart';
import 'access_policy.dart';
import 'incident.dart';
import 'incident_status.dart';
import 'penalty.dart';

Result<Incident> confirmIncident(Incident incident, {required User by, required DateTime now}) {
  if (!AccessPolicy.canDecide(by)) return const Failure(NotAllowed());
  return _transition(incident, Confirmed(by: by.id, at: now.toUtc()));
}

Result<Incident> startReview(Incident incident, {required User by, required DateTime now}) {
  if (!AccessPolicy.canDecide(by)) return const Failure(NotAllowed());
  return _transition(incident, UnderReview(by: by.id, at: now.toUtc()));
}

Result<Incident> issuePenalty(Incident incident, {required User by, required DateTime now, required Penalty penalty}) {
  if (!AccessPolicy.canDecide(by)) return const Failure(NotAllowed());
  return _transition(incident, PenaltyIssued(penalty: penalty, by: by.id, at: now.toUtc()));
}

/// The reason for a dismissal: required, and stored trimmed. Forms use this
/// same function to check the input before it is sent.
Result<String> parseDismissalReason(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return const Failure(ReasonRequired());
  return Success(trimmed);
}

Result<Incident> dismissIncident(Incident incident, {required User by, required DateTime now, required String reason}) {
  if (!AccessPolicy.canDecide(by)) return const Failure(NotAllowed());
  final parsed = parseDismissalReason(reason);
  final error = parsed.errorOrNull;
  if (error != null) return Failure(error);
  return _transition(incident, Dismissed(reason: parsed.valueOrNull!, by: by.id, at: now.toUtc()));
}

Result<Incident> _transition(Incident incident, IncidentStatus next) {
  if (!canTransition(incident.status, next)) {
    return Failure(InvalidTransition(from: incident.status, to: next));
  }
  return Success(incident.copyWith(status: next));
}
