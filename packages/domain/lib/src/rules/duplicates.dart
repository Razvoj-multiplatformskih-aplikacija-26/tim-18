import '../identifiers.dart';
import '../incident/incident.dart';
import '../incident/incident_kind.dart';
import '../incident/incident_status.dart';
import '../incident/turn_number.dart';

const duplicateWindow = Duration(minutes: 5);

/// Reports of the same rider, turn and kind close in time to a report that is
/// about to be made. Dismissed incidents do not count.
List<Incident> duplicatesOfReport(
  Iterable<Incident> existing, {
  required RiderId riderId,
  required IncidentKind kind,
  required TurnNumber turn,
  required DateTime at,
  Duration window = duplicateWindow,
}) {
  return [
    for (final other in existing)
      if (other.riderId == riderId &&
          other.turn == turn &&
          other.kind == kind &&
          other.status is! Dismissed &&
          other.reportedAt.difference(at).abs() <= window)
        other,
  ];
}

/// The same check for a report that already exists: the other incidents that
/// may be the same event.
List<Incident> possibleDuplicates(
  Incident candidate,
  Iterable<Incident> existing, {
  Duration window = duplicateWindow,
}) {
  return duplicatesOfReport(
    existing.where((other) => other.id != candidate.id),
    riderId: candidate.riderId,
    kind: candidate.kind,
    turn: candidate.turn,
    at: candidate.reportedAt,
    window: window,
  );
}
