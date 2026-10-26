import 'package:meta/meta.dart';

import '../identifiers.dart';
import '../incident/incident.dart';
import '../incident/incident_status.dart';

const longLapThreshold = 4;

@immutable
final class RiderStanding {
  const RiderStanding({required this.riderId, required this.points});

  final RiderId riderId;
  final int points;

  bool get longLapDue => points >= longLapThreshold;

  @override
  bool operator ==(Object other) => other is RiderStanding && other.riderId == riderId && other.points == points;

  @override
  int get hashCode => Object.hash(riderId, points);

  @override
  String toString() => 'RiderStanding($riderId, $points pts)';
}

int penaltyPointsOf(RiderId rider, Iterable<Incident> incidents) {
  var total = 0;
  for (final incident in incidents) {
    if (incident.riderId != rider) continue;
    if (incident.status case PenaltyIssued(:final penalty)) total += penalty.points;
  }
  return total;
}

/// The rider's total points and whether they reach the long lap threshold.
RiderStanding standingOf(RiderId rider, Iterable<Incident> incidents) {
  return RiderStanding(riderId: rider, points: penaltyPointsOf(rider, incidents));
}

bool crossesLongLapThreshold({required int pointsBefore, required int added}) =>
    pointsBefore < longLapThreshold && pointsBefore + added >= longLapThreshold;

List<RiderStanding> standings(Iterable<Incident> incidents) {
  final totals = <RiderId, int>{};
  for (final incident in incidents) {
    if (incident.status case PenaltyIssued(:final penalty)) {
      totals[incident.riderId] = (totals[incident.riderId] ?? 0) + penalty.points;
    }
  }
  final result = [for (final entry in totals.entries) RiderStanding(riderId: entry.key, points: entry.value)];
  result.sort((a, b) {
    final byPoints = b.points.compareTo(a.points);
    return byPoints != 0 ? byPoints : a.riderId.value.compareTo(b.riderId.value);
  });
  return result;
}
