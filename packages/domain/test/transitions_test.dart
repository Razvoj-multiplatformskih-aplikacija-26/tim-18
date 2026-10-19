import 'package:domain/domain.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  final now = raceStart.add(const Duration(minutes: 10));
  final warning = penalty(PenaltyKind.warning, 1);

  final statuses = <IncidentStatus>[
    const Reported(),
    Confirmed(by: director.id, at: now),
    UnderReview(by: director.id, at: now),
    PenaltyIssued(penalty: warning, by: director.id, at: now),
    Dismissed(reason: 'bez dokaza', by: director.id, at: now),
  ];

  group('R2 · status transitions', () {
    test('allows exactly six transitions out of twenty-five', () {
      final allowed = <(Type, Type)>[];
      for (final from in statuses) {
        for (final to in statuses) {
          if (canTransition(from, to)) allowed.add((from.runtimeType, to.runtimeType));
        }
      }
      expect(allowed, [
        (Reported, Confirmed),
        (Reported, Dismissed),
        (Confirmed, UnderReview),
        (Confirmed, Dismissed),
        (UnderReview, PenaltyIssued),
        (UnderReview, Dismissed),
      ]);
    });

    test('open and final statuses', () {
      expect(statuses.map((s) => s.isOpen), [true, true, true, false, false]);
      expect(statuses.map((s) => s.isFinal), [false, false, false, true, true]);
    });
  });

  group('R2 · decisions', () {
    test('the direction takes an incident from reported to a penalty', () {
      var incident = incidentAt(raceStart);
      incident = confirmIncident(incident, by: director, now: now).valueOrNull!;
      incident = startReview(incident, by: director, now: now).valueOrNull!;
      incident = issuePenalty(incident, by: director, now: now, penalty: warning).valueOrNull!;
      expect(incident.status, isA<PenaltyIssued>());
    });

    test('a penalty cannot be issued before the review', () {
      final result = issuePenalty(incidentAt(raceStart), by: director, now: now, penalty: warning);
      expect(result.errorOrNull, isA<InvalidTransition>());
    });

    test('a decided incident cannot move again', () {
      final dismissed = incidentAt(raceStart, status: statuses.last);
      expect(confirmIncident(dismissed, by: director, now: now).errorOrNull, isA<InvalidTransition>());
    });

    test('a marshal cannot decide', () {
      final incident = incidentAt(raceStart);
      expect(confirmIncident(incident, by: marshal, now: now).errorOrNull, const NotAllowed());
      expect(dismissIncident(incident, by: marshal, now: now, reason: 'x').errorOrNull, const NotAllowed());
    });

    test('dismissing needs a reason', () {
      final incident = incidentAt(raceStart);
      expect(dismissIncident(incident, by: director, now: now, reason: '   ').errorOrNull, const ReasonRequired());
    });

    test('the reason is trimmed and stored', () {
      final result = dismissIncident(incidentAt(raceStart), by: director, now: now, reason: '  bez dokaza ');
      expect((result.valueOrNull!.status as Dismissed).reason, 'bez dokaza');
    });
  });
}
