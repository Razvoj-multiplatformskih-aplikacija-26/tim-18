import 'dart:convert';

import 'package:contract/contract.dart';
import 'package:domain/domain.dart';
import 'package:mapping/mapping.dart';
import 'package:postgres/postgres.dart';

import 'http.dart';

typedef _Row = Map<String, Object?>;

const _incidentColumns =
    'id, reporter_id, rider_id, kind, description, turn, reported_at, '
    'stage, status_by, status_at, penalty_kind, penalty_points, dismissal_reason';

/// Everything that touches the database. Rows become domain objects through
/// the mapping package, so a row the domain would reject never gets through.
final class Store {
  Store(this._pool);

  final Pool<void> _pool;

  /// One transaction. If [action] throws, nothing is written.
  Future<T> transaction<T>(Future<T> Function(Session tx) action) => _pool.runTx((tx) => action(tx));

  Future<List<_Row>> _rows(Session session, String sql, [Map<String, Object?> params = const {}]) async {
    final result = await session.execute(Sql.named(sql), parameters: params);
    return [for (final row in result) row.toColumnMap()];
  }

  Future<int> incidentCount() async {
    final rows = await _rows(_pool, 'SELECT count(*) AS n FROM incidents');
    return rows.first['n']! as int;
  }

  // ---- users and riders ----

  /// The password is checked inside the database against its hash.
  Future<User?> userByCredentials(String username, String password) async {
    final rows = await _rows(
      _pool,
      'SELECT id, username, role FROM users WHERE username = @username AND password_hash = crypt(@password, password_hash)',
      {'username': username, 'password': password},
    );
    return rows.isEmpty ? null : _user(rows.first);
  }

  Future<User?> userById(String id) async {
    final rows = await _rows(_pool, 'SELECT id, username, role FROM users WHERE id = @id', {'id': id});
    return rows.isEmpty ? null : _user(rows.first);
  }

  Future<List<Rider>> riders() async {
    final rows = await _rows(_pool, 'SELECT id, number, name FROM riders ORDER BY number');
    return [
      for (final row in rows)
        riderFromDto(RiderDto(id: row['id']! as String, number: row['number']! as int, name: row['name']! as String)),
    ];
  }

  Future<bool> riderExists(Session session, RiderId id) async {
    final rows = await _rows(session, 'SELECT id FROM riders WHERE id = @id', {'id': id.value});
    return rows.isNotEmpty;
  }

  /// Rider points are summed and the long lap is awarded under this lock, so
  /// two decisions about the same rider never run that part at the same time.
  Future<void> lockRider(Session tx, RiderId id) async {
    await _rows(tx, 'SELECT id FROM riders WHERE id = @id FOR UPDATE', {'id': id.value});
  }

  // ---- incidents ----

  Future<Incident?> incidentById(Session session, String id, {bool forUpdate = false}) async {
    final rows = await _rows(
      session,
      'SELECT $_incidentColumns FROM incidents WHERE id = @id${forUpdate ? ' FOR UPDATE' : ''}',
      {'id': id},
    );
    return rows.isEmpty ? null : _incident(rows.first);
  }

  /// False when an incident with this id already exists (the same report sent
  /// twice, as a sync after a lost connection would do).
  Future<bool> insertIncident(Session tx, Incident incident) async {
    final result = await tx.execute(
      Sql.named(
        'INSERT INTO incidents (id, reporter_id, rider_id, kind, description, turn, reported_at) '
        'VALUES (@id, @reporter, @rider, @kind, @description, @turn, @reportedAt) '
        'ON CONFLICT (id) DO NOTHING',
      ),
      parameters: {
        'id': incident.id.value,
        'reporter': incident.reporterId.value,
        'rider': incident.riderId.value,
        'kind': incident.kind.name,
        'description': incident.description.text,
        'turn': incident.turn.value,
        'reportedAt': incident.reportedAt,
      },
    );
    return result.affectedRows == 1;
  }

  Future<void> updateStatus(Session tx, Incident incident) async {
    final status = statusToDto(incident.status);
    await tx.execute(
      Sql.named(
        'UPDATE incidents SET stage = @stage, status_by = @by, status_at = @at, '
        'penalty_kind = @penaltyKind, penalty_points = @penaltyPoints, dismissal_reason = @reason '
        'WHERE id = @id',
      ),
      parameters: {
        'id': incident.id.value,
        'stage': status.stage,
        'by': status.by,
        'at': status.at == null ? null : DateTime.parse(status.at!),
        'penaltyKind': status.penaltyKind,
        'penaltyPoints': status.penaltyPoints,
        'reason': status.reason,
      },
    );
  }

  Future<void> deleteIncident(Session tx, IncidentId id) async {
    await tx.execute(Sql.named('DELETE FROM incidents WHERE id = @id'), parameters: {'id': id.value});
  }

