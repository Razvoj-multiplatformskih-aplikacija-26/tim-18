import 'package:domain/domain.dart';
import 'package:server/src/team_notifier.dart';
import 'package:test/test.dart';

void main() {
  PenaltyNotice notice({bool longLap = false}) => PenaltyNotice(
    riderId: const RiderId('r-90'),
    incidentId: const IncidentId('i-1'),
    penalty: Penalty.parse(PenaltyKind.warning, 3).valueOrNull!,
    longLapAwarded: longLap,
  );

  test('keeps what it was asked to send', () async {
    final notifier = FakeTeamNotifier(apiKey: 'dev-fake-key', log: (_) {});
    await notifier.penaltyIssued(notice());
    expect(notifier.sent, hasLength(1));
    expect(notifier.sent.single.riderId, const RiderId('r-90'));
  });

  test('says when the long lap went out with the penalty', () async {
    final lines = <String>[];
    final notifier = FakeTeamNotifier(apiKey: 'dev-fake-key', log: lines.add);
    await notifier.penaltyIssued(notice(longLap: true));
    expect(lines.single, contains('long lap'));
  });

  test('the key is never written out in full', () async {
    final lines = <String>[];
    final notifier = FakeTeamNotifier(apiKey: 'dev-fake-key', log: lines.add);
    await notifier.penaltyIssued(notice());
    expect(lines.single.contains('dev-fake-key'), isFalse);
    expect(lines.single, contains('****-key'));
  });
}
