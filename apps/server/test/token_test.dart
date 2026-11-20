import 'package:contract/contract.dart';
import 'package:domain/domain.dart';
import 'package:server/src/http.dart';
import 'package:server/src/token.dart';
import 'package:test/test.dart';

void main() {
  final start = DateTime.utc(2026, 11, 20, 10);
  var now = start;

  setUp(() => now = start);

  TokenService service({String secret = 'secret-for-tests-0123456789abcdef'}) =>
      TokenService(secret: secret, lifetime: const Duration(minutes: 60), now: () => now);

  Matcher refusedWith(String code) =>
      throwsA(isA<ApiException>().having((e) => e.error.code, 'code', code).having((e) => e.status, 'status', 401));

  test('a token the server issued is accepted', () {
    final issued = service().issue(const UserId('u-1'), app: ClientApp.mobile);
    final claims = service().verify(issued.token);
    expect(claims.userId, const UserId('u-1'));
    expect(claims.app, 'mobile');
    expect(issued.expiresAt, start.add(const Duration(minutes: 60)));
  });

  test('a token signed with another secret is refused', () {
    final foreign = service(secret: 'another-secret-0123456789abcdef!!')
        .issue(const UserId('u-1'), app: ClientApp.mobile);
    expect(() => service().verify(foreign.token), refusedWith(ErrorCodes.unauthorized));
  });

  test('a payload swapped under a valid signature is refused', () {
    final mine = service().issue(const UserId('u-marshal-1'), app: ClientApp.mobile).token.split('.');
    final other = service().issue(const UserId('u-director-1'), app: ClientApp.backoffice).token.split('.');
    final forged = '${mine[0]}.${other[1]}.${mine[2]}';
    expect(() => service().verify(forged), refusedWith(ErrorCodes.unauthorized));
  });

  test('garbage is refused, not thrown as something else', () {
    for (final garbage in ['', 'abc', 'a.b.c', '....']) {
      expect(() => service().verify(garbage), refusedWith(ErrorCodes.unauthorized));
    }
  });

  test('a token that ran out says the session expired', () {
    final issued = service().issue(const UserId('u-1'), app: ClientApp.backoffice);
    now = start.add(const Duration(minutes: 61));
    expect(() => service().verify(issued.token), refusedWith(ErrorCodes.sessionExpired));
  });
}
