import 'dart:convert';

import 'package:contract/contract.dart';
import 'package:domain/domain.dart';
import 'package:mapping/mapping.dart';
import 'package:test/test.dart';

final _t0 = DateTime.utc(2026, 10, 18, 14, 5);
const _director = UserId('u-director-1');

Incident _incident(IncidentStatus status) => Incident(
  id: const IncidentId('i-1'),
  reporterId: const UserId('u-marshal-1'),
  riderId: const RiderId('r-12'),
  kind: IncidentKind.illegalOvertake,
  description: IncidentDescription.parse('Preticanje u krivini 7 uz kontakt.').valueOrNull!,
  turn: TurnNumber.parse(7).valueOrNull!,
  reportedAt: _t0,
  status: status,
);

/// What a message looks like after the network.
IncidentDto _overTheWire(IncidentDto dto) => IncidentDto.fromJson(jsonDecode(jsonEncode(dto.toJson())) as Json);

void main() {
  group('incident', () {
    final statuses = <IncidentStatus>[
      const Reported(),
      Confirmed(by: _director, at: _t0),
      UnderReview(by: _director, at: _t0),
      PenaltyIssued(penalty: Penalty.parse(PenaltyKind.rideThrough, 3).valueOrNull!, by: _director, at: _t0),
      PenaltyIssued(penalty: Penalty.automaticLongLap, by: _director, at: _t0),
      Dismissed(reason: 'Prednost nije ostvarena.', by: _director, at: _t0),
    ];

    for (final status in statuses) {
      test('${status.runtimeType} survives domain -> wire -> domain', () {
        final incident = _incident(status);
        final back = incidentFromDto(_overTheWire(incidentToDto(incident)));
        expect(back, incident);
      });
    }

    test('an unknown kind is a MappingException, not a crash somewhere else', () {
      final dto = IncidentDto(
        id: 'i-1',
        reporterId: 'u',
        riderId: 'r',
        kind: 'teleport',
        description: 'Neki dovoljno dug opis.',
        turn: 3,
        reportedAt: _t0.toIso8601String(),
        status: const StatusDto(stage: 'reported'),
      );
      expect(() => incidentFromDto(dto), throwsA(isA<MappingException>()));
    });

    test('a status without its data is a MappingException', () {
      expect(
        () => statusFromDto(const StatusDto(stage: 'dismissed', by: 'u', at: '2026-10-18T14:00:00Z')),
        throwsA(isA<MappingException>()),
      );
    });
  });

  group('decisions', () {
    test('a moved status gives the decision that leads there', () {
      expect(decisionFromStatus(Confirmed(by: _director, at: _t0)).action, 'confirm');
      expect(decisionFromStatus(UnderReview(by: _director, at: _t0)).action, 'startReview');
      final penalty = decisionFromStatus(
        PenaltyIssued(penalty: Penalty.parse(PenaltyKind.warning, 2).valueOrNull!, by: _director, at: _t0),
      );
      expect((penalty.action, penalty.penaltyKind, penalty.penaltyPoints), ('issuePenalty', 'warning', 2));
      expect(decisionFromStatus(Dismissed(reason: 'Duplikat.', by: _director, at: _t0)).reason, 'Duplikat.');
    });

    test('the server reads the decision back as raw input', () {
      final input = decisionInputFromDto(
        const DecisionDto(action: 'issuePenalty', penaltyKind: 'longLap', penaltyPoints: 9),
      );
      expect(input, isA<IssuePenaltyInput>());
      expect((input as IssuePenaltyInput).points, 9); // not validated here: the domain does it
    });

    test('an unknown action is a MappingException', () {
      expect(() => decisionInputFromDto(const DecisionDto(action: 'explode')), throwsA(isA<MappingException>()));
    });
  });

  group('errors', () {
    final errors = <DomainError>[
      const DescriptionTooShort(4),
      const DescriptionTooLong(301),
      const InvalidTurnNumber(31),
      const InvalidPenaltyPoints(7),
      const ReasonRequired(),
      InvalidTransition(
        from: const Reported(),
        to: PenaltyIssued(penalty: Penalty.automaticLongLap, by: _director, at: _t0),
      ),
      const NotAllowed(),
      const NotFound(),
    ];

    for (final error in errors) {
      test('${error.runtimeType} survives domain -> wire -> domain', () {
        final wire = ApiErrorDto.fromJson(jsonDecode(jsonEncode(domainErrorToDto(error).toJson())) as Json);
        final back = domainErrorFromDto(wire);
        expect(back.runtimeType, error.runtimeType);
        if (error is! ReasonRequired && error is! NotAllowed && error is! NotFound) expect(back, error);
      });
    }

    test('the rule figures travel with the error', () {
      final dto = domainErrorToDto(const DescriptionTooShort(4));
      expect(dto.intData(ErrorKeys.min), IncidentDescription.minLength);
      expect(domainErrorToDto(const InvalidTurnNumber(99)).intData(ErrorKeys.max), TurnNumber.max);
    });

    test('a code this client does not know gives null, so the app can show a generic message', () {
      expect(domainErrorFromDto(const ApiErrorDto(code: 'rule_from_the_future')), isNull);
      expect(domainErrorFromDto(const ApiErrorDto(code: ErrorCodes.sessionExpired)), isNull);
      expect(domainErrorFromDto(const ApiErrorDto(code: ErrorCodes.invalidTurn)), isNull); // figures missing
    });
  });

  test('user and rider round trip', () {
    const user = User(id: UserId('u-1'), username: 'marshal1', role: Role.marshal);
    expect(userFromDto(userToDto(user)), user);
    const rider = Rider(id: RiderId('r-12'), number: 12, name: 'Luka Vidić');
    expect(riderFromDto(riderToDto(rider)), rider);
  });
}
