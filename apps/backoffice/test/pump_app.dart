import 'package:backoffice/app.dart';
import 'package:backoffice/app_dependencies.dart';
import 'package:backoffice/data/fake_incident_repository.dart';
import 'package:backoffice/data/seed_data.dart';
import 'package:backoffice/router.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// The backoffice is made for big screens, so tests use one.
void useWideScreen(WidgetTester tester, {double height = 1200}) {
  tester.view.physicalSize = Size(1400, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<GoRouter> pumpApp(WidgetTester tester, {FakeIncidentRepository? repository, User user = demoDirector}) async {
  final fake = repository ?? FakeIncidentRepository(latency: const Duration(milliseconds: 50));
  final router = buildRouter();
  addTearDown(router.dispose);
  await tester.pumpWidget(
    BackofficeApp(
      router: router,
      dependencies: AppDependencies(
        repository: fake,
        user: user,
        onFailNextRequest: fake.failNextRequest,
        newId: () => const IncidentId('i-test'),
        now: () => DateTime.utc(2026, 10, 20, 12),
      ),
    ),
  );
  return router;
}
