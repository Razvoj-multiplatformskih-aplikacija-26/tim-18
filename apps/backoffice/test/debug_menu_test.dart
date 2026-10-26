import 'package:backoffice/widgets/incident_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pump_app.dart';

Future<void> chooseFromMenu(WidgetTester tester, String item) async {
  await tester.tap(find.byKey(const Key('debug-menu')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(item));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the menu shows the empty list once, and reload brings the table back', (tester) async {
    useWideScreen(tester);
    await pumpApp(tester);
    await tester.pumpAndSettle();
    expect(find.byType(IncidentRow), findsWidgets);

    await chooseFromMenu(tester, 'Prikaži praznu listu');
    expect(find.text('Nema prijavljenih incidenata.'), findsOneWidget);
    expect(find.byType(IncidentRow), findsNothing);

    await chooseFromMenu(tester, 'Osveži');
    expect(find.byType(IncidentRow), findsWidgets);
  });

  testWidgets('the menu makes the next request fail', (tester) async {
    useWideScreen(tester);
    await pumpApp(tester);
    await tester.pumpAndSettle();

    await chooseFromMenu(tester, 'Simuliraj grešku sledećeg zahteva');
    await chooseFromMenu(tester, 'Osveži');

    expect(find.text('Incidenti nisu učitani.'), findsOneWidget);
    expect(find.text('Pokušaj ponovo'), findsOneWidget);
  });
}
