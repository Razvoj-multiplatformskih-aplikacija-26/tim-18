import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/fake_incident_repository.dart';
import 'package:mobile/data/seed_data.dart';

void main() {
  FakeIncidentRepository build() => FakeIncidentRepository(latency: Duration.zero);

  test('the marshal sees at least ten incidents covering every status', () async {
    final incidents = await build().incidentsFor(demoMarshal);
    expect(incidents.length, greaterThanOrEqualTo(10));
    expect(incidents.map((incident) => incident.status.runtimeType).toSet(), {
      Reported,
      Confirmed,
      UnderReview,
      PenaltyIssued,
      Dismissed,
    });
  });

  test('the marshal sees only their own incidents, the direction sees all', () async {
    final repository = build();
    expect((await repository.incidentsFor(demoMarshal)).length, 12);
    expect((await repository.incidentsFor(demoDirector)).length, 15);
  });

  test('a saved incident is returned afterwards', () async {
    final repository = build();
    final before = await repository.incidentsFor(demoMarshal);
    final created = reportIncident(
      id: const IncidentId('i-new'),
      by: demoMarshal,
      riderId: riders.first.id,
      kind: IncidentKind.crash,
      description: 'Vozač je pao u krivini 3.',
      turn: 3,
      now: DateTime.utc(2026, 11, 8, 15),
    ).valueOrNull!;

    await repository.save(created);

    expect((await repository.incidentsFor(demoMarshal)).length, before.length + 1);
  });

  test('failNextRequest fails exactly one request', () async {
    final repository = build()..failNextRequest();
    await expectLater(repository.incidentsFor(demoMarshal), throwsA(isA<RepositoryException>()));
    expect(await repository.incidentsFor(demoMarshal), isNotEmpty);
  });

  test('a failed save stores nothing', () async {
    final repository = build();
    final before = await repository.incidentsFor(demoMarshal);
    final created = reportIncident(
      id: const IncidentId('i-new'),
      by: demoMarshal,
      riderId: riders.first.id,
      kind: IncidentKind.crash,
      description: 'Vozač je pao u krivini 3.',
      turn: 3,
      now: DateTime.utc(2026, 11, 8, 15),
    ).valueOrNull!;

    repository.failNextRequest();
    await expectLater(repository.save(created), throwsA(isA<RepositoryException>()));

    expect((await repository.incidentsFor(demoMarshal)).length, before.length);
  });
}
