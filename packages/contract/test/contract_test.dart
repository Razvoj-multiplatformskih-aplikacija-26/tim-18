import 'dart:convert';

import 'package:contract/contract.dart';
import 'package:test/test.dart';

Json _roundTrip(Json json) => jsonDecode(jsonEncode(json)) as Json;

void main() {
  group('incident', () {
    test('every status survives encoding', () {
      const statuses = [
        StatusDto(stage: 'reported'),
        StatusDto(stage: 'confirmed', by: 'u-1', at: '2026-10-18T14:27:00.000Z'),
        StatusDto(
          stage: 'penaltyIssued',
          by: 'u-1',
          at: '2026-10-18T14:30:00.000Z',
          penaltyKind: 'warning',
          penaltyPoints: 1,
        ),
        StatusDto(stage: 'dismissed', by: 'u-1', at: '2026-10-18T14:58:00.000Z', reason: 'Prednost nije ostvarena.'),
      ];
      for (final status in statuses) {
        final decoded = StatusDto.fromJson(_roundTrip(status.toJson()));
        expect(_roundTrip(decoded.toJson()), _roundTrip(status.toJson()));
      }
    });

    test('a page keeps its items and cursor', () {
      const incident = IncidentDto(
        id: 'i-1',
        reporterId: 'u-1',
        riderId: 'r-12',
        kind: 'crash',
        description: 'Vozač je pao u krivini 3.',
        turn: 3,
        reportedAt: '2026-10-18T14:05:00.000Z',
        status: StatusDto(stage: 'reported'),
      );
      const page = IncidentPageDto(items: [incident], nextCursor: 'abc');
      final decoded = IncidentPageDto.fromJson(_roundTrip(page.toJson()));
      expect(decoded.items.single.id, 'i-1');
      expect(decoded.nextCursor, 'abc');
    });

    test('a message without a required field is a FormatException', () {
      expect(() => IncidentDto.fromJson({'id': 'i-1'}), throwsFormatException);
      expect(() => UserDto.fromJson({'id': 1, 'username': 'x', 'role': 'marshal'}), throwsFormatException);
    });

    test('extra fields from a newer server are ignored', () {
      final user = UserDto.fromJson({'id': 'u', 'username': 'x', 'role': 'marshal', 'avatar': 'new-field'});
      expect(user.username, 'x');
    });
  });

  group('ApiErrorDto', () {
    test('keeps code and data', () {
      const error = ApiErrorDto(code: ErrorCodes.descriptionTooShort, data: {ErrorKeys.length: 4, ErrorKeys.min: 10});
      final decoded = ApiErrorDto.fromJson(_roundTrip(error.toJson()));
      expect(decoded.code, ErrorCodes.descriptionTooShort);
      expect(decoded.intData(ErrorKeys.min), 10);
    });

    test('garbage still decodes, to an unknown code', () {
      final decoded = ApiErrorDto.fromJson({'message': 'neki tekst'});
      expect(decoded.code, 'unknown');
      expect(decoded.data, isEmpty);
    });
  });
}
