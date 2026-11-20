import 'package:api_client/api_client.dart';
import 'package:blocs/auth.dart';
import 'package:blocs/blocs.dart';
import 'package:contract/contract.dart';
import 'package:flutter/foundation.dart';

import '../auth/secure_session_store.dart';

/// Where the server is, per platform. The Android emulator reaches the
/// computer under 10.0.2.2; the iOS simulator, desktop and the browser use
/// localhost. A phone in the same network passes
/// `--dart-define=API_URL=http://<ip računara>:8080`.
Uri serverUrl() {
  const fromEnvironment = String.fromEnvironment('API_URL');
  if (fromEnvironment.isNotEmpty) return Uri.parse(fromEnvironment);
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) return Uri.parse('http://10.0.2.2:8080');
  return Uri.parse('http://localhost:8080');
}

/// Everything that talks to the server, built once and shared by the screens
/// through the app. Tests pass their own [store] and, instead of the server,
/// their own [repository] and [gateway].
final class ServerConnection {
  ServerConnection({required this.api, required this.store, IncidentRepository? repository, AuthGateway? gateway})
    : repository = repository ?? ApiIncidentRepository(api),
      gateway = gateway ?? ApiAuthGateway(api);

  factory ServerConnection.real() => ServerConnection(
    api: ApiClient(baseUrl: serverUrl(), clientApp: ClientApps.mobile),
    store: SecureSessionStore(key: 'race_direction.mobile.session'),
  );

  final ApiClient api;
  final SessionStore store;
  final IncidentRepository repository;
  final AuthGateway gateway;
}
