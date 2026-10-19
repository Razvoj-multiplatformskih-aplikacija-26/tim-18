import 'package:meta/meta.dart';

import '../identifiers.dart';
import 'description.dart';
import 'incident_kind.dart';
import 'incident_status.dart';
import 'turn_number.dart';

@immutable
final class Incident {
  const Incident({
    required this.id,
    required this.reporterId,
    required this.riderId,
    required this.kind,
    required this.description,
    required this.turn,
    required this.reportedAt,
    this.status = const Reported(),
  });

  final IncidentId id;
  final UserId reporterId;
  final RiderId riderId;
  final IncidentKind kind;
  final IncidentDescription description;
  final TurnNumber turn;
  final DateTime reportedAt;
  final IncidentStatus status;

  bool get isOpen => status.isOpen;

  Incident copyWith({IncidentStatus? status}) {
    return Incident(
      id: id,
      reporterId: reporterId,
      riderId: riderId,
      kind: kind,
      description: description,
      turn: turn,
      reportedAt: reportedAt,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Incident &&
      other.id == id &&
      other.reporterId == reporterId &&
      other.riderId == riderId &&
      other.kind == kind &&
      other.description == description &&
      other.turn == turn &&
      other.reportedAt == reportedAt &&
      other.status == status;

  @override
  int get hashCode => Object.hash(id, reporterId, riderId, kind, description, turn, reportedAt, status);

  @override
  String toString() => 'Incident($id, $riderId, ${kind.name}, turn ${turn.value}, $status)';
}
