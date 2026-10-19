import 'package:domain/domain.dart';

const marshal = User(id: UserId('u-marshal'), username: 'marshal1', role: Role.marshal);
const otherMarshal = User(id: UserId('u-marshal-2'), username: 'marshal2', role: Role.marshal);
const director = User(id: UserId('u-director'), username: 'director1', role: Role.director);

const rider93 = RiderId('r-93');
const rider46 = RiderId('r-46');

final raceStart = DateTime.utc(2026, 11, 8, 14);

Penalty penalty(PenaltyKind kind, int points) => Penalty.parse(kind, points).valueOrNull!;

Incident incidentAt(
  DateTime reportedAt, {
  String id = 'i-1',
  UserId reporterId = const UserId('u-marshal'),
  RiderId riderId = rider93,
  int turn = 5,
  IncidentKind kind = IncidentKind.trackLimits,
  IncidentStatus status = const Reported(),
}) {
  return Incident(
    id: IncidentId(id),
    reporterId: reporterId,
    riderId: riderId,
    kind: kind,
    description: IncidentDescription.parse('Vozač je prešao liniju staze u krivini.').valueOrNull!,
    turn: TurnNumber.parse(turn).valueOrNull!,
    reportedAt: reportedAt,
    status: status,
  );
}

Incident withPenalty(String id, RiderId riderId, int points) {
  return incidentAt(
    raceStart,
    id: id,
    riderId: riderId,
    status: PenaltyIssued(penalty: penalty(PenaltyKind.warning, points), by: director.id, at: raceStart),
  );
}
