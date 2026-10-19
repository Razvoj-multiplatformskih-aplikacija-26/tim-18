import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('R3 · IncidentDescription', () {
    test('trims the input', () {
      final result = IncidentDescription.parse('   Vozač je pao u krivini.   ');
      expect(result.valueOrNull?.text, 'Vozač je pao u krivini.');
    });

    test('rejects text shorter than ten characters', () {
      expect(IncidentDescription.parse('kratko').errorOrNull, const DescriptionTooShort(6));
    });

    test('accepts exactly ten and exactly three hundred characters', () {
      expect(IncidentDescription.parse('a' * 10).isSuccess, isTrue);
      expect(IncidentDescription.parse('a' * 300).isSuccess, isTrue);
    });

    test('rejects three hundred and one characters', () {
      expect(IncidentDescription.parse('a' * 301).errorOrNull, const DescriptionTooLong(301));
    });

    test('counts characters, not UTF-16 code units', () {
      expect(IncidentDescription.parse('👍' * 300).isSuccess, isTrue);
      expect(IncidentDescription.parse('👍' * 301).errorOrNull, const DescriptionTooLong(301));
    });
  });

  group('R3 · TurnNumber', () {
    test('accepts the bounds', () {
      expect(TurnNumber.parse(TurnNumber.min).isSuccess, isTrue);
      expect(TurnNumber.parse(TurnNumber.max).isSuccess, isTrue);
    });

    test('rejects values outside the bounds', () {
      expect(TurnNumber.parse(0).errorOrNull, const InvalidTurnNumber(0));
      expect(TurnNumber.parse(31).errorOrNull, const InvalidTurnNumber(31));
    });
  });

  group('Penalty', () {
    test('accepts zero to three points', () {
      expect(Penalty.parse(PenaltyKind.warning, 0).isSuccess, isTrue);
      expect(Penalty.parse(PenaltyKind.longLap, 3).isSuccess, isTrue);
    });

    test('rejects points outside the range', () {
      expect(Penalty.parse(PenaltyKind.warning, -1).errorOrNull, const InvalidPenaltyPoints(-1));
      expect(Penalty.parse(PenaltyKind.warning, 4).errorOrNull, const InvalidPenaltyPoints(4));
    });
  });
}
