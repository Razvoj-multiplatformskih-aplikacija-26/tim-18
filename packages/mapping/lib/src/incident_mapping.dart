import 'package:contract/contract.dart';
import 'package:domain/domain.dart';

import 'mapping_exception.dart';
import 'user_mapping.dart';

String _time(DateTime time) => time.toUtc().toIso8601String();

DateTime _parseTime(String? text, String what) {
  if (text == null) throw MappingException('Nedostaje vreme za $what.');
  final parsed = DateTime.tryParse(text);
  if (parsed == null) throw MappingException('Vreme "$text" nije ispravno ($what).');
  return parsed.toUtc();
}

T _present<T>(T? value, String what) {
  if (value == null) throw MappingException('Nedostaje $what.');
  return value;
}

T _valid<T>(Result<T> result, String what) {
  final value = result.valueOrNull;
  if (value == null) throw MappingException('Vrednost nije prihvaćena ($what): ${result.errorOrNull}.');
  return value;
}

// ---- status ----

StatusDto statusToDto(IncidentStatus status) => switch (status) {
  Reported() => StatusDto(stage: IncidentStage.reported.name),
  Confirmed(:final by, :final at) => StatusDto(stage: IncidentStage.confirmed.name, by: by.value, at: _time(at)),
  UnderReview(:final by, :final at) => StatusDto(stage: IncidentStage.underReview.name, by: by.value, at: _time(at)),
  PenaltyIssued(:final penalty, :final by, :final at) => StatusDto(
    stage: IncidentStage.penaltyIssued.name,
    by: by.value,
    at: _time(at),
    penaltyKind: penalty.kind.name,
    penaltyPoints: penalty.points,
  ),
  Dismissed(:final reason, :final by, :final at) => StatusDto(
    stage: IncidentStage.dismissed.name,
    by: by.value,
    at: _time(at),
    reason: reason,
  ),
};

IncidentStatus statusFromDto(StatusDto dto) {
  final stage = enumByName(IncidentStage.values, dto.stage, 'stage');
  if (stage == IncidentStage.reported) return const Reported();

  final by = UserId(_present(dto.by, 'by'));
  final at = _parseTime(dto.at, 'at');
  return switch (stage) {
    IncidentStage.reported => const Reported(),
    IncidentStage.confirmed => Confirmed(by: by, at: at),
    IncidentStage.underReview => UnderReview(by: by, at: at),
    IncidentStage.penaltyIssued => PenaltyIssued(
      penalty: _valid(
        Penalty.parse(
          enumByName(PenaltyKind.values, _present(dto.penaltyKind, 'penaltyKind'), 'penaltyKind'),
          _present(dto.penaltyPoints, 'penaltyPoints'),
        ),
        'penalty',
      ),
      by: by,
      at: at,
    ),
    IncidentStage.dismissed => Dismissed(reason: _present(dto.reason, 'reason'), by: by, at: at),
  };
}

// ---- incident ----

IncidentDto incidentToDto(Incident incident) => IncidentDto(
  id: incident.id.value,
  reporterId: incident.reporterId.value,
  riderId: incident.riderId.value,
  kind: incident.kind.name,
  description: incident.description.text,
  turn: incident.turn.value,
  reportedAt: _time(incident.reportedAt),
  status: statusToDto(incident.status),
);

Incident incidentFromDto(IncidentDto dto) => Incident(
  id: IncidentId(dto.id),
  reporterId: UserId(dto.reporterId),
  riderId: RiderId(dto.riderId),
  kind: enumByName(IncidentKind.values, dto.kind, 'kind'),
  description: _valid(IncidentDescription.parse(dto.description), 'description'),
  turn: _valid(TurnNumber.parse(dto.turn), 'turn'),
  reportedAt: _parseTime(dto.reportedAt, 'reportedAt'),
  status: statusFromDto(dto.status),
);

// ---- report ----

/// What the client sends for a report it has just made (and validated).
ReportRequestDto reportRequestFromIncident(Incident incident) => ReportRequestDto(
  id: incident.id.value,
  riderId: incident.riderId.value,
  kind: incident.kind.name,
  description: incident.description.text,
  turn: incident.turn.value,
  reportedAt: _time(incident.reportedAt),
);

/// The raw input of a report as the server received it: nothing is validated
/// here, `reportIncident` in the domain does that.
final class ReportInput {
  const ReportInput({
    required this.id,
    required this.riderId,
    required this.kind,
    required this.description,
    required this.turn,
    required this.reportedAt,
  });

  final IncidentId id;
  final RiderId riderId;
  final IncidentKind kind;
  final String description;
  final int turn;
  final DateTime reportedAt;
}

ReportInput reportInputFromDto(ReportRequestDto dto) => ReportInput(
  id: IncidentId(dto.id),
  riderId: RiderId(dto.riderId),
  kind: enumByName(IncidentKind.values, dto.kind, 'kind'),
  description: dto.description,
  turn: dto.turn,
  reportedAt: _parseTime(dto.reportedAt, 'reportedAt'),
);

// ---- decisions ----

/// The client holds an incident whose status it has already moved; the server
/// needs the decision that leads there. The domain function runs again on the
/// server, with the server's user and clock.
DecisionDto decisionFromStatus(IncidentStatus status) => switch (status) {
  Confirmed() => DecisionDto(action: Decision.confirm.name),
  UnderReview() => DecisionDto(action: Decision.startReview.name),
  PenaltyIssued(:final penalty) => DecisionDto(
    action: Decision.issuePenalty.name,
    penaltyKind: penalty.kind.name,
    penaltyPoints: penalty.points,
  ),
  Dismissed(:final reason) => DecisionDto(action: Decision.dismiss.name, reason: reason),
  Reported() => throw const MappingException('Nijedna odluka ne vodi u stanje "prijavljen".'),
};

/// A decision as the server received it, parsed to values. Penalty points and
/// the reason are still raw: the domain validates them.
sealed class DecisionInput {
  const DecisionInput();
}

final class ConfirmInput extends DecisionInput {
  const ConfirmInput();
}

final class StartReviewInput extends DecisionInput {
  const StartReviewInput();
}

final class IssuePenaltyInput extends DecisionInput {
  const IssuePenaltyInput({required this.kind, required this.points});

  final PenaltyKind kind;
  final int points;
}

final class DismissInput extends DecisionInput {
  const DismissInput({required this.reason});

  final String reason;
}

DecisionInput decisionInputFromDto(DecisionDto dto) {
  return switch (enumByName(Decision.values, dto.action, 'action')) {
    Decision.confirm => const ConfirmInput(),
    Decision.startReview => const StartReviewInput(),
    Decision.issuePenalty => IssuePenaltyInput(
      kind: enumByName(PenaltyKind.values, _present(dto.penaltyKind, 'penaltyKind'), 'penaltyKind'),
      points: _present(dto.penaltyPoints, 'penaltyPoints'),
    ),
    Decision.dismiss => DismissInput(reason: dto.reason ?? ''),
  };
}
