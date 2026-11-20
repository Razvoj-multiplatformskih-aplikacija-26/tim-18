import 'package:domain/domain.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  group('canSignIn', () {
    test('a marshal belongs in the mobile app only', () {
      expect(AccessPolicy.canSignIn(marshal, ClientApp.mobile), isTrue);
      expect(AccessPolicy.canSignIn(marshal, ClientApp.backoffice), isFalse);
    });

    test('the direction belongs in the backoffice only', () {
      expect(AccessPolicy.canSignIn(director, ClientApp.backoffice), isTrue);
      expect(AccessPolicy.canSignIn(director, ClientApp.mobile), isFalse);
    });
  });

  test('WrongApp is equal by the application that refused', () {
    expect(const WrongApp(ClientApp.backoffice), const WrongApp(ClientApp.backoffice));
    expect(const WrongApp(ClientApp.backoffice), isNot(const WrongApp(ClientApp.mobile)));
  });
}
