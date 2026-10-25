import 'package:backoffice/data/fake_incident_repository.dart';
import 'package:backoffice/widgets/incident_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pump_app.dart';

Future<FakeIncidentRepository> openPanel(WidgetTester tester, String id) async {
  useWideScreen(tester);
  final repository = FakeIncidentRepository(latency: const Duration(milliseconds: 50));
  await pumpApp(tester, repository: repository);
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(ValueKey('row-$id')));
  await tester.pumpAndSettle();
  return repository;
}

Future<void> tapDecision(WidgetTester tester, String name) async {
  await tester.tap(find.byKey(Key('decision-$name')));
  await tester.pumpAndSettle();
}

void main() {
  group('the buttons follow the domain', () {
    testWidgets('a reported incident can be confirmed or dismissed', (tester) async {
      await openPanel(tester, 'i-01');

      expect(find.byKey(const Key('decision-confirm')), findsOneWidget);
      expect(find.byKey(const Key('decision-dismiss')), findsOneWidget);
      expect(find.byKey(const Key('decision-issuePenalty')), findsNothing);
    });

    testWidgets('a decided incident has no decisions left', (tester) async {
      await openPanel(tester, 'i-11');

      expect(find.text('Za ovaj incident nema daljih odluka.'), findsOneWidget);
      expect(find.byKey(const Key('decision-confirm')), findsNothing);
    });
  });

  group('decisions', () {
    testWidgets('confirming moves the incident on to review', (tester) async {
      await openPanel(tester, 'i-01');
      await tapDecision(tester, 'confirm');

      expect(find.text('Odluka je sačuvana.'), findsOneWidget);
      expect(find.byKey(const Key('decision-startReview')), findsOneWidget);
      expect(find.byKey(const Key('decision-confirm')), findsNothing);
    });

    testWidgets('an incident goes all the way to a penalty', (tester) async {
      await openPanel(tester, 'i-01');
      await tapDecision(tester, 'confirm');
      await tapDecision(tester, 'startReview');
      await tapDecision(tester, 'issuePenalty');

      await tester.enterText(find.byKey(const Key('penalty-points')), '2');
      await tester.tap(find.byKey(const Key('penalty-submit')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Upozorenje, 2 poena'), findsOneWidget);
      expect(find.text('Za ovaj incident nema daljih odluka.'), findsOneWidget);
    });

    testWidgets('dismissing needs a reason', (tester) async {
      await openPanel(tester, 'i-01');
      await tapDecision(tester, 'dismiss');

      await tester.tap(find.byKey(const Key('dismiss-submit')));
      await tester.pumpAndSettle();
      expect(find.text('Razlog je obavezan.'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('dismiss-reason')), 'Duplikat.');
      await tester.tap(find.byKey(const Key('dismiss-submit')));
      await tester.pumpAndSettle();

      expect(find.text('Razlog: Duplikat.'), findsOneWidget);
    });

    testWidgets('penalty points outside the range are refused in the dialog', (tester) async {
      await openPanel(tester, 'i-06');
      await tapDecision(tester, 'issuePenalty');

      await tester.enterText(find.byKey(const Key('penalty-points')), '9');
      await tester.tap(find.byKey(const Key('penalty-submit')));
      await tester.pumpAndSettle();

      expect(find.text('Kazneni poeni moraju biti od 0 do 3.'), findsOneWidget);
    });

    testWidgets('backing out of a dialog changes nothing', (tester) async {
      await openPanel(tester, 'i-06');
      await tapDecision(tester, 'issuePenalty');

      await tester.tap(find.text('Odustani'));
      await tester.pumpAndSettle();

      expect(find.byType(IncidentPanel), findsOneWidget);
      expect(find.byKey(const Key('decision-issuePenalty')), findsOneWidget);
      expect(find.text('Odluka je sačuvana.'), findsNothing);
    });

    testWidgets('a storage failure leaves the incident as it was', (tester) async {
      final repository = await openPanel(tester, 'i-01');
      repository.failNextRequest();
      await tapDecision(tester, 'confirm');

      expect(find.text('Odluka nije sačuvana. Pokušajte ponovo.'), findsOneWidget);
      expect(find.byKey(const Key('decision-confirm')), findsOneWidget);
    });
  });
}
