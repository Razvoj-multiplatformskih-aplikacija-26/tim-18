import 'package:go_router/go_router.dart';

import 'screens/incident_detail_screen.dart';
import 'screens/incidents_screen.dart';
import 'screens/report_screen.dart';

abstract final class Routes {
  static const incidents = 'incidents';
  static const report = 'report';
  static const incident = 'incident';
}

/// One address per screen. `/incidents/new` is declared before
/// `/incidents/:id`, otherwise "new" would be read as an incident id.
GoRouter buildRouter() {
  return GoRouter(
    initialLocation: '/incidents',
    routes: [
      GoRoute(
        path: '/incidents',
        name: Routes.incidents,
        builder: (context, state) => const IncidentsScreen(),
        routes: [
          GoRoute(path: 'new', name: Routes.report, builder: (context, state) => const ReportScreen()),
          GoRoute(
            path: ':id',
            name: Routes.incident,
            builder: (context, state) => IncidentDetailScreen(incidentId: state.pathParameters['id']!),
          ),
        ],
      ),
    ],
  );
}
