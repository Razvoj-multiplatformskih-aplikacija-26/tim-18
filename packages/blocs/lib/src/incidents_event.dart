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
