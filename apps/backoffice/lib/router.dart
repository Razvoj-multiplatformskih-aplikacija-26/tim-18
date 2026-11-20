import 'package:blocs/auth.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import 'screens/incidents_screen.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'widgets/signed_in_scope.dart';

abstract final class Routes {
  static const incidents = 'incidents';
  static const login = 'login';
  static const splash = 'splash';
}

/// Without [auth] (tests, the fake setup) there is no login. With it, every
/// address except `/login` needs one: the redirect sends the user to sign in,
/// and back to the list afterwards.
GoRouter buildRouter({AuthBloc? auth, Listenable? refresh}) {
  final incidentRoutes = <RouteBase>[
    GoRoute(path: '/incidents', name: Routes.incidents, builder: (context, state) => const IncidentsScreen()),
  ];

  if (auth == null) return GoRouter(initialLocation: '/incidents', routes: incidentRoutes);

  return GoRouter(
    initialLocation: '/incidents',
    refreshListenable: refresh,
    redirect: (context, state) {
      final here = state.matchedLocation;
      return switch (auth.state) {
        AuthRestoring() => here == '/splash' ? null : '/splash',
        SigningIn() => null,
        SignedOut() => here == '/login' ? null : '/login',
        SignedIn() => here == '/login' || here == '/splash' ? '/incidents' : null,
      };
    },
    routes: [
      GoRoute(path: '/splash', name: Routes.splash, builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', name: Routes.login, builder: (context, state) => const LoginScreen()),
      ShellRoute(
        builder: (context, state, child) => SignedInScope(child: child),
        routes: incidentRoutes,
      ),
    ],
  );
}
