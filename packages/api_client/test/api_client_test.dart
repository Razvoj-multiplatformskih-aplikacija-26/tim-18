import 'dart:async';
import 'dart:convert';

import 'package:api_client/api_client.dart';
import 'package:blocs/auth.dart';
import 'package:blocs/blocs.dart';
import 'package:contract/contract.dart';
import 'package:domain/domain.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mapping/mapping.dart';
import 'package:test/test.dart';

const marshal = User(id: UserId('u-marshal'), username: 'marshal1', role: Role.marshal);
final t0 = DateTime.utc(2026, 10, 18, 14, 5);

Incident incident(String id, {IncidentStatus status = const Reported()}) => Incident(
  id: IncidentId(id),
  reporterId: marshal.id,
  riderId: const RiderId('r-12'),
  kind: IncidentKind.crash,
  description: IncidentDescription.parse('Vozač je pao u krivini 3.').valueOrNull!,
  turn: TurnNumber.parse(3).valueOrNull!,
  reportedAt: t0,
  status: status,
);

http.Response json(int status, Object? body) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

ApiClient clientFor(Future<http.Response> Function(http.Request request) handler, {Duration? timeout}) => ApiClient(
  baseUrl: Uri.parse('http://localhost:8080'),
  clientApp: ClientApps.mobile,
  httpClient: MockClient(handler),
  timeout: timeout ?? const Duration(seconds: 2),
);

