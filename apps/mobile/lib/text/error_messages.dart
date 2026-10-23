import 'package:domain/domain.dart';

/// Serbian wording for every domain error. The rules themselves live in the
/// domain package; this file only decides what the user reads.
extension DomainErrorMessage on DomainError {
  String get message => switch (this) {
    DescriptionTooShort(:final length) =>
      'Opis mora imati bar ${IncidentDescription.minLength} znakova (uneto: $length).',
    DescriptionTooLong() => 'Opis može imati najviše ${IncidentDescription.maxLength} znakova.',
    InvalidTurnNumber() => 'Broj krivine mora biti od ${TurnNumber.min} do ${TurnNumber.max}.',
    InvalidPenaltyPoints() => 'Kazneni poeni moraju biti od 0 do ${Penalty.maxPoints}.',
    ReasonRequired() => 'Razlog je obavezan.',
    InvalidTransition() => 'Ova promena stanja nije dozvoljena.',
    NotAllowed() => 'Nemate dozvolu za ovu akciju.',
    NotFound() => 'Traženi zapis ne postoji.',
  };
}
