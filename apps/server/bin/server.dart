import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:relic/relic.dart';
import 'package:server/config.dart';
import 'package:server/src/api.dart';
import 'package:server/src/http.dart';
import 'package:server/src/store.dart';
import 'package:server/src/team_notifier.dart';
import 'package:server/src/token.dart';

Future<void> main() async {
  final config = ServerConfig.fromEnvironment();

  final pool = Pool<void>.withEndpoints([
    Endpoint(
      host: config.dbHost,
      port: config.dbPort,
      database: config.dbName,
      username: config.dbUser,
      password: config.dbPassword,
    ),
  ], settings: const PoolSettings(maxConnectionCount: 10, sslMode: SslMode.disable));

  final api = Api(
    store: Store(pool),
    tokens: TokenService(secret: config.jwtSecret, lifetime: config.sessionDuration),
    notifier: FakeTeamNotifier(apiKey: config.penaltyApiKey),
  );

  final app = RelicApp()..any('/**', (Request request) => _adapt(api, request));

  await app.serve(address: InternetAddress.anyIPv4, port: config.port);
  stdout.writeln('Server radi na portu ${config.port}');
}

/// The only place that knows the web framework: it turns a framework request
/// into an [ApiRequest] and the [ApiResponse] back. All rules are in [Api].
Future<Response> _adapt(Api api, Request request) async {
  final headers = <String, String>{};
  for (final name in const ['authorization', 'x-client-app', 'content-type']) {
    final Object? raw = request.headers[name];
    final value = raw is Iterable ? raw.join(',') : raw?.toString();
    if (value != null && value.isNotEmpty) headers[name] = value;
  }

  final path = request.url.path.startsWith('/') ? request.url.path : '/${request.url.path}';
  final result = await api.handle(
    ApiRequest(
      method: request.method.name.toUpperCase(),
      path: path,
      query: request.url.queryParameters,
      headers: headers,
      body: await request.readAsString(),
    ),
  );

  return Response(
    result.status,
    headers: Headers.fromMap({
      for (final entry in result.headers.entries) entry.key: [entry.value],
    }),
    body: result.body.isEmpty
        ? Body.empty()
        : Body.fromString(result.body, mimeType: result.body.startsWith('ok') ? MimeType.plainText : MimeType.json),
  );
}
