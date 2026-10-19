import 'package:meta/meta.dart';

import 'incident/incident_status.dart';

sealed class DomainError {
  const DomainError();
}

@immutable
final class DescriptionTooShort extends DomainError {
  const DescriptionTooShort(this.length);

  final int length;

  @override
  bool operator ==(Object other) => other is DescriptionTooShort && other.length == length;

  @override
  int get hashCode => Object.hash(DescriptionTooShort, length);

  @override
  String toString() => 'DescriptionTooShort($length)';
}

@immutable
final class DescriptionTooLong extends DomainError {
  const DescriptionTooLong(this.length);

  final int length;

  @override
  bool operator ==(Object other) => other is DescriptionTooLong && other.length == length;

  @override
  int get hashCode => Object.hash(DescriptionTooLong, length);

  @override
  String toString() => 'DescriptionTooLong($length)';
}

@immutable
final class InvalidTurnNumber extends DomainError {
  const InvalidTurnNumber(this.turn);

  final int turn;

  @override
  bool operator ==(Object other) => other is InvalidTurnNumber && other.turn == turn;

  @override
  int get hashCode => Object.hash(InvalidTurnNumber, turn);

  @override
  String toString() => 'InvalidTurnNumber($turn)';
}

@immutable
final class InvalidPenaltyPoints extends DomainError {
  const InvalidPenaltyPoints(this.points);

  final int points;

  @override
  bool operator ==(Object other) => other is InvalidPenaltyPoints && other.points == points;

  @override
  int get hashCode => Object.hash(InvalidPenaltyPoints, points);

  @override
  String toString() => 'InvalidPenaltyPoints($points)';
}

final class ReasonRequired extends DomainError {
  const ReasonRequired();
}

@immutable
final class InvalidTransition extends DomainError {
  const InvalidTransition({required this.from, required this.to});

  final IncidentStatus from;
  final IncidentStatus to;

  @override
  bool operator ==(Object other) =>
      other is InvalidTransition &&
      other.from.runtimeType == from.runtimeType &&
      other.to.runtimeType == to.runtimeType;

  @override
  int get hashCode => Object.hash(InvalidTransition, from.runtimeType, to.runtimeType);

  @override
  String toString() => 'InvalidTransition(${from.runtimeType} -> ${to.runtimeType})';
}

final class NotAllowed extends DomainError {
  const NotAllowed();
}

final class NotFound extends DomainError {
  const NotFound();
}
