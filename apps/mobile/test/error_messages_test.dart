import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/text/error_messages.dart';

void main() {
  test('every domain error has a message', () {
    const errors = <DomainError>[
      DescriptionTooShort(3),
      DescriptionTooLong(301),
      InvalidTurnNumber(0),
      InvalidPenaltyPoints(9),
      ReasonRequired(),
      InvalidTransition(from: Reported(), to: Reported()),
      NotAllowed(),
      NotFound(),
    ];
    for (final error in errors) {
      expect(error.message, isNotEmpty);
    }
  });

  test('messages carry the limits from the domain', () {
    expect(const DescriptionTooShort(3).message, 'Opis mora imati bar 10 znakova (uneto: 3).');
    expect(const DescriptionTooLong(301).message, 'Opis može imati najviše 300 znakova.');
    expect(const InvalidTurnNumber(99).message, 'Broj krivine mora biti od 1 do 30.');
  });
}
