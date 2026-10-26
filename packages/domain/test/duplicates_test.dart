import 'package:domain/domain.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  final candidate = incidentAt(raceStart, id: 'i-1');

  group('R3 · possible duplicates', () {
    test('finds the same rider, turn and kind from another marshal within five minutes', () {
      final other = incidentAt(raceStart.add(const Duration(minutes: 3)), id: 'i-2', reporterId: otherMarshal.id);
      expect(possibleDuplicates(candidate, [other]), [other]);
    });

    test('the window is inclusive and works in both directions', () {
      final before = incidentAt(raceStart.subtract(duplicateWindow), id: 'i-2');
      final after = incidentAt(raceStart.add(duplicateWindow), id: 'i-3');
      expect(possibleDuplicates(candidate, [before, after]), [before, after]);
    });

    test('ignores reports outside the window', () {
      final tooLate = incidentAt(raceStart.add(const Duration(minutes: 6)), id: 'i-2');
      expect(possibleDuplicates(candidate, [tooLate]), isEmpty);
    });

    test('ignores a different rider, turn or kind', () {
      final others = [
        incidentAt(raceStart, id: 'i-2', riderId: rider46),
        incidentAt(raceStart, id: 'i-3', turn: 6),
        incidentAt(raceStart, id: 'i-4', kind: IncidentKind.crash),
      ];
      expect(possibleDuplicates(candidate, others), isEmpty);
    });

    test('ignores dismissed incidents and the candidate itself', () {
      final dismissed = incidentAt(
        raceStart,
        id: 'i-2',
        status: Dismissed(reason: 'bez dokaza', by: director.id, at: raceStart),
      );
      expect(possibleDuplicates(candidate, [dismissed, candidate]), isEmpty);
    });
  });

  group('R3 · duplicates of a report that is about to be made', () {
    final turn5 = TurnNumber.parse(5).valueOrNull!;
    final existing = [incidentAt(raceStart, id: 'i-1')];

    test('finds a close report of the same rider, turn and kind', () {
      final found = duplicatesOfReport(
        existing,
        riderId: rider93,
        kind: IncidentKind.trackLimits,
        turn: turn5,
        at: raceStart.add(const Duration(minutes: 2)),
      );
      expect(found, existing);
    });

    test('ignores a report outside the window or of another kind', () {
      expect(
        duplicatesOfReport(
          existing,
          riderId: rider93,
          kind: IncidentKind.trackLimits,
          turn: turn5,
          at: raceStart.add(const Duration(minutes: 10)),
        ),
        isEmpty,
      );
      expect(
        duplicatesOfReport(existing, riderId: rider93, kind: IncidentKind.crash, turn: turn5, at: raceStart),
        isEmpty,
      );
    });
  });
}
