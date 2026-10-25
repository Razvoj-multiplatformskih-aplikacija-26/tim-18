import 'package:backoffice/widgets/incident_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pump_app.dart';

// Newest first, the direction sees fifteen incidents: the first row is i-15,
// then i-14, i-11, and the last one is i-06.
const _first = 'Preticanje izvan staze u krivini 13.'; // i-15, reported
const _second = 'Pad u krivini 12, vozač je odmah ustao.'; // i-14
const _last = 'Vozač je krenuo pre nego što se ugasilo crveno svetlo.'; // i-06

Future<void> openTable(WidgetTester tester, {double height = 1200}) async {
  useWideScreen(tester, height: height);
  await pumpApp(tester);
  await tester.pumpAndSettle();
}

Future<void> press(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pumpAndSettle();
}

void main() {
  group('moving through the incidents', () {
    testWidgets('down selects the first row and then walks down', (tester) async {
      await openTable(tester);
      expect(find.byType(IncidentPanel), findsNothing);

      await press(tester, LogicalKeyboardKey.arrowDown);
      expect(find.text(_first), findsOneWidget);

      await press(tester, LogicalKeyboardKey.arrowDown);
      expect(find.text(_second), findsOneWidget);

      await press(tester, LogicalKeyboardKey.arrowUp);
      expect(find.text(_first), findsOneWidget);
    });

    testWidgets('up from nothing starts at the last row, and the ends stop the selection', (tester) async {
      await openTable(tester);

      await press(tester, LogicalKeyboardKey.arrowUp);
      expect(find.text(_last), findsOneWidget);

      await press(tester, LogicalKeyboardKey.arrowDown);
      expect(find.text(_last), findsOneWidget);
    });

    testWidgets('Home and End jump to the ends', (tester) async {
      await openTable(tester);

      await press(tester, LogicalKeyboardKey.end);
      expect(find.text(_last), findsOneWidget);

      await press(tester, LogicalKeyboardKey.home);
      expect(find.text(_first), findsOneWidget);
    });

    testWidgets('Escape closes the panel', (tester) async {
      await openTable(tester);
      await press(tester, LogicalKeyboardKey.arrowDown);
      expect(find.byType(IncidentPanel), findsOneWidget);

      await press(tester, LogicalKeyboardKey.escape);
      expect(find.byType(IncidentPanel), findsNothing);
    });

    testWidgets('the selected row scrolls into view', (tester) async {
      await openTable(tester, height: 500);

      await press(tester, LogicalKeyboardKey.end);

      final row = find.byKey(const ValueKey('row-i-06'));
      expect(row, findsOneWidget);
      expect(tester.getBottomLeft(row).dy, lessThanOrEqualTo(500));
    });
  });

  group('shortcuts', () {
    testWidgets('an incident goes from reported to a penalty using only the keyboard', (tester) async {
      await openTable(tester);
      await press(tester, LogicalKeyboardKey.arrowDown);

      await press(tester, LogicalKeyboardKey.keyC);
      expect(find.byKey(const Key('decision-startReview')), findsOneWidget);

      await press(tester, LogicalKeyboardKey.keyR);
      expect(find.byKey(const Key('decision-issuePenalty')), findsOneWidget);

      await press(tester, LogicalKeyboardKey.keyK);
      expect(find.byKey(const Key('penalty-points')), findsOneWidget);
      await tester.enterText(find.byKey(const Key('penalty-points')), '1');
      await tester.tap(find.byKey(const Key('penalty-submit')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Upozorenje, 1 poen'), findsOneWidget);
    });

    testWidgets('D asks for a reason', (tester) async {
      await openTable(tester);
      await press(tester, LogicalKeyboardKey.arrowDown);

      await press(tester, LogicalKeyboardKey.keyD);

      expect(find.byKey(const Key('dismiss-reason')), findsOneWidget);
    });

    testWidgets('a shortcut the domain does not allow does nothing', (tester) async {
      await openTable(tester);
      await press(tester, LogicalKeyboardKey.arrowDown); // reported

      await press(tester, LogicalKeyboardKey.keyK);
      await press(tester, LogicalKeyboardKey.keyR);

      expect(find.byKey(const Key('penalty-points')), findsNothing);
      expect(find.byKey(const Key('decision-confirm')), findsOneWidget);
    });

    testWidgets('without a selection the shortcuts do nothing', (tester) async {
      await openTable(tester);

      await press(tester, LogicalKeyboardKey.keyC);

      expect(find.text('Odluka je sačuvana.'), findsNothing);
    });

    testWidgets('F1 and the toolbar button show the shortcuts', (tester) async {
      await openTable(tester);

      await press(tester, LogicalKeyboardKey.f1);
      expect(find.text('Prečice na tastaturi'), findsOneWidget);

      await tester.tap(find.text('Zatvori'));
      await tester.pumpAndSettle();
      expect(find.text('Prečice na tastaturi'), findsNothing);

      await tester.tap(find.byKey(const Key('shortcuts-button')));
      await tester.pumpAndSettle();
      expect(find.text('Prečice na tastaturi'), findsOneWidget);
    });
  });
}
