import 'dart:async';

import 'package:bloc/bloc.dart';

import 'auth_event.dart';
import 'auth_gateway.dart';
import 'auth_state.dart';
import 'session.dart';
import 'session_store.dart';

/// Shared by both apps: signing in, keeping the login across restarts, and
/// ending it when the user signs out or the time runs out.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required this._gateway, required this._store, DateTime Function()? now})
    : _now = now ?? DateTime.now,
      super(const AuthRestoring()) {
    on<AuthStarted>(_onStarted);
    on<SignInSubmitted>(_onSignIn);
    on<SignOutRequested>(_onSignOut);
    on<SessionExpired>(_onExpired);
  }

  final AuthGateway _gateway;
  final SessionStore _store;
  final DateTime Function() _now;
  Timer? _expiry;

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    final stored = await _readQuietly();
    if (stored == null) {
      emit(const SignedOut());
      return;
    }
    if (stored.hasExpired(_now())) {
      await _clearQuietly();
      emit(const SignedOut(notice: AuthNotice.sessionExpired));
      return;
    }
    _watchExpiry(stored);
    emit(SignedIn(stored));
  }

  Future<void> _onSignIn(SignInSubmitted event, Emitter<AuthState> emit) async {
    if (state is SigningIn) return;
    emit(const SigningIn());
    try {
      final session = await _gateway.signIn(username: event.username.trim(), password: event.password);
      await _writeQuietly(session);
      _watchExpiry(session);
      emit(SignedIn(session));
    } on AuthException catch (failure) {
      final rule = failure.failure == AuthFailure.wrongApp ? failure.rule : null;
      emit(SignedOut(notice: rule == null ? _noticeFor(failure.failure) : null, rule: rule));
    }
  }

  Future<void> _onSignOut(SignOutRequested event, Emitter<AuthState> emit) async {
    _expiry?.cancel();
    await _clearQuietly();
    emit(const SignedOut());
  }

  Future<void> _onExpired(SessionExpired event, Emitter<AuthState> emit) async {
    if (state is! SignedIn) return;
    _expiry?.cancel();
    await _clearQuietly();
    emit(const SignedOut(notice: AuthNotice.sessionExpired));
  }

  AuthNotice _noticeFor(AuthFailure failure) => switch (failure) {
    AuthFailure.invalidCredentials => AuthNotice.invalidCredentials,
    AuthFailure.unavailable => AuthNotice.serverUnavailable,
    AuthFailure.wrongApp || AuthFailure.other => AuthNotice.signInFailed,
  };

  /// The login ends by itself when its time comes, even if the user does
  /// nothing and no call is made.
  void _watchExpiry(Session session) {
    _expiry?.cancel();
    final remaining = session.expiresAt.difference(_now());
    _expiry = Timer(remaining.isNegative ? Duration.zero : remaining, () => add(const SessionExpired()));
  }

  // A store that cannot be read is an empty store, and one that cannot be
  // written only costs the user a new sign-in after a restart.
  Future<Session?> _readQuietly() async {
    try {
      return await _store.read();
    } on Object {
      return null;
    }
  }

  Future<void> _writeQuietly(Session session) async {
    try {
      await _store.write(session);
    } on Object {
      // see above
    }
  }

  Future<void> _clearQuietly() async {
    try {
      await _store.clear();
    } on Object {
      // see above
    }
  }

  @override
  Future<void> close() {
    _expiry?.cancel();
    return super.close();
  }
}
