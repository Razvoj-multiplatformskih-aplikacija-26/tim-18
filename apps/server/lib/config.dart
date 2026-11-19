import 'dart:io';

/// Podešavanja servera iz promenljivih okruženja (.env preko Docker Compose-a).
final class ServerConfig {
  const ServerConfig({
    required this.dbHost,
    required this.dbPort,
    required this.dbName,
    required this.dbUser,
    required this.dbPassword,
    required this.port,
    required this.jwtSecret,
    required this.sessionDuration,
    required this.penaltyApiKey,
  });

  factory ServerConfig.fromEnvironment([Map<String, String>? env]) {
    final values = env ?? Platform.environment;
    String need(String key) {
      final value = values[key];
      if (value == null || value.isEmpty) {
        throw StateError('Nedostaje promenljiva okruženja $key (videti .env.example).');
      }
      return value;
    }

    return ServerConfig(
      dbHost: values['DB_HOST'] ?? 'localhost',
      dbPort: int.parse(values['DB_PORT'] ?? '5432'),
      dbName: need('DB_NAME'),
      dbUser: need('DB_USER'),
      dbPassword: need('DB_PASSWORD'),
      port: int.parse(values['SERVER_PORT'] ?? '8080'),
      jwtSecret: need('JWT_SECRET'),
      sessionDuration: Duration(minutes: int.parse(values['SESSION_MINUTES'] ?? '60')),
      penaltyApiKey: values['PENALTY_API_KEY'] ?? '',
    );
  }

  final String dbHost;
  final int dbPort;
  final String dbName;
  final String dbUser;
  final String dbPassword;
  final int port;
  final String jwtSecret;
  final Duration sessionDuration;
  final String penaltyApiKey;
}
