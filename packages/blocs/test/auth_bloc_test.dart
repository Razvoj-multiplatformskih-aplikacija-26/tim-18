import 'package:blocs/auth.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';

import 'fakes.dart';

final class FakeGateway implements AuthGateway {
  AuthException? failWith;
  int calls = 0;
  Session Function() session = () =>
      Session(token: 'tok', expiresAt: DateTime.now().add(const Duration(hours: 1)), user: marshal);

  @override
  Future<Session> signIn({required String username, required String password}) async {
    calls++;
    final failure = failWith;
    if (failure != null) throw failure;
    return session();
  }
}

final class BrokenStore implements SessionStore {
  @override
  Future<Session?> read() async => throw StateError('keychain locked');

  @override
  Future<void> write(Session session) async => throw StateError('keychain locked');

  @override
  Future<void> clear() async => throw StateError('keychain locked');
}

void main() {
  late FakeGateway gateway;
  late InMemorySessionStore store;
  var now = DateTime.utc(2026, 11, 20, 10);

  AuthBloc build({SessionStore? sessionStore}) {
    final bloc = AuthBloc(gateway: gateway, store: sessionStore ?? store, now: () => now);
    addTearDown(bloc.close);
    return bloc;
  }

  Session sessionExpiringIn(Duration lifetime) => Session(token: 'tok', expiresAt: now.add(lifetime), user: marshal);

  Future<void> expectStates(AuthBloc bloc, AuthEvent event, List<Object> states) async {
    final expectation = expectLater(bloc.stream, emitsInOrder(states));
    bloc.add(event);
    await expectation;
  }

  setUp(() {
    gateway = FakeGateway();
    store = InMemorySessionStore();
    now = DateTime.utc(2026, 11, 20, 10);
    gateway.session = () => sessionExpiringIn(const Duration(hours: 1));
  });

  group('on start', () {
    test('with nothing stored the user is signed out, without a notice', () async {
      await expectStates(build(), const AuthStarted(), [const SignedOut()]);
    });

    test('a login that survived the restart signs the user straight in', () async {
      final session = sessionExpiringIn(const Duration(hours: 1));
      store = InMemorySessionStore(session);
      await expectStates(build(), const AuthStarted(), [SignedIn(session)]);
    });

    test('a login that ran out while the app was closed says so and is forgotten', () async {
      store = InMemorySessionStore(sessionExpiringIn(const Duration(minutes: -1)));
      await expectStates(build(), const AuthStarted(), [const SignedOut(notice: AuthNotice.sessionExpired)]);
      expect(await store.read(), isNull);
    });

    test('a store that cannot be read is an empty store', () async {
      await expectStates(build(sessionStore: BrokenStore()), const AuthStarted(), [const SignedOut()]);
    });
  });

  group('signing in', () {
    test('keeps the session so it survives a restart', () async {
      final bloc = build();
      await expectStates(bloc, const SignInSubmitted(username: ' marshal1 ', password: 'demo1234'), [
        const SigningIn(),
        isA<SignedIn>(),
      ]);
      expect(await store.read(), isNotNull);
    });

    test('a wrong password says so', () async {
      gateway.failWith = const AuthException(AuthFailure.invalidCredentials);
      await expectStates(build(), const SignInSubmitted(username: 'marshal1', password: 'x'), [
        const SigningIn(),
        const SignedOut(notice: AuthNotice.invalidCredentials),
      ]);
      expect(await store.read(), isNull);
    });

    test('the wrong application is explained by the rule, not by a notice', () async {
      gateway.failWith = const AuthException(AuthFailure.wrongApp, rule: WrongApp(ClientApp.backoffice));
      await expectStates(build(), const SignInSubmitted(username: 'marshal1', password: 'demo1234'), [
        const SigningIn(),
        const SignedOut(rule: WrongApp(ClientApp.backoffice)),
      ]);
    });

    test('an unreachable server says so', () async {
      gateway.failWith = const AuthException(AuthFailure.unavailable);
      await expectStates(build(), const SignInSubmitted(username: 'marshal1', password: 'demo1234'), [
        const SigningIn(),
        const SignedOut(notice: AuthNotice.serverUnavailable),
      ]);
    });

    test('a store that cannot be written does not stop the sign-in', () async {
      await expectStates(
        build(sessionStore: BrokenStore()),
        const SignInSubmitted(username: 'marshal1', password: 'demo1234'),
        [const SigningIn(), isA<SignedIn>()],
      );
    });
  });

  group('ending a login', () {
    test('signing out forgets the session', () async {
      final bloc = build();
      await expectStates(bloc, const SignInSubmitted(username: 'marshal1', password: 'demo1234'), [
        const SigningIn(),
        isA<SignedIn>(),
      ]);
      await expectStates(bloc, const SignOutRequested(), [const SignedOut()]);
      expect(await store.read(), isNull);
    });

    test('when the server says the login is over, the user is told and sent back', () async {
      final bloc = build();
      await expectStates(bloc, const SignInSubmitted(username: 'marshal1', password: 'demo1234'), [
        const SigningIn(),
        isA<SignedIn>(),
      ]);
      await expectStates(bloc, const SessionExpired(), [const SignedOut(notice: AuthNotice.sessionExpired)]);
      expect(await store.read(), isNull);
    });

    test('the login ends by itself when its time comes, with nobody doing anything', () async {
      gateway.session = () =>
          Session(token: 'tok', expiresAt: DateTime.now().add(const Duration(milliseconds: 80)), user: marshal);
      final bloc = AuthBloc(gateway: gateway, store: store);
      addTearDown(bloc.close);

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([const SigningIn(), isA<SignedIn>(), const SignedOut(notice: AuthNotice.sessionExpired)]),
      );
      bloc.add(const SignInSubmitted(username: 'marshal1', password: 'demo1234'));
      await expectation;
    });

    test('a late expiry message changes nothing for someone already signed out', () async {
      final bloc = build();
      await expectStates(bloc, const AuthStarted(), [const SignedOut()]);
      bloc.add(const SessionExpired());
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(bloc.state, const SignedOut());
    });
  });
}
