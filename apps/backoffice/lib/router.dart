import 'package:go_router/go_router.dart';

import 'screens/incidents_screen.dart';

abstract final class Routes {
  static const incidents = 'incidents';
}

GoRouter buildRouter() {
  return GoRouter(
    initialLocation: '/incidents',
    routes: [GoRoute(path: '/incidents', name: Routes.incidents, builder: (context, state) => const IncidentsScreen())],
  );
}
