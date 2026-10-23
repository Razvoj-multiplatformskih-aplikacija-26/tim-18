import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/seed_data.dart';
import 'package:mobile/text/labels.dart';

void main() {
  test('points use the singular only for one', () {
    expect(pointsLabel(0), '0 poena');
    expect(pointsLabel(1), '1 poen');
    expect(pointsLabel(3), '3 poena');
  });

  test('time is shown as two digits in UTC', () {
    expect(formatTime(DateTime.utc(2026, 11, 8, 9, 5)), '09:05');
  });

  test('a known rider shows number and name, an unknown one the raw id', () {
    expect(riderLabel(riders.first.id), '#12 Luka Vidić');
    expect(riderLabel(const RiderId('r-404')), 'r-404');
  });

  test('every status has a label and only a reported incident has no note', () {
    final at = DateTime.utc(2026, 11, 8, 14, 30);
    const director = UserId('u-director-1');
    final statuses = <IncidentStatus>[
      const Reported(),
      Confirmed(by: director, at: at),
      UnderReview(by: director, at: at),
      PenaltyIssued(penalty: Penalty.automaticLongLap, by: director, at: at),
      Dismissed(reason: 'Duplikat.', by: director, at: at),
    ];
    expect(statuses.map((status) => status.label), [
      'Prijavljen',
      'Potvrđen',
      'U razmatranju',
      'Kazna izrečena',
      'Odbačen',
    ]);
    expect(statuses.map(statusNote), [
      null,
      'Potvrđen u 14:30',
      'U razmatranju od 14:30',
      'Long lap penalty, 0 poena (14:30)',
      'Razlog: Duplikat.',
    ]);
  });
}
