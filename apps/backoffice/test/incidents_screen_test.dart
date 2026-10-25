import 'package:backoffice/data/fake_incident_repository.dart';
import 'package:backoffice/widgets/incident_panel.dart';
import 'package:backoffice/widgets/incident_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pump_app.dart';

Future<void> openTable(WidgetTester tester) async {
  useWideScreen(tester);
  await pumpApp(tester);
  await tester.pumpAndSettle();
}

Future<void> chooseStage(WidgetTester tester, String label) async {
  await tester.tap(find.widgetWithText(ChoiceChip, label));
  await tester.pumpAndSettle();
}

Future<void> chooseRider(WidgetTester tester, String label) async {
  await tester.tap(find.byKey(const Key('rider-filter')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

void main() {
  group('table and filters', () {
    testWidgets('the direction sees the incidents of every marshal', (tester) async {
      await openTable(tester);

      expect(find.byType(IncidentRow), findsNWidgets(15));
      expect(find.text('Prikazano 15 od 15'), findsOneWidget);
    });

    testWidgets('filters by stage', (tester) async {
      await openTable(tester);
      await chooseStage(tester, 'Potvrđen');

      expect(find.byType(IncidentRow), findsNWidgets(2));
      expect(find.text('Prikazano 2 od 15'), findsOneWidget);
    });

    testWidgets('filters by rider', (tester) async {
      await openTable(tester);
      await chooseRider(tester, '#12 Luka Vidić');

      expect(find.byType(IncidentRow), findsNWidgets(4));
    });

    testWidgets('combines both filters', (tester) async {
      await openTable(tester);
      await chooseStage(tester, 'Prijavljen');
      await chooseRider(tester, '#12 Luka Vidić');

      expect(find.byType(IncidentRow), findsNWidgets(2));
    });

    testWidgets('says so when no incident matches', (tester) async {
      await openTable(tester);
      await chooseStage(tester, 'Odbačen');
      await chooseRider(tester, '#12 Luka Vidić');

      expect(find.byType(IncidentRow), findsNothing);
      expect(find.text('Nema incidenata za izabrane filtere.'), findsOneWidget);
    });
  });

  group('side panel', () {
    testWidgets('opens for a row with points and possible duplicates, and closes', (tester) async {
      await openTable(tester);
      expect(find.byType(IncidentPanel), findsNothing);

      await tester.tap(find.byKey(const ValueKey('row-i-09')));
      await tester.pumpAndSettle();

      expect(find.byType(IncidentPanel), findsOneWidget);
      expect(find.text('1 od 4'), findsOneWidget);
      expect(find.textContaining('i-13'), findsOneWidget);

      await tester.tap(find.byKey(const Key('close-panel')));
      await tester.pumpAndSettle();
      expect(find.byType(IncidentPanel), findsNothing);
    });
  });

  group('screen states', () {
    testWidgets('loading, then the table', (tester) async {
      useWideScreen(tester);
      await pumpApp(tester);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.byType(IncidentRow), findsWidgets);
    });

    testWidgets('error with a retry button', (tester) async {
      useWideScreen(tester);
      final repository = FakeIncidentRepository(latency: Duration.zero)..failNextRequest();
      await pumpApp(tester, repository: repository);
      await tester.pumpAndSettle();
      expect(find.text('Incidenti nisu učitani.'), findsOneWidget);

      await tester.tap(find.text('Pokušaj ponovo'));
      await tester.pumpAndSettle();
      expect(find.byType(IncidentRow), findsWidgets);
    });

    testWidgets('empty list', (tester) async {
      useWideScreen(tester);
      final repository = FakeIncidentRepository(seed: const [], latency: Duration.zero);
      await pumpApp(tester, repository: repository);
      await tester.pumpAndSettle();

      expect(find.text('Nema prijavljenih incidenata.'), findsOneWidget);
    });
  });
}
