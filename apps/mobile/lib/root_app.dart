import 'package:blocs/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'auth/auth_refresh.dart';
import 'data/server_connection.dart';
import 'router.dart';
import 'theme/app_theme.dart';

/// The app as users get it: it talks to the server and starts with the login.
/// (`RaceDirectionApp` is the same screens over a repository without login.)
class RaceDirectionRoot extends StatefulWidget {
  const RaceDirectionRoot({super.key, required this.connection});

  final ServerConnection connection;

  @override
  State<RaceDirectionRoot> createState() => _RaceDirectionRootState();
}

class _RaceDirectionRootState extends State<RaceDirectionRoot> {
  late final AuthBloc _auth;
  late final AuthRefresh _refresh;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final connection = widget.connection;
    _auth = AuthBloc(gateway: connection.gateway, store: connection.store);
    // The server said the login is no longer good: say so and go to sign-in.
    connection.api.onSessionExpired = () => _auth.add(const SessionExpired());
    _refresh = AuthRefresh(_auth.stream);
    _router = buildRouter(auth: _auth, refresh: _refresh);
    _auth.add(const AuthStarted());
  }

  @override
  void dispose() {
    widget.connection.api.onSessionExpired = null;
    _router.dispose();
    _refresh.dispose();
    _auth.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<ServerConnection>.value(
      value: widget.connection,
      child: BlocProvider<AuthBloc>.value(
        value: _auth,
        child: BlocListener<AuthBloc, AuthState>(
          // No login, no token: nothing goes out with an old one.
          listener: (context, state) {
            if (state is! SignedIn) widget.connection.api.token = null;
          },
          child: MaterialApp.router(
            title: 'Race Direction',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            routerConfig: _router,
          ),
        ),
      ),
    );
  }
}
