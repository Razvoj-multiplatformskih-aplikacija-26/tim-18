import 'package:api_client/api_client.dart';
import 'package:blocs/auth.dart';
import 'package:contract/contract.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:backoffice/data/fake_incident_repository.dart';
import 'package:backoffice/data/seed_data.dart';
import 'package:backoffice/data/server_connection.dart';
import 'package:backoffice/root_app.dart';
import 'package:backoffice/screens/incidents_screen.dart';
import 'package:backoffice/screens/login_screen.dart';

import 'pump_app.dart' show useWideScreen;

class _FakeGateway implements AuthGateway {
  AuthException? failure;

  @override
  Future<Session> signIn({required String username, required String password}) async {
    final failure = this.failure;
    if (failure != null) throw failure;
    return Session(token: 'tok', expiresAt: DateTime.now().add(const Duration(hours: 1)), user: demoDirector);
  }
}

Future<void> _pumpRoot(WidgetTester tester, {SessionStore? store, _FakeGateway? gateway}) async {
  useWideScreen(tester);
  final connection = ServerConnection(
    api: ApiClient(baseUrl: Uri.parse('http://localhost:8080'), clientApp: ClientApps.backoffice),
    store: store ?? InMemorySessionStore(),
    repository: FakeIncidentRepository(latency: const Duration(milliseconds: 10)),
    gateway: gateway ?? _FakeGateway(),
  );
  await tester.pumpWidget(BackofficeRoot(connection: connection));
  await tester.pumpAndSettle();
}

Future<void> _signIn(WidgetTester tester) async {
  await tester.enterText(find.byKey(const Key('username-field')), 'director1');
  await tester.enterText(find.byKey(const Key('password-field')), 'demo1234');
  await tester.tap(find.byKey(const Key('sign-in-button')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('without a saved login the app starts on the sign-in screen', (tester) async {
    await _pumpRoot(tester);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(IncidentsScreen), findsNothing);
  });

  testWidgets('empty fields are refused with a message', (tester) async {
    await _pumpRoot(tester);
    await tester.tap(find.byKey(const Key('sign-in-button')));
    await tester.pumpAndSettle();
    expect(find.text('Unesite korisničko ime.'), findsOneWidget);
    expect(find.text('Unesite lozinku.'), findsOneWidget);
  });

  testWidgets('wrong credentials are explained and the user stays on the screen', (tester) async {
    await _pumpRoot(tester, gateway: _FakeGateway()..failure = const AuthException(AuthFailure.invalidCredentials));
    await _signIn(tester);
    expect(find.text('Pogrešno korisničko ime ili lozinka.'), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('a server that does not answer is named', (tester) async {
    await _pumpRoot(tester, gateway: _FakeGateway()..failure = const AuthException(AuthFailure.unavailable));
    await _signIn(tester);
    expect(find.text('Server nije dostupan. Proverite vezu i pokušajte ponovo.'), findsOneWidget);
  });

  testWidgets('the wrong application says why', (tester) async {
    await _pumpRoot(
      tester,
      gateway: _FakeGateway()
        ..failure = const AuthException(AuthFailure.wrongApp, rule: WrongApp(ClientApp.backoffice)),
    );
    await _signIn(tester);
    expect(find.text('Backoffice je za osoblje trke.'), findsOneWidget);
  });

  testWidgets('signing in opens the list, signing out returns to sign-in', (tester) async {
    await _pumpRoot(tester);
    await _signIn(tester);
    expect(find.byType(IncidentsScreen), findsOneWidget);

    await tester.tap(find.byKey(const Key('sign-out-button')));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a saved login survives the restart', (tester) async {
    final saved = Session(token: 'tok', expiresAt: DateTime.now().add(const Duration(hours: 1)), user: demoDirector);
    await _pumpRoot(tester, store: InMemorySessionStore(saved));
    expect(find.byType(IncidentsScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('an expired login sends the user to sign-in and says so', (tester) async {
    final expired = Session(token: 'tok', expiresAt: DateTime.utc(2020), user: demoDirector);
    await _pumpRoot(tester, store: InMemorySessionStore(expired));
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Prijava je istekla. Prijavite se ponovo.'), findsOneWidget);
  });
}
