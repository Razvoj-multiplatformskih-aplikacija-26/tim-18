import 'session.dart';

/// Where the login survives a restart. Each platform plugs in its own: the
/// secure storage of the system (Keychain, Keystore, Credential Manager,
/// libsecret) where there is one, the browser's storage on the web. The
/// password is never stored, only the session the server issued.
abstract interface class SessionStore {
  Future<Session?> read();

  Future<void> write(Session session);

  Future<void> clear();
}

/// For tests and for a session that should not outlive the process.
final class InMemorySessionStore implements SessionStore {
  InMemorySessionStore([this._session]);

  Session? _session;

  @override
  Future<Session?> read() async => _session;

  @override
  Future<void> write(Session session) async => _session = session;

  @override
  Future<void> clear() async => _session = null;
}
