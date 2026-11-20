import 'package:api_client/api_client.dart';
import 'package:blocs/auth.dart';
import 'package:blocs/blocs.dart';
import 'package:contract/contract.dart';

import '../auth/secure_session_store.dart';

/// Where the server is. Desktop and the browser run on the same computer as
/// the server, so it is localhost; another address goes in
/// `--dart-define=API_URL=http://<adresa>:8080`.
Uri serverUrl() {
  const fromEnvironment = String.fromEnvironment('API_URL');
  if (fromEnvironment.isNotEmpty) return Uri.parse(fromEnvironment);
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
    api: ApiClient(baseUrl: serverUrl(), clientApp: ClientApps.backoffice),
    store: SecureSessionStore(key: 'race_direction.backoffice.session'),
  );

  final ApiClient api;
  final SessionStore store;
  final IncidentRepository repository;
  final AuthGateway gateway;
}
