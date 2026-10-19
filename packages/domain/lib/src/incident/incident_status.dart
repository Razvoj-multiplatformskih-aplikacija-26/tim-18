import 'package:meta/meta.dart';

import '../identifiers.dart';
import 'penalty.dart';

sealed class IncidentStatus {
  const IncidentStatus();

  bool get isOpen => switch (this) {
    Reported() || Confirmed() || UnderReview() => true,
    PenaltyIssued() || Dismissed() => false,
  };

  bool get isFinal => !isOpen;
}

final class Reported extends IncidentStatus {
  const Reported();

  @override
  String toString() => 'Reported';
}

@immutable
final class Confirmed extends IncidentStatus {
  const Confirmed({required this.by, required this.at});

  final UserId by;
  final DateTime at;

  @override
  bool operator ==(Object other) => other is Confirmed && other.by == by && other.at == at;

  @override
  int get hashCode => Object.hash(by, at);

  @override
  String toString() => 'Confirmed(by $by at $at)';
}

@immutable
final class UnderReview extends IncidentStatus {
  const UnderReview({required this.by, required this.at});

  final UserId by;
  final DateTime at;

  @override
  bool operator ==(Object other) => other is UnderReview && other.by == by && other.at == at;

  @override
  int get hashCode => Object.hash(UnderReview, by, at);

  @override
  String toString() => 'UnderReview(by $by at $at)';
}

@immutable
final class PenaltyIssued extends IncidentStatus {
  const PenaltyIssued({required this.penalty, required this.by, required this.at});

  final Penalty penalty;
  final UserId by;
  final DateTime at;

  @override
  bool operator ==(Object other) =>
      other is PenaltyIssued && other.penalty == penalty && other.by == by && other.at == at;

  @override
  int get hashCode => Object.hash(penalty, by, at);

  @override
  String toString() => 'PenaltyIssued($penalty by $by at $at)';
}

@immutable
final class Dismissed extends IncidentStatus {
  const Dismissed({required this.reason, required this.by, required this.at});

  final String reason;
  final UserId by;
  final DateTime at;

  @override
  bool operator ==(Object other) => other is Dismissed && other.reason == reason && other.by == by && other.at == at;

  @override
  int get hashCode => Object.hash(reason, by, at);

  @override
  String toString() => 'Dismissed("$reason" by $by at $at)';
}

bool canTransition(IncidentStatus from, IncidentStatus to) => switch ((from, to)) {
  (Reported(), Confirmed()) => true,
  (Reported(), Dismissed()) => true,
  (Confirmed(), UnderReview()) => true,
  (Confirmed(), Dismissed()) => true,
  (UnderReview(), PenaltyIssued()) => true,
  (UnderReview(), Dismissed()) => true,
  _ => false,
};
