import 'package:domain/domain.dart';

const demoMarshal = User(id: UserId('u-marshal-1'), username: 'marshal1', role: Role.marshal);
const demoDirector = User(id: UserId('u-director-1'), username: 'director1', role: Role.director);

const _otherMarshal = UserId('u-marshal-2');

const riders = <Rider>[
  Rider(id: RiderId('r-12'), number: 12, name: 'Luka Vidić'),
  Rider(id: RiderId('r-27'), number: 27, name: 'Marko Ilić'),
  Rider(id: RiderId('r-44'), number: 44, name: 'Stefan Marić'),
  Rider(id: RiderId('r-63'), number: 63, name: 'Nikola Savić'),
  Rider(id: RiderId('r-90'), number: 90, name: 'Andrej Lukić'),
];

final _raceStart = DateTime.utc(2026, 11, 8, 14);

DateTime _at(int minutes) => _raceStart.add(Duration(minutes: minutes));

Incident _incident(
  String id, {
  required int minutes,
  required String rider,
  required IncidentKind kind,
  required int turn,
  required String text,
  IncidentStatus status = const Reported(),
  UserId reporter = const UserId('u-marshal-1'),
}) {
  return Incident(
    id: IncidentId(id),
    reporterId: reporter,
    riderId: RiderId(rider),
    kind: kind,
    description: IncidentDescription.parse(text).valueOrNull!,
    turn: TurnNumber.parse(turn).valueOrNull!,
    reportedAt: _at(minutes),
    status: status,
  );
}

Penalty _penalty(PenaltyKind kind, int points) => Penalty.parse(kind, points).valueOrNull!;

const _director = UserId('u-director-1');

/// Fifteen incidents: twelve reported by [demoMarshal] covering every status,
/// three by another marshal (one of them a likely duplicate of `i-09`).
List<Incident> seedIncidents() {
  return [
    _incident(
      'i-01',
      minutes: 5,
      rider: 'r-12',
      kind: IncidentKind.crash,
      turn: 3,
      text: 'Vozač je pao u krivini 3, motor je ostao na stazi.',
    ),
    _incident(
      'i-02',
      minutes: 12,
      rider: 'r-27',
      kind: IncidentKind.illegalOvertake,
      turn: 7,
      text: 'Preticanje u krivini 7 uz kontakt sa vozačem ispred.',
    ),
    _incident(
      'i-03',
      minutes: 20,
      rider: 'r-44',
      kind: IncidentKind.trackLimits,
      turn: 11,
      text: 'Vozač je sa obe strane motora izašao van linije staze.',
    ),
    _incident(
      'i-04',
      minutes: 25,
      rider: 'r-12',
      kind: IncidentKind.dangerousRiding,
      turn: 5,
      text: 'Naglo menjanje putanje na izlazu iz krivine 5.',
      status: Confirmed(by: _director, at: _at(27)),
    ),
    _incident(
      'i-05',
      minutes: 33,
      rider: 'r-27',
      kind: IncidentKind.trackLimits,
      turn: 9,
      text: 'Ponovljen prelazak bele linije u krivini 9.',
      status: Confirmed(by: _director, at: _at(35)),
    ),
    _incident(
      'i-06',
      minutes: 2,
      rider: 'r-63',
      kind: IncidentKind.jumpStart,
      turn: 1,
      text: 'Vozač je krenuo pre nego što se ugasilo crveno svetlo.',
      status: UnderReview(by: _director, at: _at(6)),
    ),
    _incident(
      'i-07',
      minutes: 41,
      rider: 'r-44',
      kind: IncidentKind.illegalOvertake,
      turn: 14,
      text: 'Preticanje pod žutom zastavom u krivini 14.',
      status: UnderReview(by: _director, at: _at(44)),
    ),
    _incident(
      'i-08',
      minutes: 18,
      rider: 'r-63',
      kind: IncidentKind.crash,
      turn: 6,
      text: 'Pad posle kontakta sa vozačem pored, bez povreda.',
      status: PenaltyIssued(penalty: _penalty(PenaltyKind.warning, 1), by: _director, at: _at(30)),
    ),
    _incident(
      'i-09',
      minutes: 48,
      rider: 'r-12',
      kind: IncidentKind.trackLimits,
      turn: 8,
      text: 'Dva prelaska linije u istom krugu u krivini 8.',
      status: PenaltyIssued(penalty: _penalty(PenaltyKind.warning, 1), by: _director, at: _at(55)),
    ),
    _incident(
      'i-10',
      minutes: 8,
      rider: 'r-27',
      kind: IncidentKind.dangerousRiding,
      turn: 2,
      text: 'Opasna vožnja u gužvi odmah posle starta, kontakt sa dva vozača.',
      status: PenaltyIssued(penalty: _penalty(PenaltyKind.rideThrough, 3), by: _director, at: _at(15)),
    ),
    _incident(
      'i-11',
      minutes: 52,
      rider: 'r-44',
      kind: IncidentKind.trackLimits,
      turn: 4,
      text: 'Kratak izlazak van staze bez ostvarene prednosti.',
      status: Dismissed(reason: 'Prednost nije ostvarena.', by: _director, at: _at(58)),
    ),
    _incident(
      'i-12',
      minutes: 36,
      rider: 'r-63',
      kind: IncidentKind.crash,
      turn: 10,
      text: 'Prijava pada koji je već obrađen kroz drugu prijavu.',
      status: Dismissed(reason: 'Duplikat druge prijave.', by: _director, at: _at(40)),
    ),
    _incident(
      'i-13',
      minutes: 50,
      rider: 'r-12',
      kind: IncidentKind.trackLimits,
      turn: 8,
      text: 'Vozač je prešao liniju staze u krivini 8, drugi put u krugu.',
      reporter: _otherMarshal,
    ),
    _incident(
      'i-14',
      minutes: 60,
      rider: 'r-90',
      kind: IncidentKind.crash,
      turn: 12,
      text: 'Pad u krivini 12, vozač je odmah ustao.',
      reporter: _otherMarshal,
    ),
    _incident(
      'i-15',
      minutes: 62,
      rider: 'r-90',
      kind: IncidentKind.illegalOvertake,
      turn: 13,
      text: 'Preticanje izvan staze u krivini 13.',
      reporter: _otherMarshal,
    ),
  ];
}
