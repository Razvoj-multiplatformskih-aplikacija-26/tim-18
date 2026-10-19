import 'package:domain/domain.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

Result<Incident> report({User by = marshal, String description = 'Vozač je prešao liniju staze.', int turn = 5}) {
  return reportIncident(
    id: const IncidentId('i-1'),
    by: by,
    riderId: rider93,
    kind: IncidentKind.trackLimits,
    description: description,
    turn: turn,
    now: raceStart,
  );
}

void main() {
  group('R1 · reporting', () {
    test('a marshal creates a reported incident', () {
      final incident = report().valueOrNull!;
      expect(incident.status, isA<Reported>());
      expect(incident.reporterId, marshal.id);
      expect(incident.reportedAt.isUtc, isTrue);
    });

    test('the description is trimmed', () {
      final incident = report(description: '   Vozač je prešao liniju staze.  ').valueOrNull!;
      expect(incident.description.text, 'Vozač je prešao liniju staze.');
    });

    test('the direction cannot report', () {
      expect(report(by: director).errorOrNull, const NotAllowed());
    });

    test('a short description is refused', () {
      expect(report(description: 'pad').errorOrNull, const DescriptionTooShort(3));
    });

    test('an invalid turn is refused', () {
      expect(report(turn: 99).errorOrNull, const InvalidTurnNumber(99));
    });

    test('the description error wins over the turn error', () {
      expect(report(description: 'pad', turn: 99).errorOrNull, const DescriptionTooShort(3));
    });
  });

  group('R1 · AccessPolicy', () {
    final incident = incidentAt(raceStart);

    test('a marshal sees only their own incidents', () {
      expect(AccessPolicy.canView(marshal, incident), isTrue);
      expect(AccessPolicy.canView(otherMarshal, incident), isFalse);
    });

    test('the direction sees every incident', () {
      expect(AccessPolicy.canView(director, incident), isTrue);
    });

    test('only the direction decides', () {
      expect(AccessPolicy.canDecide(director), isTrue);
      expect(AccessPolicy.canDecide(marshal), isFalse);
    });
  });
}
