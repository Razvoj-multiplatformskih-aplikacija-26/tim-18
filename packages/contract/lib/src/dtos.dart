import 'json.dart';

final class UserDto {
  const UserDto({required this.id, required this.username, required this.role});

  factory UserDto.fromJson(Json json) => UserDto(
    id: requiredField<String>(json, 'id'),
    username: requiredField<String>(json, 'username'),
    role: requiredField<String>(json, 'role'),
  );

  final String id;
  final String username;

  /// `marshal` or `director`.
  final String role;

  Json toJson() => {'id': id, 'username': username, 'role': role};
}

final class LoginRequestDto {
  const LoginRequestDto({required this.username, required this.password});

  factory LoginRequestDto.fromJson(Json json) => LoginRequestDto(
    username: requiredField<String>(json, 'username'),
    password: requiredField<String>(json, 'password'),
  );

  final String username;
  final String password;

  Json toJson() => {'username': username, 'password': password};
}

final class LoginResponseDto {
  const LoginResponseDto({required this.token, required this.expiresAt, required this.user});

  factory LoginResponseDto.fromJson(Json json) => LoginResponseDto(
    token: requiredField<String>(json, 'token'),
    expiresAt: requiredField<String>(json, 'expiresAt'),
    user: UserDto.fromJson(requiredField<Json>(json, 'user')),
  );

  final String token;

  /// ISO 8601, UTC.
  final String expiresAt;
  final UserDto user;

  Json toJson() => {'token': token, 'expiresAt': expiresAt, 'user': user.toJson()};
}

final class RiderDto {
  const RiderDto({required this.id, required this.number, required this.name});

  factory RiderDto.fromJson(Json json) => RiderDto(
    id: requiredField<String>(json, 'id'),
    number: requiredField<int>(json, 'number'),
    name: requiredField<String>(json, 'name'),
  );

  final String id;
  final int number;
  final String name;

  Json toJson() => {'id': id, 'number': number, 'name': name};
}

/// The status of an incident: the stage and only the data that stage has.
final class StatusDto {
  const StatusDto({required this.stage, this.by, this.at, this.penaltyKind, this.penaltyPoints, this.reason});

  factory StatusDto.fromJson(Json json) => StatusDto(
    stage: requiredField<String>(json, 'stage'),
    by: optionalField<String>(json, 'by'),
    at: optionalField<String>(json, 'at'),
    penaltyKind: optionalField<String>(json, 'penaltyKind'),
    penaltyPoints: optionalField<int>(json, 'penaltyPoints'),
    reason: optionalField<String>(json, 'reason'),
  );

  /// `reported`, `confirmed`, `underReview`, `penaltyIssued` or `dismissed`.
  final String stage;
  final String? by;

  /// ISO 8601, UTC.
  final String? at;
  final String? penaltyKind;
  final int? penaltyPoints;
  final String? reason;

  Json toJson() => {
    'stage': stage,
    if (by != null) 'by': by,
    if (at != null) 'at': at,
    if (penaltyKind != null) 'penaltyKind': penaltyKind,
    if (penaltyPoints != null) 'penaltyPoints': penaltyPoints,
    if (reason != null) 'reason': reason,
  };
}

final class IncidentDto {
  const IncidentDto({
    required this.id,
    required this.reporterId,
    required this.riderId,
    required this.kind,
    required this.description,
    required this.turn,
    required this.reportedAt,
    required this.status,
  });

  factory IncidentDto.fromJson(Json json) => IncidentDto(
    id: requiredField<String>(json, 'id'),
    reporterId: requiredField<String>(json, 'reporterId'),
    riderId: requiredField<String>(json, 'riderId'),
    kind: requiredField<String>(json, 'kind'),
    description: requiredField<String>(json, 'description'),
    turn: requiredField<int>(json, 'turn'),
    reportedAt: requiredField<String>(json, 'reportedAt'),
    status: StatusDto.fromJson(requiredField<Json>(json, 'status')),
  );

  final String id;
  final String reporterId;
  final String riderId;
  final String kind;
  final String description;
  final int turn;

  /// ISO 8601, UTC.
  final String reportedAt;
  final StatusDto status;

  Json toJson() => {
    'id': id,
    'reporterId': reporterId,
    'riderId': riderId,
    'kind': kind,
    'description': description,
    'turn': turn,
    'reportedAt': reportedAt,
    'status': status.toJson(),
  };
}

/// A new report. The id and the time come from the client (a report made
/// without a signal keeps its own time); the reporter never does: the server
/// takes it from the login.
final class ReportRequestDto {
  const ReportRequestDto({
    required this.id,
    required this.riderId,
    required this.kind,
    required this.description,
    required this.turn,
    required this.reportedAt,
  });

  factory ReportRequestDto.fromJson(Json json) => ReportRequestDto(
    id: requiredField<String>(json, 'id'),
    riderId: requiredField<String>(json, 'riderId'),
    kind: requiredField<String>(json, 'kind'),
    description: requiredField<String>(json, 'description'),
    turn: requiredField<int>(json, 'turn'),
    reportedAt: requiredField<String>(json, 'reportedAt'),
  );

  final String id;
  final String riderId;
  final String kind;
  final String description;
  final int turn;
  final String reportedAt;

  Json toJson() => {
    'id': id,
    'riderId': riderId,
    'kind': kind,
    'description': description,
    'turn': turn,
    'reportedAt': reportedAt,
  };
}

/// A decision of the direction. Who decided and when is decided by the server.
final class DecisionDto {
  const DecisionDto({required this.action, this.penaltyKind, this.penaltyPoints, this.reason});

  factory DecisionDto.fromJson(Json json) => DecisionDto(
    action: requiredField<String>(json, 'action'),
    penaltyKind: optionalField<String>(json, 'penaltyKind'),
    penaltyPoints: optionalField<int>(json, 'penaltyPoints'),
    reason: optionalField<String>(json, 'reason'),
  );

  /// `confirm`, `startReview`, `issuePenalty` or `dismiss`.
  final String action;
  final String? penaltyKind;
  final int? penaltyPoints;
  final String? reason;

  Json toJson() => {
    'action': action,
    if (penaltyKind != null) 'penaltyKind': penaltyKind,
    if (penaltyPoints != null) 'penaltyPoints': penaltyPoints,
    if (reason != null) 'reason': reason,
  };
}

/// One page of a long list. [nextCursor] is opaque to the client: it is sent
/// back as is, and null means there is nothing more.
final class IncidentPageDto {
  const IncidentPageDto({required this.items, this.nextCursor});

  factory IncidentPageDto.fromJson(Json json) => IncidentPageDto(
    items: [for (final item in objectList(json, 'items')) IncidentDto.fromJson(item)],
    nextCursor: optionalField<String>(json, 'nextCursor'),
  );

  final List<IncidentDto> items;
  final String? nextCursor;

  Json toJson() => {
    'items': [for (final item in items) item.toJson()],
    if (nextCursor != null) 'nextCursor': nextCursor,
  };
}
