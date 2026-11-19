import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:relic/relic.dart';
import 'package:server/config.dart';

Future<void> main() async {
  final config = ServerConfig.fromEnvironment();

  final db = await Connection.open(
    Endpoint(
      host: config.dbHost,
      port: config.dbPort,
      database: config.dbName,
      username: config.dbUser,
      password: config.dbPassword,
    ),
    settings: const ConnectionSettings(sslMode: SslMode.disable),
  );

  final app = RelicApp()
    ..get('/health', (Request request) async {
      final row = await db.execute('SELECT count(*) FROM incidents');
      final incidents = row.first.first as int;
      return Response.ok(body: Body.fromString('ok, incidents: $incidents'));
    });

  await app.serve(address: InternetAddress.anyIPv4, port: config.port);
  stdout.writeln('Server radi na portu ${config.port}');
}
