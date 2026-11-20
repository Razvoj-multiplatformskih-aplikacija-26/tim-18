import 'dart:convert';

import 'package:contract/contract.dart';
import 'package:domain/domain.dart';
import 'package:mapping/mapping.dart';

/// A request as the API sees it. The web framework is only an adapter that
/// builds this, so the rules below never depend on it.
final class ApiRequest {
  const ApiRequest({
    required this.method,
    required this.path,
    this.query = const {},
    this.headers = const {},
    this.body = '',
  });

  /// Upper case: `GET`, `POST`, `OPTIONS`.
  final String method;
  final String path;
  final Map<String, String> query;

  /// Lower case names.
  final Map<String, String> headers;
  final String body;

  String? header(String name) => headers[name.toLowerCase()];

  Json jsonBody() {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, Object?>) return decoded;
    } on FormatException {
      // falls through to the error below
    }
    throw ApiException.coded(400, ErrorCodes.badRequest);
  }
}

final class ApiResponse {
  const ApiResponse(this.status, this.body, {this.headers = const {}});

  factory ApiResponse.json(int status, Object? json) => ApiResponse(status, jsonEncode(json));

  final int status;
  final String body;
  final Map<String, String> headers;

  ApiResponse withHeaders(Map<String, String> extra) => ApiResponse(status, body, headers: {...headers, ...extra});
}

/// An answer other than success. It carries the HTTP status and the error as
/// it travels (code and data, no text).
final class ApiException implements Exception {
  ApiException(this.status, this.error);

  ApiException.coded(this.status, String code) : error = ApiErrorDto(code: code);

  /// A rule violation, with the same code a client would get from its own check.
  factory ApiException.domain(DomainError error) => ApiException(_statusFor(error), domainErrorToDto(error));

  final int status;
  final ApiErrorDto error;

  @override
  String toString() => 'ApiException($status, ${error.code})';
}

int _statusFor(DomainError error) => switch (error) {
  NotAllowed() || WrongApp() => 403,
  NotFound() => 404,
  InvalidTransition() => 409,
  _ => 422,
};
