import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/widgets/incident_tile.dart';

import 'pump_app.dart';

Future<void> chooseFromMenu(WidgetTester tester, String item) async {
  await tester.tap(find.byKey(const Key('debug-menu')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(item));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the menu shows the empty list once, and reload brings the data back', (tester) async {
    await pumpApp(tester);
    await tester.pumpAndSettle();
    expect(find.byType(IncidentTile), findsWidgets);

    await chooseFromMenu(tester, 'Prikaži praznu listu');
    expect(find.text('Nema prijavljenih incidenata.'), findsOneWidget);
    expect(find.byType(IncidentTile), findsNothing);

    await chooseFromMenu(tester, 'Osveži');
    expect(find.byType(IncidentTile), findsWidgets);
  });
}
