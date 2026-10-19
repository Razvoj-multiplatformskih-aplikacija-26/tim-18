import 'package:meta/meta.dart';

import '../errors.dart';
import '../result.dart';

@immutable
final class TurnNumber {
  const TurnNumber._(this.value);

  static const min = 1;
  static const max = 30;

  final int value;

  static Result<TurnNumber> parse(int value) {
    if (value < min || value > max) return Failure(InvalidTurnNumber(value));
    return Success(TurnNumber._(value));
  }

  @override
  bool operator ==(Object other) => other is TurnNumber && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'TurnNumber($value)';
}
