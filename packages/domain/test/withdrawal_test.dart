import 'package:domain/domain.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  group('withdrawIncident', () {
    test('the marshal who reported it can take it back while it is reported', () {
      final incident = incidentAt(raceStart);
      expect(withdrawIncident(incident, by: marshal).valueOrNull, incident);
    });

    test('another marshal cannot take back a report that is not theirs', () {
      final incident = incidentAt(raceStart);
      expect(withdrawIncident(incident, by: otherMarshal).errorOrNull, const NotAllowed());
    });

    test('the direction does not take reports back', () {
      final incident = incidentAt(raceStart);
      expect(withdrawIncident(incident, by: director).errorOrNull, const NotAllowed());
    });

    test('once the direction has acted, the report stays', () {
      final statuses = <IncidentStatus>[
        Confirmed(by: director.id, at: raceStart),
        UnderReview(by: director.id, at: raceStart),
        PenaltyIssued(penalty: penalty(PenaltyKind.warning, 1), by: director.id, at: raceStart),
        Dismissed(reason: 'bez dokaza', by: director.id, at: raceStart),
      ];
      for (final status in statuses) {
        final incident = incidentAt(raceStart, status: status);
        expect(isWithdrawable(incident), isFalse);
        expect(withdrawIncident(incident, by: marshal).errorOrNull, const NotWithdrawable());
      }
    });

    test('ownership is checked before the state', () {
      final incident = incidentAt(
        raceStart,
        status: Confirmed(by: director.id, at: raceStart),
      );
      expect(withdrawIncident(incident, by: otherMarshal).errorOrNull, const NotAllowed());
    });
  });
}
