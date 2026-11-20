import 'package:blocs/auth.dart';

/// What a signed-out user reads. The reasons come from the BLoC as names; the
/// wording is decided here.
extension AuthNoticeMessage on AuthNotice {
  String get message => switch (this) {
    AuthNotice.sessionExpired => 'Prijava je istekla. Prijavite se ponovo.',
    AuthNotice.invalidCredentials => 'Pogrešno korisničko ime ili lozinka.',
    AuthNotice.serverUnavailable => 'Server nije dostupan. Proverite vezu i pokušajte ponovo.',
    AuthNotice.signInFailed => 'Prijava nije uspela. Pokušajte ponovo.',
  };
}
