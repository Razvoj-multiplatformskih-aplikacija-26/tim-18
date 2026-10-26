import 'package:backoffice/widgets/incident_list.dart';
import 'package:backoffice/widgets/incident_panel.dart';
import 'package:backoffice/widgets/incident_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pump_app.dart';

const _narrow = Size(700, 900);
const _wide = Size(1400, 1200);

const _i09 = 'Dva prelaska linije u istom krugu u krivini 8.';
const _first = 'Preticanje izvan staze u krivini 13.'; // i-15
const _second = 'Pad u krivini 12, vozač je odmah ustao.'; // i-14

Future<void> open(WidgetTester tester, Size size) async {
  useScreen(tester, width: size.width, height: size.height);
  await pumpApp(tester);
  await tester.pumpAndSettle();
}

Future<void> resize(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  await tester.pumpAndSettle();
}

Future<void> press(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pumpAndSettle();
}

void main() {
  group('layout', () {
    testWidgets('a wide window shows the table', (tester) async {
      await open(tester, _wide);

      expect(find.byType(IncidentTable), findsOneWidget);
      expect(find.byType(IncidentList), findsNothing);
    });

    testWidgets('a narrow window shows a list instead of the table', (tester) async {
      await open(tester, _narrow);

      expect(find.byType(IncidentList), findsOneWidget);
      expect(find.byType(IncidentTable), findsNothing);
      expect(find.byType(IncidentListItem), findsWidgets);
    });

    testWidgets('resizing switches between the two', (tester) async {
      await open(tester, _wide);

      await resize(tester, _narrow);
      expect(find.byType(IncidentList), findsOneWidget);

      await resize(tester, _wide);
      expect(find.byType(IncidentTable), findsOneWidget);
    });

    testWidgets('in a narrow window a row opens the detail across the whole window', (tester) async {
      await open(tester, _narrow);

      await tester.tap(find.byKey(const ValueKey('row-i-09')));
      await tester.pumpAndSettle();

      expect(find.byType(IncidentPanel), findsOneWidget);
      expect(tester.getSize(find.byType(IncidentPanel)).width, greaterThan(600));
      expect(find.byType(IncidentList), findsNothing);
    });
  });

  group('the selection survives resizing', () {
    testWidgets('narrowing, going back and widening keeps the same incident', (tester) async {
      await open(tester, _wide);
      await tester.tap(find.byKey(const ValueKey('row-i-09')));
      await tester.pumpAndSettle();
      expect(find.text(_i09), findsOneWidget);

      await resize(tester, _narrow);
      expect(find.byType(IncidentTable), findsNothing);
      expect(find.text(_i09), findsOneWidget);

      await tester.tap(find.byKey(const Key('close-panel')));
      await tester.pumpAndSettle();
      expect(find.byType(IncidentList), findsOneWidget);
      expect(find.byType(IncidentPanel), findsNothing);

      await resize(tester, _wide);
      expect(find.byType(IncidentTable), findsOneWidget);
      expect(find.text(_i09), findsOneWidget);
    });
  });

  group('keyboard in a narrow window', () {
    testWidgets('arrows select, Enter opens the detail, Escape goes back and keeps the selection', (tester) async {
      await open(tester, _narrow);

      await press(tester, LogicalKeyboardKey.arrowDown);
      expect(find.byType(IncidentPanel), findsNothing);

      await press(tester, LogicalKeyboardKey.enter);
      expect(find.text(_first), findsOneWidget);

      await press(tester, LogicalKeyboardKey.escape);
      expect(find.byType(IncidentPanel), findsNothing);
      expect(find.byType(IncidentList), findsOneWidget);

      await press(tester, LogicalKeyboardKey.arrowDown);
      await press(tester, LogicalKeyboardKey.enter);
      expect(find.text(_second), findsOneWidget);
    });

    testWidgets('the decision shortcuts work in the detail', (tester) async {
      await open(tester, _narrow);

      await press(tester, LogicalKeyboardKey.arrowDown);
      await press(tester, LogicalKeyboardKey.enter);
      await press(tester, LogicalKeyboardKey.keyC);

      expect(find.byKey(const Key('decision-startReview')), findsOneWidget);
    });

    testWidgets('Escape twice clears the selection', (tester) async {
      await open(tester, _narrow);
      await press(tester, LogicalKeyboardKey.arrowDown);
      await press(tester, LogicalKeyboardKey.enter);

      await press(tester, LogicalKeyboardKey.escape);
      await press(tester, LogicalKeyboardKey.escape);
      await resize(tester, _wide);

      expect(find.byType(IncidentPanel), findsNothing);
    });
  });
}
