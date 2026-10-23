import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/fake_incident_repository.dart';
import 'package:mobile/screens/report_screen.dart';
import 'package:mobile/widgets/incident_tile.dart';

import 'pump_app.dart';

Future<void> openForm(WidgetTester tester, {FakeIncidentRepository? repository}) async {
  final router = await pumpApp(tester, repository: repository);
  await tester.pumpAndSettle();
  router.go('/incidents/new');
  await tester.pumpAndSettle();
}

Future<void> fillValidForm(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('rider-field')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('#27 Marko Ilić').last);
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(const Key('kind-field')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Pad').last);
  await tester.pumpAndSettle();

  await tester.enterText(find.byKey(const Key('turn-field')), '3');
  await tester.enterText(find.byKey(const Key('description-field')), 'Vozač je pao u krivini 3.');
}

Future<void> tapSubmit(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(const Key('submit-button')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('submit-button')));
}

void main() {
  group('report form', () {
    testWidgets('an empty form names every missing field', (tester) async {
      await openForm(tester);
      await tapSubmit(tester);
      await tester.pumpAndSettle();

      expect(find.text('Izaberite vozača.'), findsOneWidget);
      expect(find.text('Izaberite vrstu incidenta.'), findsOneWidget);
      expect(find.text('Unesite broj krivine.'), findsOneWidget);
      expect(find.text('Opis mora imati bar 10 znakova (uneto: 0).'), findsOneWidget);
    });

    testWidgets('rule messages come from the domain rules', (tester) async {
      await openForm(tester);
      await tester.enterText(find.byKey(const Key('turn-field')), '99');
      await tester.enterText(find.byKey(const Key('description-field')), 'pad');
      await tapSubmit(tester);
      await tester.pumpAndSettle();

      expect(find.text('Broj krivine mora biti od 1 do 30.'), findsOneWidget);
      expect(find.text('Opis mora imati bar 10 znakova (uneto: 3).'), findsOneWidget);
      expect(find.byType(ReportScreen), findsOneWidget);
    });

    testWidgets('a valid report is saved and shown first in the list', (tester) async {
      await openForm(tester);
      await fillValidForm(tester);
      await tapSubmit(tester);
      await tester.pumpAndSettle();

      expect(find.byType(ReportScreen), findsNothing);
      expect(find.text('Incident je prijavljen.'), findsOneWidget);
      final first = tester.widget<IncidentTile>(find.byType(IncidentTile).first);
      expect(first.incident.id.value, 'i-test');
    });

    testWidgets('a storage failure keeps the form and says so', (tester) async {
      final repository = FakeIncidentRepository(latency: const Duration(milliseconds: 50));
      await openForm(tester, repository: repository);
      await fillValidForm(tester);

      repository.failNextRequest();
      await tapSubmit(tester);
      await tester.pumpAndSettle();

      expect(find.text('Prijava nije sačuvana. Pokušajte ponovo.'), findsOneWidget);
      expect(find.byType(ReportScreen), findsOneWidget);
      expect(find.text('Vozač je pao u krivini 3.'), findsOneWidget);
    });
  });
}
