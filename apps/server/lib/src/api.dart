import 'dart:io';

import 'package:contract/contract.dart';
import 'package:domain/domain.dart';
import 'package:mapping/mapping.dart';

import 'http.dart';
import 'store.dart';
import 'token.dart';

/// The browser backoffice runs on another origin than the server, so the
/// browser asks first (`OPTIONS`) and only talks to a server that allows it.
/// That is solved here, once, and never in a client.
const _corsHeaders = {
  'access-control-allow-origin': '*',
  'access-control-allow-methods': 'GET, POST, OPTIONS',
  'access-control-allow-headers': 'authorization, content-type, x-client-app',
  'access-control-max-age': '600',
};

const _defaultLimit = 50;
const _maxLimit = 200;

/// A report may not claim to be from the future (a phone with a wrong clock).
const _clockSkew = Duration(minutes: 5);

/// Every rule is checked here before anything is written, with the same domain
/// functions the clients use. Who is calling is known only from the token this
/// server issued, and it is checked on every call.
final class Api {
  Api({required this._store, required this._tokens, DateTime Function()? now}) : _now = now ?? DateTime.now;

  final Store _store;
  final TokenService _tokens;
  final DateTime Function() _now;

  Future<ApiResponse> handle(ApiRequest request) async {
    if (request.method == 'OPTIONS') return const ApiResponse(204, '', headers: _corsHeaders);
    try {
      return (await _route(request)).withHeaders(_corsHeaders);
    } on ApiException catch (e) {
      return ApiResponse.json(e.status, e.error.toJson()).withHeaders(_corsHeaders);
    } on FormatException {
      return _error(400, ErrorCodes.badRequest);
    } on MappingException {
      return _error(400, ErrorCodes.badRequest);
    } catch (error, stack) {
      stderr.writeln('Neočekivana greška: $error\n$stack');
      return _error(500, ErrorCodes.internal);
    }
  }

  ApiResponse _error(int status, String code) =>
      ApiResponse.json(status, ApiErrorDto(code: code).toJson()).withHeaders(_corsHeaders);

  Future<ApiResponse> _route(ApiRequest request) {
    final segments = [
      for (final part in request.path.split('/'))
        if (part.isNotEmpty) part,
    ];
    return switch ((request.method, segments)) {
      ('GET', ['health']) => _health(),
      ('POST', ['api', 'auth', 'login']) => _login(request),
      ('GET', ['api', 'me']) => _me(request),
      ('GET', ['api', 'riders']) => _riders(request),
      ('GET', ['api', 'standings']) => _standings(),
      ('GET', ['api', 'incidents']) => _listIncidents(request),
      ('POST', ['api', 'incidents']) => _report(request),
      ('POST', ['api', 'incidents', final id, 'decision']) => _decide(request, id),
      _ => throw ApiException.coded(404, ErrorCodes.notFound),
    };
  }

  // ---- public ----

  Future<ApiResponse> _health() async => ApiResponse(200, 'ok, incidents: ${await _store.incidentCount()}');

  Future<ApiResponse> _standings() async {
    final standings = await _store.currentStandings();
    return ApiResponse.json(200, [for (final standing in standings) standing.toJson()]);
  }

  // ---- login ----

  Future<ApiResponse> _login(ApiRequest request) async {
    final body = LoginRequestDto.fromJson(request.jsonBody());
    final app = _clientApp(request);

    final user = await _store.userByCredentials(body.username.trim(), body.password);
    if (user == null) throw ApiException.coded(401, ErrorCodes.invalidCredentials);

    // Checked only after the password, so the refusal is not a way to find out
    // which names exist.
    if (!AccessPolicy.canSignIn(user, app)) throw ApiException.domain(WrongApp(app));

    final issued = _tokens.issue(user.id, app: app);
    return ApiResponse.json(
      200,
      LoginResponseDto(
        token: issued.token,
        expiresAt: issued.expiresAt.toIso8601String(),
        user: userToDto(user),
      ).toJson(),
    );
  }

  ClientApp _clientApp(ApiRequest request) {
    final name = request.header(ApiHeaders.clientApp);
    for (final app in ClientApp.values) {
      if (app.name == name) return app;
    }
    throw ApiException.coded(400, ErrorCodes.badRequest);
  }

  /// The caller, from the token only, looked up again on every call.
  Future<User> _authenticate(ApiRequest request) async {
    final header = request.header(ApiHeaders.authorization);
    if (header == null || !header.toLowerCase().startsWith('bearer ')) {
      throw ApiException.coded(401, ErrorCodes.unauthorized);
    }
    final claims = _tokens.verify(header.substring(7).trim());
    final user = await _store.userById(claims.userId.value);
    if (user == null) throw ApiException.coded(401, ErrorCodes.unauthorized);
    return user;
  }

  Future<ApiResponse> _me(ApiRequest request) async {
    final user = await _authenticate(request);
    return ApiResponse.json(200, userToDto(user).toJson());
  }

