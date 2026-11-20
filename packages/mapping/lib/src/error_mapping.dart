import 'package:contract/contract.dart';
import 'package:domain/domain.dart';

/// A rule violation as it goes on the wire: a code and the figures of the
/// rule. The words are chosen by the client.
ApiErrorDto domainErrorToDto(DomainError error) => switch (error) {
  DescriptionTooShort(:final length) => ApiErrorDto(
    code: ErrorCodes.descriptionTooShort,
    data: {ErrorKeys.length: length, ErrorKeys.min: IncidentDescription.minLength},
  ),
  DescriptionTooLong(:final length) => ApiErrorDto(
    code: ErrorCodes.descriptionTooLong,
    data: {ErrorKeys.length: length, ErrorKeys.max: IncidentDescription.maxLength},
  ),
  InvalidTurnNumber(:final turn) => ApiErrorDto(
    code: ErrorCodes.invalidTurn,
    data: {ErrorKeys.turn: turn, ErrorKeys.min: TurnNumber.min, ErrorKeys.max: TurnNumber.max},
  ),
  InvalidPenaltyPoints(:final points) => ApiErrorDto(
    code: ErrorCodes.invalidPenaltyPoints,
    data: {ErrorKeys.points: points, ErrorKeys.min: 0, ErrorKeys.max: Penalty.maxPoints},
  ),
  ReasonRequired() => const ApiErrorDto(code: ErrorCodes.reasonRequired),
  InvalidTransition(:final from, :final to) => ApiErrorDto(
    code: ErrorCodes.invalidTransition,
    data: {ErrorKeys.from: from.stage.name, ErrorKeys.to: to.stage.name},
  ),
  NotAllowed() => const ApiErrorDto(code: ErrorCodes.notAllowed),
  NotFound() => const ApiErrorDto(code: ErrorCodes.notFound),
  NotWithdrawable() => const ApiErrorDto(code: ErrorCodes.notWithdrawable),
  WrongApp(:final app) => ApiErrorDto(code: ErrorCodes.wrongApp, data: {ErrorKeys.app: app.name}),
};

/// The domain error behind a wire error, or null when the code is not a rule
/// of this domain: a code from a newer server, or a transport/session code.
/// The caller then shows a generic message and never crashes.
DomainError? domainErrorFromDto(ApiErrorDto dto) {
  switch (dto.code) {
    case ErrorCodes.descriptionTooShort:
      final length = dto.intData(ErrorKeys.length);
      return length == null ? null : DescriptionTooShort(length);
    case ErrorCodes.descriptionTooLong:
      final length = dto.intData(ErrorKeys.length);
      return length == null ? null : DescriptionTooLong(length);
    case ErrorCodes.invalidTurn:
      final turn = dto.intData(ErrorKeys.turn);
      return turn == null ? null : InvalidTurnNumber(turn);
    case ErrorCodes.invalidPenaltyPoints:
      final points = dto.intData(ErrorKeys.points);
      return points == null ? null : InvalidPenaltyPoints(points);
    case ErrorCodes.reasonRequired:
      return const ReasonRequired();
    case ErrorCodes.invalidTransition:
      final from = _stage(dto.stringData(ErrorKeys.from));
      final to = _stage(dto.stringData(ErrorKeys.to));
      if (from == null || to == null) return null;
      return InvalidTransition(from: _placeholder(from), to: _placeholder(to));
    case ErrorCodes.notAllowed:
      return const NotAllowed();
    case ErrorCodes.notFound:
      return const NotFound();
    case ErrorCodes.notWithdrawable:
      return const NotWithdrawable();
    case ErrorCodes.wrongApp:
      final app = _clientApp(dto.stringData(ErrorKeys.app));
      return app == null ? null : WrongApp(app);
    default:
      return null;
  }
}

ClientApp? _clientApp(String? name) {
  for (final app in ClientApp.values) {
    if (app.name == name) return app;
  }
  return null;
}

IncidentStage? _stage(String? name) {
  for (final stage in IncidentStage.values) {
    if (stage.name == name) return stage;
  }
  return null;
}

/// Only the kind of status travels with an `InvalidTransition`, and that is
/// all its equality looks at, so a status of that kind with empty data stands
/// in for the real one.
IncidentStatus _placeholder(IncidentStage stage) {
  const nobody = UserId('');
  final epoch = DateTime.utc(1970);
  return switch (stage) {
    IncidentStage.reported => const Reported(),
    IncidentStage.confirmed => Confirmed(by: nobody, at: epoch),
    IncidentStage.underReview => UnderReview(by: nobody, at: epoch),
    IncidentStage.penaltyIssued => PenaltyIssued(penalty: Penalty.automaticLongLap, by: nobody, at: epoch),
    IncidentStage.dismissed => Dismissed(reason: '', by: nobody, at: epoch),
  };
}
