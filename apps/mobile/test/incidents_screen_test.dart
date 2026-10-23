import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/fake_incident_repository.dart';
import 'package:mobile/screens/incident_detail_screen.dart';
import 'package:mobile/widgets/incident_tile.dart';

import 'pump_app.dart';

void main() {
  group('the four screen states', () {
    testWidgets('loading, then the incidents', (tester) async {
      await pumpApp(tester);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(IncidentTile), findsWidgets);
    });

    testWidgets('error with a retry button that loads the list', (tester) async {
      final repository = FakeIncidentRepository(latency: Duration.zero)..failNextRequest();
      await pumpApp(tester, repository: repository);
      await tester.pumpAndSettle();

      expect(find.text('Incidenti nisu učitani.'), findsOneWidget);
      expect(find.byType(IncidentTile), findsNothing);

      await tester.tap(find.text('Pokušaj ponovo'));
      await tester.pumpAndSettle();
      expect(find.byType(IncidentTile), findsWidgets);
    });

    testWidgets('empty list', (tester) async {
      final repository = FakeIncidentRepository(seed: const [], latency: Duration.zero);
      await pumpApp(tester, repository: repository);
      await tester.pumpAndSettle();

      expect(find.text('Nema prijavljenih incidenata.'), findsOneWidget);
      expect(find.byType(IncidentTile), findsNothing);
    });

    testWidgets('the menu makes the next request fail', (tester) async {
      await pumpApp(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('debug-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Simuliraj grešku sledećeg zahteva'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('debug-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Osveži'));
      await tester.pumpAndSettle();

      expect(find.text('Pokušaj ponovo'), findsOneWidget);
    });
  });

  group('incident detail', () {
    testWidgets('opens from the list and shows how the incident was handled', (tester) async {
      await pumpApp(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(IncidentTile).first);
      await tester.pumpAndSettle();

      expect(find.byType(IncidentDetailScreen), findsOneWidget);
      expect(find.text('Razlog: Prednost nije ostvarena.'), findsOneWidget);
    });

    testWidgets('an unknown id says so', (tester) async {
      final router = await pumpApp(tester);
      await tester.pumpAndSettle();

      router.go('/incidents/nepostojeci');
      await tester.pumpAndSettle();

      expect(find.text('Incident nije pronađen.'), findsOneWidget);
    });
  });
}
