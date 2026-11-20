import 'package:domain/domain.dart';

import 'session.dart';

/// The port through which an app signs in. The app supplies an implementation
/// that talks to the server.
abstract interface class AuthGateway {
  /// Throws [AuthException] when the user cannot be signed in.
  Future<Session> signIn({required String username, required String password});
}

enum AuthFailure {
  invalidCredentials,

  /// A valid user in the wrong application (a marshal in the backoffice).
  wrongApp,

  /// No answer from the server.
  unavailable,

  other,
}

final class AuthException implements Exception {
  const AuthException(this.failure, {this.rule});

  final AuthFailure failure;

  /// For [AuthFailure.wrongApp]: the rule, so the app can say why.
  final DomainError? rule;

  @override
  String toString() => 'AuthException($failure)';
}