  /// One page, newest first, of what [viewer] may see. The cursor is opaque to
  /// the client: it is the time and id of the last incident of the page.
  Future<({List<Incident> items, String? nextCursor})> listIncidents(
    User viewer, {
    IncidentStage? stage,
    RiderId? riderId,
    required int limit,
    String? cursor,
  }) async {
    final conditions = <String>[];
    final params = <String, Object?>{'limit': limit + 1};

    if (!viewer.role.isDirection) {
      conditions.add('reporter_id = @viewer');
      params['viewer'] = viewer.id.value;
    }
    if (stage != null) {
      conditions.add('stage = @stage');
      params['stage'] = stage.name;
    }
    if (riderId != null) {
      conditions.add('rider_id = @rider');
      params['rider'] = riderId.value;
    }
    if (cursor != null) {
      final (at, id) = _decodeCursor(cursor);
      conditions.add('(reported_at, id) < (@cursorAt, @cursorId)');
      params['cursorAt'] = at;
      params['cursorId'] = id;
    }

    final where = conditions.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')}';
    final rows = await _rows(
      _pool,
      'SELECT $_incidentColumns FROM incidents $where ORDER BY reported_at DESC, id DESC LIMIT @limit',
      params,
    );

    final all = [for (final row in rows) _incident(row)];
    final page = all.take(limit).where((incident) => AccessPolicy.canView(viewer, incident)).toList();
    final hasMore = all.length > limit;
    final last = all.take(limit).lastOrNull;
    return (items: page, nextCursor: hasMore && last != null ? _encodeCursor(last) : null);
  }

  // ---- penalty points and the long lap ----

  Future<List<Incident>> penaltyIncidentsOf(Session session, RiderId rider) async {
    final rows = await _rows(
      session,
      "SELECT $_incidentColumns FROM incidents WHERE rider_id = @rider AND stage = 'penaltyIssued'",
      {'rider': rider.value},
    );
    return [for (final row in rows) _incident(row)];
  }

  /// False when the rider already has the long lap. The primary key of the
  /// table is the last line of defence: it holds even if the lock above did not.
  Future<bool> awardLongLap(Session tx, RiderId rider, IncidentId incident) async {
    final result = await tx.execute(
      Sql.named(
        'INSERT INTO rider_long_laps (rider_id, incident_id) VALUES (@rider, @incident) '
        'ON CONFLICT (rider_id) DO NOTHING',
      ),
      parameters: {'rider': rider.value, 'incident': incident.value},
    );
    return result.affectedRows == 1;
  }

  Future<List<StandingDto>> currentStandings() async {
    final rows = await _rows(_pool, "SELECT $_incidentColumns FROM incidents WHERE stage = 'penaltyIssued'");
    final longLaps = {
      for (final row in await _rows(_pool, 'SELECT rider_id FROM rider_long_laps')) row['rider_id']! as String,
    };
    return [
      for (final standing in standings([for (final row in rows) _incident(row)]))
        standingToDto(standing, longLap: longLaps.contains(standing.riderId.value)),
    ];
  }

  // ---- rows to domain ----

  User _user(_Row row) => userFromDto(
    UserDto(id: row['id']! as String, username: row['username']! as String, role: row['role']! as String),
  );

  Incident _incident(_Row row) {
    String? time(Object? value) => (value as DateTime?)?.toUtc().toIso8601String();
    return incidentFromDto(
      IncidentDto(
        id: row['id']! as String,
        reporterId: row['reporter_id']! as String,
        riderId: row['rider_id']! as String,
        kind: row['kind']! as String,
        description: row['description']! as String,
        turn: row['turn']! as int,
        reportedAt: time(row['reported_at'])!,
        status: StatusDto(
          stage: row['stage']! as String,
          by: row['status_by'] as String?,
          at: time(row['status_at']),
          penaltyKind: row['penalty_kind'] as String?,
          penaltyPoints: row['penalty_points'] as int?,
          reason: row['dismissal_reason'] as String?,
        ),
      ),
    );
  }

  static String _encodeCursor(Incident incident) {
    final text = '${incident.reportedAt.toUtc().toIso8601String()}|${incident.id.value}';
    return base64Url.encode(utf8.encode(text)).replaceAll('=', '');
  }

  static (DateTime, String) _decodeCursor(String cursor) {
    try {
      final text = utf8.decode(base64Url.decode(base64Url.normalize(cursor)));
      final split = text.indexOf('|');
      return (DateTime.parse(text.substring(0, split)).toUtc(), text.substring(split + 1));
    } on FormatException {
      throw ApiException.coded(400, ErrorCodes.badRequest);
    } on RangeError {
      throw ApiException.coded(400, ErrorCodes.badRequest);
    }
  }
}