void main() {
  group('ApiIncidentRepository', () {
    test('asks for the next page until the server has no more, and sends the login', () async {
      final seen = <http.Request>[];
      final api = clientFor((request) async {
        seen.add(request);
        final cursor = request.url.queryParameters[QueryParams.cursor];
        return json(
          200,
          cursor == null
              ? IncidentPageDto(items: [incidentToDto(incident('i-2'))], nextCursor: 'c1').toJson()
              : IncidentPageDto(items: [incidentToDto(incident('i-1'))]).toJson(),
        );
      })..token = 'tok';

      final incidents = await ApiIncidentRepository(api).incidentsFor(marshal);

      expect(incidents.map((i) => i.id.value), ['i-2', 'i-1']);
      expect(seen, hasLength(2));
      expect(seen.last.url.queryParameters[QueryParams.cursor], 'c1');
      expect(seen.first.headers[ApiHeaders.authorization], 'Bearer tok');
      expect(seen.first.headers[ApiHeaders.clientApp], 'mobile');
    });

    test('a new report never names its reporter: the server takes it from the login', () async {
      late Map<String, Object?> sent;
      final api = clientFor((request) async {
        sent = jsonDecode(request.body) as Map<String, Object?>;
        return json(201, incidentToDto(incident('i-9')).toJson());
      });

      final saved = await ApiIncidentRepository(api).save(incident('i-9'));

      expect(saved.id.value, 'i-9');
      expect(sent.containsKey('reporterId'), isFalse);
      expect(sent['id'], 'i-9');
    });

    test('a decision goes to the server as a decision, not as a finished incident', () async {
      late http.Request seen;
      final decided = incident(
        'i-1',
        status: Confirmed(by: const UserId('u-director'), at: t0),
      );
      final api = clientFor((request) async {
        seen = request;
        return json(200, incidentToDto(decided).toJson());
      });

      await ApiIncidentRepository(api).update(decided);

      expect(seen.url.path, '/api/incidents/i-1/decision');
      expect(jsonDecode(seen.body), {'action': 'confirm'});
    });

    test('withdrawing sends DELETE and expects no body', () async {
      late http.Request seen;
      final api = clientFor((request) async {
        seen = request;
        return http.Response('', 204);
      });
      await ApiIncidentRepository(api).withdraw(const IncidentId('i-1'));
      expect(seen.method, 'DELETE');
      expect(seen.url.path, '/api/incidents/i-1');
    });

    test('a rule the server enforces comes back as that rule', () async {
      final api = clientFor((request) async => json(409, const ApiErrorDto(code: ErrorCodes.notWithdrawable).toJson()));
      await expectLater(
        ApiIncidentRepository(api).withdraw(const IncidentId('i-1')),
        throwsA(
          isA<RepositoryException>()
              .having((e) => e.failure, 'failure', RepositoryFailure.rejected)
              .having((e) => e.rule, 'rule', const NotWithdrawable()),
        ),
      );
    });

    test('a code from a newer server is still a refusal, without a rule, and nothing crashes', () async {
      final api = clientFor(
        (request) async => json(422, const ApiErrorDto(code: 'rule_from_the_future', data: {'x': 1}).toJson()),
      );
      await expectLater(
        ApiIncidentRepository(api).withdraw(const IncidentId('i-1')),
        throwsA(
          isA<RepositoryException>()
              .having((e) => e.failure, 'failure', RepositoryFailure.rejected)
              .having((e) => e.rule, 'rule', isNull),
        ),
      );
    });

    test('a server that errors out counts as unavailable', () async {
      final api = clientFor((request) async => http.Response('boom', 500));
      await expectLater(
        ApiIncidentRepository(api).incidentsFor(marshal),
        throwsA(isA<RepositoryException>().having((e) => e.failure, 'failure', RepositoryFailure.unavailable)),
      );
    });

    test('no connection counts as unavailable', () async {
      final api = clientFor((request) async => throw http.ClientException('no route to host'));
      await expectLater(
        ApiIncidentRepository(api).incidentsFor(marshal),
        throwsA(isA<RepositoryException>().having((e) => e.failure, 'failure', RepositoryFailure.unavailable)),
      );
    });

    test('a server that never answers does not leave the screen loading for ever', () async {
      final never = Completer<http.Response>();
      final api = clientFor((request) => never.future, timeout: const Duration(milliseconds: 50));
      await expectLater(
        ApiIncidentRepository(api).incidentsFor(marshal),
        throwsA(isA<RepositoryException>().having((e) => e.failure, 'failure', RepositoryFailure.unavailable)),
      );
    });

    test('an answer that is not what the contract says is a plain failure', () async {
      final api = clientFor((request) async => json(200, {'unexpected': true}));
      await expectLater(ApiIncidentRepository(api).incidentsFor(marshal), throwsA(isA<RepositoryException>()));
    });
  });

  group('session', () {
    test('an expired login tells the app, once the server says so', () async {
      var told = 0;
      final api = clientFor((request) async => json(401, const ApiErrorDto(code: ErrorCodes.sessionExpired).toJson()))
        ..token = 'old'
        ..onSessionExpired = () => told++;

      await expectLater(
        ApiIncidentRepository(api).incidentsFor(marshal),
        throwsA(isA<RepositoryException>().having((e) => e.failure, 'failure', RepositoryFailure.sessionExpired)),
      );
      expect(told, 1);
    });

    test('a wrong password is not an expired session', () async {
      var told = 0;
      final api = clientFor(
        (request) async => json(401, const ApiErrorDto(code: ErrorCodes.invalidCredentials).toJson()),
      )..onSessionExpired = () => told++;

      await expectLater(
        ApiAuthGateway(api).signIn(username: 'marshal1', password: 'x'),
        throwsA(isA<AuthException>().having((e) => e.failure, 'failure', AuthFailure.invalidCredentials)),
      );
      expect(told, 0);
    });

    test('sign-in sends no token and gives a session', () async {
      late http.Request seen;
      final api = clientFor((request) async {
        seen = request;
        return json(
          200,
          LoginResponseDto(
            token: 'tok',
            expiresAt: DateTime.utc(2026, 11, 20, 12).toIso8601String(),
            user: userToDto(marshal),
          ).toJson(),
        );
      })..token = 'stale';

      final session = await ApiAuthGateway(api).signIn(username: 'marshal1', password: 'demo1234');

      expect(seen.headers.containsKey(ApiHeaders.authorization), isFalse);
      expect(session.token, 'tok');
      expect(session.user, marshal);
    });

    test('a marshal in the backoffice is told why, with the rule', () async {
      final api = clientFor(
        (request) async => json(403, domainErrorToDto(const WrongApp(ClientApp.backoffice)).toJson()),
      );
      await expectLater(
        ApiAuthGateway(api).signIn(username: 'marshal1', password: 'demo1234'),
        throwsA(
          isA<AuthException>()
              .having((e) => e.failure, 'failure', AuthFailure.wrongApp)
              .having((e) => e.rule, 'rule', const WrongApp(ClientApp.backoffice)),
        ),
      );
    });

    test('the stored form of a session keeps the token and the user, and reads back', () {
      final session = Session(token: 'tok', expiresAt: DateTime.utc(2026, 11, 20, 12), user: marshal);
      final text = encodeSession(session);
      expect(text.contains('password'), isFalse);
      expect(decodeSession(text), session);
    });

    test('a stored value that is garbage is no session', () {
      expect(decodeSession('not json'), isNull);
      expect(decodeSession('{"token": 1}'), isNull);
    });
  });
}
