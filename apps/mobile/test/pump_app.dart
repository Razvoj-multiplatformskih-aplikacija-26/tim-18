import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/app.dart';
import 'package:mobile/app_dependencies.dart';
import 'package:mobile/data/fake_incident_repository.dart';
import 'package:mobile/data/seed_data.dart';
import 'package:mobile/router.dart';

/// Starts the app on a fake repository. Returns the router so tests can jump
/// to any address.
Future<GoRouter> pumpApp(WidgetTester tester, {FakeIncidentRepository? repository, User user = demoMarshal}) async {
  final fake = repository ?? FakeIncidentRepository(latency: const Duration(milliseconds: 50));
  final router = buildRouter();
  addTearDown(router.dispose);
  await tester.pumpWidget(
    RaceDirectionApp(
      router: router,
      dependencies: AppDependencies(repository: fake, user: user, onFailNextRequest: fake.failNextRequest),
    ),
  );
  return router;
}
