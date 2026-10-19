import '../errors.dart';
import '../identifiers.dart';
import '../result.dart';
import '../user.dart';
import 'access_policy.dart';
import 'description.dart';
import 'incident.dart';
import 'incident_kind.dart';
import 'turn_number.dart';

Result<Incident> reportIncident({
  required IncidentId id,
  required User by,
  required RiderId riderId,
  required IncidentKind kind,
  required String description,
  required int turn,
  required DateTime now,
}) {
  if (!AccessPolicy.canReport(by)) return const Failure(NotAllowed());
  final parsedDescription = IncidentDescription.parse(description);
  final parsedTurn = TurnNumber.parse(turn);
  final error = parsedDescription.errorOrNull ?? parsedTurn.errorOrNull;
  if (error != null) return Failure(error);
  return Success(
    Incident(
      id: id,
      reporterId: by.id,
      riderId: riderId,
      kind: kind,
      description: parsedDescription.valueOrNull!,
      turn: parsedTurn.valueOrNull!,
      reportedAt: now.toUtc(),
    ),
  );
}
