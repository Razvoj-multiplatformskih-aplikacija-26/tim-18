import 'package:api_client/api_client.dart';
import 'package:blocs/auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keeps the login in the secure storage of the platform (Keychain, Keystore).
/// Only the session the server issued is stored, never the password.
final class SecureSessionStore implements SessionStore {
  SecureSessionStore({required this._key, FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage(mOptions: MacOsOptions(useDataProtectionKeyChain: false));

  final String _key;
  final FlutterSecureStorage _storage;

  @override
  Future<Session?> read() async {
    final text = await _storage.read(key: _key);
    return text == null ? null : decodeSession(text);
  }

  @override
  Future<void> write(Session session) => _storage.write(key: _key, value: encodeSession(session));

  @override
  Future<void> clear() => _storage.delete(key: _key);
}
