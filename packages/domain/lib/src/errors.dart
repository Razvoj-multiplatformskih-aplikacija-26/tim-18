import 'package:meta/meta.dart';

import 'client_app.dart';
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

/// A marshal tried to take back a report that the direction has already acted
/// on. Only a report that is still in the state "reported" can be withdrawn.
@immutable
final class NotWithdrawable extends DomainError {
  const NotWithdrawable();

  @override
  bool operator ==(Object other) => other is NotWithdrawable;

  @override
  int get hashCode => (NotWithdrawable).hashCode;

  @override
  String toString() => 'NotWithdrawable()';
}

/// The user signed in to the wrong application (a marshal in the backoffice,
/// or the direction in the mobile app). [app] is the application that refused.
@immutable
final class WrongApp extends DomainError {
  const WrongApp(this.app);

  final ClientApp app;

  @override
  bool operator ==(Object other) => other is WrongApp && other.app == app;

  @override
  int get hashCode => Object.hash(WrongApp, app);

  @override
  String toString() => 'WrongApp(${app.name})';
}
