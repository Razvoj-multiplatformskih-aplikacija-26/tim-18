import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app.dart';
import 'package:mobile/router.dart';
import 'package:mobile/screens/incident_detail_screen.dart';
import 'package:mobile/screens/incidents_screen.dart';
import 'package:mobile/screens/report_screen.dart';
import 'package:mobile/theme/app_theme.dart';

void main() {
  group('routing', () {
    testWidgets('opens on the incident list', (tester) async {
      await tester.pumpWidget(const RaceDirectionApp());
      expect(find.byType(IncidentsScreen), findsOneWidget);
    });

    testWidgets('every screen has its own address', (tester) async {
      final router = buildRouter();
      addTearDown(router.dispose);
      await tester.pumpWidget(RaceDirectionApp(router: router));

      router.go('/incidents/i-01');
      await tester.pumpAndSettle();
      expect(find.byType(IncidentDetailScreen), findsOneWidget);
      expect(tester.widget<IncidentDetailScreen>(find.byType(IncidentDetailScreen)).incidentId, 'i-01');

      router.go('/incidents/new');
      await tester.pumpAndSettle();
      expect(find.byType(ReportScreen), findsOneWidget);
      expect(find.byType(IncidentDetailScreen), findsNothing);
    });

    testWidgets('the placeholder buttons navigate by route name', (tester) async {
      await tester.pumpWidget(const RaceDirectionApp());

      await tester.tap(find.text('Prijavi incident'));
      await tester.pumpAndSettle();
      expect(find.byType(ReportScreen), findsOneWidget);
    });
  });

  group('theme', () {
    test('uses the bundled font in both brightnesses', () {
      expect(AppTheme.light().textTheme.bodyMedium?.fontFamily, AppTheme.fontFamily);
      expect(AppTheme.dark().textTheme.bodyMedium?.fontFamily, AppTheme.fontFamily);
    });

    test('has a light and a dark color scheme', () {
      expect(AppTheme.light().colorScheme.brightness, Brightness.light);
      expect(AppTheme.dark().colorScheme.brightness, Brightness.dark);
    });
  });
}
