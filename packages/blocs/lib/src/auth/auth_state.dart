import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';

import 'session.dart';

/// What a signed-out user should be told.
enum AuthNotice { sessionExpired, invalidCredentials, serverUnavailable, signInFailed }

sealed class AuthState extends Equatable {
  const AuthState();
}

/// Looking in the store for a login that survived the restart.
final class AuthRestoring extends AuthState {
  const AuthRestoring();

  @override
  List<Object?> get props => const [];
}

final class SignedOut extends AuthState {
  const SignedOut({this.notice, this.rule});

  final AuthNotice? notice;

  /// Set when the user was refused for a rule of the domain (wrong application).
  final DomainError? rule;

  @override
  List<Object?> get props => [notice, rule];
}

final class SigningIn extends AuthState {
  const SigningIn();

  @override
  List<Object?> get props => const [];
}

final class SignedIn extends AuthState {
  const SignedIn(this.session);

  final Session session;

  @override
  List<Object?> get props => [session];
}
