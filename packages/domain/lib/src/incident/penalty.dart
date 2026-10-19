import 'package:meta/meta.dart';

import '../errors.dart';
import '../result.dart';

enum PenaltyKind { warning, longLap, rideThrough, positionDrop }

@immutable
final class Penalty {
  const Penalty._(this.kind, this.points);

  static const maxPoints = 3;

  /// The penalty the system hands out when a rider reaches the points threshold.
  static const automaticLongLap = Penalty._(PenaltyKind.longLap, 0);

  final PenaltyKind kind;
  final int points;

  static Result<Penalty> parse(PenaltyKind kind, int points) {
    if (points < 0 || points > maxPoints) return Failure(InvalidPenaltyPoints(points));
    return Success(Penalty._(kind, points));
  }

  @override
  bool operator ==(Object other) => other is Penalty && other.kind == kind && other.points == points;

  @override
  int get hashCode => Object.hash(kind, points);

  @override
  String toString() => 'Penalty(${kind.name}, $points pts)';
}
