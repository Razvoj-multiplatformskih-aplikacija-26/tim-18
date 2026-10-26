import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/data/fake_incident_repository.dart';
import 'package:mobile/screens/report_screen.dart';
import 'package:mobile/widgets/incident_tile.dart';

import 'pump_app.dart';

Future<GoRouter> openForm(WidgetTester tester, {FakeIncidentRepository? repository}) async {
  final router = await pumpApp(tester, repository: repository);
  await tester.pumpAndSettle();
  router.go('/incidents/new');
  await tester.pumpAndSettle();
  return router;
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
  await tester.pumpAndSettle();
}

Future<void> tapInDialog(WidgetTester tester, String key) async {
  await tester.tap(find.byKey(Key(key)));
  await tester.pumpAndSettle();
}

void main() {
  group('report form', () {
    testWidgets('an empty form names every missing field', (tester) async {
      await openForm(tester);
      await tapSubmit(tester);

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

      expect(find.text('Broj krivine mora biti od 1 do 30.'), findsOneWidget);
      expect(find.text('Opis mora imati bar 10 znakova (uneto: 3).'), findsOneWidget);
      expect(find.byType(ReportScreen), findsOneWidget);
    });

    testWidgets('a valid report asks for confirmation, then is saved and shown first', (tester) async {
      await openForm(tester);
      await fillValidForm(tester);
      await tapSubmit(tester);

      expect(find.text('Pošalji prijavu?'), findsOneWidget);
      expect(find.text('Prijava se ne može povući.'), findsOneWidget);

      await tapInDialog(tester, 'confirm-report');

      expect(find.byType(ReportScreen), findsNothing);
      expect(find.text('Incident je prijavljen.'), findsOneWidget);
      final first = tester.widget<IncidentTile>(find.byType(IncidentTile).first);
      expect(first.incident.id.value, 'i-test');
    });

    testWidgets('backing out of the confirmation sends nothing', (tester) async {
      await openForm(tester);
      await fillValidForm(tester);
      await tapSubmit(tester);

      await tapInDialog(tester, 'cancel-report');

      expect(find.byType(ReportScreen), findsOneWidget);
      expect(find.text('Incident je prijavljen.'), findsNothing);
      expect(find.text('Vozač je pao u krivini 3.'), findsOneWidget);
    });

    testWidgets('reporting the same incident twice in a row warns about a duplicate', (tester) async {
      final router = await openForm(tester);
      await fillValidForm(tester);
      await tapSubmit(tester);
      await tapInDialog(tester, 'confirm-report');

      router.go('/incidents/new');
      await tester.pumpAndSettle();
      await fillValidForm(tester);
      await tapSubmit(tester);

      expect(find.text('Moguć duplikat'), findsOneWidget);
      expect(find.textContaining('Već ste prijavili sličan incident'), findsOneWidget);
      expect(find.text('Ipak prijavi'), findsOneWidget);

      await tapInDialog(tester, 'cancel-report');
      expect(find.byType(ReportScreen), findsOneWidget);
    });

    testWidgets('a storage failure keeps the form and says so', (tester) async {
      final repository = FakeIncidentRepository(latency: const Duration(milliseconds: 50));
      await openForm(tester, repository: repository);
      await fillValidForm(tester);
      await tapSubmit(tester);

      repository.failNextRequest();
      await tapInDialog(tester, 'confirm-report');

      expect(find.text('Prijava nije sačuvana. Pokušajte ponovo.'), findsOneWidget);
      expect(find.byType(ReportScreen), findsOneWidget);
      expect(find.text('Vozač je pao u krivini 3.'), findsOneWidget);
    });
  });
}
