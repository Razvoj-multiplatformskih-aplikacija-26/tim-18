import 'package:flutter_test/flutter_test.dart';
import 'package:backoffice/app.dart';
import 'package:backoffice/app_dependencies.dart';
import 'package:backoffice/data/fake_incident_repository.dart';
import 'package:backoffice/data/seed_data.dart';

void main() {
  testWidgets('the direction sees the incidents of every marshal', (tester) async {
    final repository = FakeIncidentRepository(latency: Duration.zero);
    await tester.pumpWidget(
      BackofficeApp(
        dependencies: AppDependencies(repository: repository, user: demoDirector),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Učitano incidenata: 15'), findsOneWidget);
  });
}
