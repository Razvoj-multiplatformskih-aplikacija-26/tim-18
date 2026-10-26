import 'package:domain/domain.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  group('R3 · penalty points', () {
    test('sums only issued penalties of the rider', () {
      final incidents = [
        withPenalty('i-1', rider93, 1),
        withPenalty('i-2', rider93, 2),
        withPenalty('i-3', rider46, 3),
        incidentAt(raceStart, id: 'i-4'),
      ];
      expect(penaltyPointsOf(rider93, incidents), 3);
      expect(penaltyPointsOf(rider46, incidents), 3);
      expect(penaltyPointsOf(const RiderId('r-none'), incidents), 0);
    });

    test('the threshold is crossed exactly once', () {
      expect(crossesLongLapThreshold(pointsBefore: 3, added: 1), isTrue);
      expect(crossesLongLapThreshold(pointsBefore: 2, added: 1), isFalse);
      expect(crossesLongLapThreshold(pointsBefore: 4, added: 1), isFalse);
      expect(crossesLongLapThreshold(pointsBefore: 0, added: 3), isFalse);
    });

    test('standings are sorted by points, then by rider', () {
      final incidents = [
        withPenalty('i-1', rider93, 1),
        withPenalty('i-2', rider46, 2),
        withPenalty('i-3', rider93, 3),
      ];
      expect(standings(incidents), [
        const RiderStanding(riderId: rider93, points: 4),
        const RiderStanding(riderId: rider46, points: 2),
      ]);
    });

    test('a rider at the threshold is due a long lap', () {
      expect(const RiderStanding(riderId: rider93, points: longLapThreshold).longLapDue, isTrue);
      expect(const RiderStanding(riderId: rider93, points: longLapThreshold - 1).longLapDue, isFalse);
    });
  });

  group('R3 · standingOf', () {
    test('adds up the points and says when the threshold is reached', () {
      final incidents = [withPenalty('i-1', rider93, 2), withPenalty('i-2', rider93, 2)];
      final standing = standingOf(rider93, incidents);
      expect(standing.points, 4);
      expect(standing.longLapDue, isTrue);
      expect(standingOf(rider46, incidents).longLapDue, isFalse);
    });
  });
}
