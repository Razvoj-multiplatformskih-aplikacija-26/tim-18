import '../incident/incident.dart';
import '../incident/incident_status.dart';

const duplicateWindow = Duration(minutes: 5);

List<Incident> possibleDuplicates(
  Incident candidate,
  Iterable<Incident> existing, {
  Duration window = duplicateWindow,
}) {
  return [
    for (final other in existing)
      if (other.id != candidate.id &&
          other.riderId == candidate.riderId &&
          other.turn == candidate.turn &&
          other.kind == candidate.kind &&
          other.status is! Dismissed &&
          other.reportedAt.difference(candidate.reportedAt).abs() <= window)
        other,
  ];
}
