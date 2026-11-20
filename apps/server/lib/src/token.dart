import 'dart:convert';

import 'package:contract/contract.dart';
import 'package:crypto/crypto.dart';
import 'package:domain/domain.dart';

import 'http.dart';

final class TokenClaims {
  const TokenClaims({required this.userId, required this.app, required this.expiresAt});

  final UserId userId;

  /// The application the user signed in to.
  final String app;
  final DateTime expiresAt;
}

/// The login the server issues: a signed token (HS256) with the user, the
/// application and the expiry. The server believes nothing about the caller
/// that is not in a token it signed itself, and it checks the token on every
/// call. The lifetime comes from the server's settings.
final class TokenService {
  TokenService({required String secret, required this.lifetime, DateTime Function()? now})
    : _key = utf8.encode(secret),
      _now = now ?? DateTime.now;

  final List<int> _key;
  final Duration lifetime;
  final DateTime Function() _now;

  ({String token, DateTime expiresAt}) issue(UserId user, {required ClientApp app}) {
    final issued = _seconds(_now());
    final expires = issued + lifetime.inSeconds;
    final header = _encode(utf8.encode(jsonEncode({'alg': 'HS256', 'typ': 'JWT'})));
    final payload = _encode(
      utf8.encode(jsonEncode({'sub': user.value, 'app': app.name, 'iat': issued, 'exp': expires})),
    );
    final signingInput = '$header.$payload';
    return (
      token: '$signingInput.${_encode(_sign(signingInput))}',
      expiresAt: DateTime.fromMillisecondsSinceEpoch(expires * 1000, isUtc: true),
    );
  }

  /// The claims of a valid token. Throws [ApiException]: `unauthorized` for a
  /// token that is not ours, `session_expired` for one that ran out.
  TokenClaims verify(String token) {
    ApiException unauthorized() => ApiException.coded(401, ErrorCodes.unauthorized);

    final parts = token.split('.');
    if (parts.length != 3) throw unauthorized();

    final List<int> given;
    final Object? payload;
    try {
      given = _decode(parts[2]);
      payload = jsonDecode(utf8.decode(_decode(parts[1])));
    } on FormatException {
      throw unauthorized();
    }
    if (!_sameBytes(_sign('${parts[0]}.${parts[1]}'), given)) throw unauthorized();

    if (payload is! Map<String, Object?>) throw unauthorized();
    final sub = payload['sub'];
    final app = payload['app'];
    final exp = payload['exp'];
    if (sub is! String || app is! String || exp is! int) throw unauthorized();

    if (_seconds(_now()) >= exp) throw ApiException.coded(401, ErrorCodes.sessionExpired);
    return TokenClaims(
      userId: UserId(sub),
      app: app,
      expiresAt: DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true),
    );
  }

  List<int> _sign(String input) => Hmac(sha256, _key).convert(utf8.encode(input)).bytes;

  static int _seconds(DateTime time) => time.millisecondsSinceEpoch ~/ 1000;

  static String _encode(List<int> bytes) => base64Url.encode(bytes).replaceAll('=', '');

  static List<int> _decode(String text) => base64Url.decode(base64Url.normalize(text));

  /// Compares without stopping at the first difference.
  static bool _sameBytes(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var difference = 0;
    for (var i = 0; i < a.length; i++) {
      difference |= a[i] ^ b[i];
    }
    return difference == 0;
  }
}
