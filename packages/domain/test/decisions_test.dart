import 'package:domain/domain.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  group('decisionsFor', () {
    test('a reported incident can be confirmed or dismissed', () {
      expect(decisionsFor(const Reported()), [Decision.confirm, Decision.dismiss]);
    });

    test('a confirmed incident can go to review or be dismissed', () {
      final status = Confirmed(by: director.id, at: raceStart);
      expect(decisionsFor(status), [Decision.startReview, Decision.dismiss]);
    });

    test('an incident under review gets a penalty or is dismissed', () {
      final status = UnderReview(by: director.id, at: raceStart);
      expect(decisionsFor(status), [Decision.issuePenalty, Decision.dismiss]);
    });

    test('a decided incident has no decisions left', () {
      final penalized = PenaltyIssued(penalty: penalty(PenaltyKind.warning, 1), by: director.id, at: raceStart);
      final dismissed = Dismissed(reason: 'bez dokaza', by: director.id, at: raceStart);
      expect(decisionsFor(penalized), isEmpty);
      expect(decisionsFor(dismissed), isEmpty);
    });
  });

  group('parseDismissalReason', () {
    test('trims the reason', () {
      expect(parseDismissalReason('  Duplikat.  ').valueOrNull, 'Duplikat.');
    });

    test('refuses a blank reason', () {
      expect(parseDismissalReason('   ').errorOrNull, const ReasonRequired());
      expect(parseDismissalReason('').errorOrNull, const ReasonRequired());
    });
  });
}
