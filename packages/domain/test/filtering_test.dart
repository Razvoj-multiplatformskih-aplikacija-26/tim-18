import 'package:domain/domain.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  group('IncidentStage', () {
    test('every status maps to its own stage', () {
      final statuses = <IncidentStatus>[
        const Reported(),
        Confirmed(by: director.id, at: raceStart),
        UnderReview(by: director.id, at: raceStart),
        PenaltyIssued(penalty: penalty(PenaltyKind.warning, 1), by: director.id, at: raceStart),
        Dismissed(reason: 'bez dokaza', by: director.id, at: raceStart),
      ];
      expect(statuses.map((status) => status.stage), IncidentStage.values);
    });
  });

  group('filterIncidents', () {
    final reported93 = incidentAt(raceStart, id: 'a');
    final confirmed46 = incidentAt(
      raceStart,
      id: 'b',
      riderId: rider46,
      status: Confirmed(by: director.id, at: raceStart),
    );
    final penalized93 = withPenalty('c', rider93, 1);
    final all = [reported93, confirmed46, penalized93];

    test('without filters everything is returned', () {
      expect(filterIncidents(all), all);
    });

    test('filters by stage', () {
      expect(filterIncidents(all, stage: IncidentStage.confirmed), [confirmed46]);
      expect(filterIncidents(all, stage: IncidentStage.dismissed), isEmpty);
    });

    test('filters by rider', () {
      expect(filterIncidents(all, riderId: rider93), [reported93, penalized93]);
    });

    test('combines both filters', () {
      expect(filterIncidents(all, stage: IncidentStage.penaltyIssued, riderId: rider93), [penalized93]);
      expect(filterIncidents(all, stage: IncidentStage.penaltyIssued, riderId: rider46), isEmpty);
    });
  });
}
