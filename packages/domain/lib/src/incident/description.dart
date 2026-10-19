import 'package:characters/characters.dart';
import 'package:meta/meta.dart';

import '../errors.dart';
import '../result.dart';

@immutable
final class IncidentDescription {
  const IncidentDescription._(this.text);

  static const minLength = 10;
  static const maxLength = 300;

  final String text;

  int get length => text.characters.length;

  static Result<IncidentDescription> parse(String input) {
    final text = input.trim();
    final length = text.characters.length;
    if (length < minLength) return Failure(DescriptionTooShort(length));
    if (length > maxLength) return Failure(DescriptionTooLong(length));
    return Success(IncidentDescription._(text));
  }

  @override
  bool operator ==(Object other) => other is IncidentDescription && other.text == text;

  @override
  int get hashCode => text.hashCode;

  @override
  String toString() => 'IncidentDescription("$text")';
}