  Future<ApiResponse> _riders(ApiRequest request) async {
    await _authenticate(request);
    final riders = await _store.riders();
    return ApiResponse.json(200, [for (final rider in riders) riderToDto(rider).toJson()]);
  }

  // ---- incidents ----

  Future<ApiResponse> _listIncidents(ApiRequest request) async {
    final user = await _authenticate(request);

    IncidentStage? stage;
    final stageName = request.query[QueryParams.stage];
    if (stageName != null) {
      stage = IncidentStage.values.where((value) => value.name == stageName).firstOrNull;
      if (stage == null) throw ApiException.coded(400, ErrorCodes.badRequest);
    }

    final limitText = request.query[QueryParams.limit];
    final limit = limitText == null ? _defaultLimit : int.tryParse(limitText);
    if (limit == null || limit < 1 || limit > _maxLimit) throw ApiException.coded(400, ErrorCodes.badRequest);

    final riderText = request.query[QueryParams.riderId];
    final page = await _store.listIncidents(
      user,
      stage: stage,
      riderId: riderText == null ? null : RiderId(riderText),
      limit: limit,
      cursor: request.query[QueryParams.cursor],
    );
    return ApiResponse.json(
      200,
      IncidentPageDto(
        items: [for (final incident in page.items) incidentToDto(incident)],
        nextCursor: page.nextCursor,
      ).toJson(),
    );
  }

  Future<ApiResponse> _report(ApiRequest request) async {
    final user = await _authenticate(request);
    final input = reportInputFromDto(ReportRequestDto.fromJson(request.jsonBody()));

    final now = _now().toUtc();
    final reportedAt = input.reportedAt.isAfter(now.add(_clockSkew)) ? now : input.reportedAt;

    // The same domain function the mobile app calls before it sends.
    final result = reportIncident(
      id: input.id,
      by: user,
      riderId: input.riderId,
      kind: input.kind,
      description: input.description,
      turn: input.turn,
      now: reportedAt,
    );
    final incident = result.valueOrNull;
    if (incident == null) throw ApiException.domain(result.errorOrNull!);

    final (stored, created) = await _store.transaction((tx) async {
      if (!await _store.riderExists(tx, incident.riderId)) throw ApiException.domain(const NotFound());
      if (await _store.insertIncident(tx, incident)) return (incident, true);

      // The same id again: a retry of a report that already got through.
      final existing = await _store.incidentById(tx, incident.id.value);
      if (existing == null || existing.reporterId != user.id) throw ApiException.domain(const NotAllowed());
      return (existing, false);
    });
    return ApiResponse.json(created ? 201 : 200, incidentToDto(stored).toJson());
  }

  Future<ApiResponse> _decide(ApiRequest request, String incidentId) async {
    final user = await _authenticate(request);
    if (!AccessPolicy.canDecide(user)) throw ApiException.domain(const NotAllowed());
    final input = decisionInputFromDto(DecisionDto.fromJson(request.jsonBody()));
    final now = _now().toUtc();

    final decided = await _store.transaction((tx) async {
      // The row is locked until this transaction ends. A second decision about
      // the same incident waits, then reads the new status and is refused by
      // the transition rule: only one of them can pass.
      final current = await _store.incidentById(tx, incidentId, forUpdate: true);
      if (current == null) throw ApiException.domain(const NotFound());

      final result = _apply(input, current, user, now);
      final next = result.valueOrNull;
      if (next == null) throw ApiException.domain(result.errorOrNull!);

      if (next.status case PenaltyIssued(:final penalty)) {
        // The points of a rider come from incidents of several marshals and
        // directors. Under this lock the sum and the threshold are one step.
        await _store.lockRider(tx, next.riderId);
        final before = penaltyPointsOf(next.riderId, await _store.penaltyIncidentsOf(tx, next.riderId));
        await _store.updateStatus(tx, next);
        if (crossesLongLapThreshold(pointsBefore: before, added: penalty.points)) {
          await _store.awardLongLap(tx, next.riderId, next.id);
        }
      } else {
        await _store.updateStatus(tx, next);
      }
      return next;
    });
    return ApiResponse.json(200, incidentToDto(decided).toJson());
  }

  Result<Incident> _apply(DecisionInput input, Incident incident, User by, DateTime now) => switch (input) {
    ConfirmInput() => confirmIncident(incident, by: by, now: now),
    StartReviewInput() => startReview(incident, by: by, now: now),
    IssuePenaltyInput(:final kind, :final points) => _penalize(incident, by, now, kind, points),
    DismissInput(:final reason) => dismissIncident(incident, by: by, now: now, reason: reason),
  };

  Result<Incident> _penalize(Incident incident, User by, DateTime now, PenaltyKind kind, int points) {
    final penalty = Penalty.parse(kind, points);
    final error = penalty.errorOrNull;
    if (error != null) return Failure(error);
    return issuePenalty(incident, by: by, now: now, penalty: penalty.valueOrNull!);
  }
}
