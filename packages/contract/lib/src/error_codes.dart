/// Error codes on the wire. A code is a stable name, never a sentence: the
/// text the user reads is chosen by the client.
///
/// A client must survive a code it does not know (a newer server): see
/// `domainErrorFromDto` in the mapping package, which returns null for it.
abstract final class ErrorCodes {
  // Rule violations (these have a counterpart in the domain).
  static const descriptionTooShort = 'description_too_short';
  static const descriptionTooLong = 'description_too_long';
  static const invalidTurn = 'invalid_turn';
  static const invalidPenaltyPoints = 'invalid_penalty_points';
  static const reasonRequired = 'reason_required';
  static const invalidTransition = 'invalid_transition';
  static const notAllowed = 'not_allowed';
  static const notFound = 'not_found';
  static const wrongApp = 'wrong_app';
  static const notWithdrawable = 'not_withdrawable';

  // Transport and session (no counterpart in the domain).
  // (`wrong_app` is above: it is a rule of the domain.)
  static const invalidCredentials = 'invalid_credentials';
  static const unauthorized = 'unauthorized';
  static const sessionExpired = 'session_expired';
  static const badRequest = 'bad_request';
  static const internal = 'internal_error';
}

/// Keys of the `data` object of an error: the figures of the rule, so the
/// client can word the message itself.
abstract final class ErrorKeys {
  static const length = 'length';
  static const min = 'min';
  static const max = 'max';
  static const turn = 'turn';
  static const points = 'points';
  static const from = 'from';
  static const to = 'to';
  static const app = 'app';
}
