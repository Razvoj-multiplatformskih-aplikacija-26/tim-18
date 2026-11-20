import 'package:equatable/equatable.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();
}

/// The app has started: look for a login that survived the restart.
final class AuthStarted extends AuthEvent {
  const AuthStarted();

  @override
  List<Object?> get props => const [];
}

final class SignInSubmitted extends AuthEvent {
  const SignInSubmitted({required this.username, required this.password});

  final String username;
  final String password;

  @override
  List<Object?> get props => [username, password];
}

final class SignOutRequested extends AuthEvent {
  const SignOutRequested();

  @override
  List<Object?> get props => const [];
}

/// The login ran out: its time passed, or the server refused the token.
final class SessionExpired extends AuthEvent {
  const SessionExpired();

  @override
  List<Object?> get props => const [];
}
