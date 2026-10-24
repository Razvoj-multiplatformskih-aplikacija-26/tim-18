import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';

sealed class IncidentsEvent extends Equatable {
  const IncidentsEvent();
}

/// Load the incident list. Also used by the "Pokušaj ponovo" button.
final class IncidentsRequested extends IncidentsEvent {
  const IncidentsRequested();

  @override
  List<Object?> get props => const [];
}

/// A marshal submitted the report form. Raw input: the domain validates it.
final class IncidentReported extends IncidentsEvent {
  const IncidentReported({required this.riderId, required this.kind, required this.description, required this.turn});

  final RiderId riderId;
  final IncidentKind kind;
  final String description;
  final int turn;

  @override
  List<Object?> get props => [riderId, kind, description, turn];
}

/// The direction confirms a reported incident.
final class IncidentConfirmed extends IncidentsEvent {
  const IncidentConfirmed(this.incidentId);

  final IncidentId incidentId;

  @override
  List<Object?> get props => [incidentId];
}

/// The direction starts reviewing a confirmed incident.
final class IncidentReviewStarted extends IncidentsEvent {
  const IncidentReviewStarted(this.incidentId);

  final IncidentId incidentId;

  @override
  List<Object?> get props => [incidentId];
}

/// The direction issues a penalty. Raw input: the domain validates the points.
final class IncidentPenalized extends IncidentsEvent {
  const IncidentPenalized({required this.incidentId, required this.kind, required this.points});

  final IncidentId incidentId;
  final PenaltyKind kind;
  final int points;

  @override
  List<Object?> get props => [incidentId, kind, points];
}

/// The direction dismisses an incident. The reason is required by the domain.
final class IncidentDismissed extends IncidentsEvent {
  const IncidentDismissed({required this.incidentId, required this.reason});

  final IncidentId incidentId;
  final String reason;

  @override
  List<Object?> get props => [incidentId, reason];
}
