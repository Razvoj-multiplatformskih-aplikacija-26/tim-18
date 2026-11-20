import 'dart:convert';

import 'package:contract/contract.dart';
import 'package:http/http.dart' as http;

/// The server answered, and the answer was an error.
final class ApiFailure implements Exception {
  const ApiFailure(this.status, this.error);

  final int status;
  final ApiErrorDto error;

  @override
  String toString() => 'ApiFailure($status, ${error.code})';
}

/// There was no answer: no network, the server is down, or it took too long.
final class ServerUnavailable implements Exception {
  const ServerUnavailable([this.cause]);

  final Object? cause;

  @override
  String toString() => 'ServerUnavailable($cause)';
}

/// One HTTP client for both apps. It uses only `package:http`, so the same
/// code runs on the VM (phone, desktop) and in the browser.
///
/// It sends the token it was given and the name of the application, and turns
/// every failure into one of two exceptions, so nothing above it ever waits
/// without end or has to know about sockets.
final class ApiClient {
  ApiClient({
    required this.baseUrl,
    required this.clientApp,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 10),
  }) : _http = httpClient ?? http.Client();

  final Uri baseUrl;

  /// `mobile` or `backoffice`, see [ClientApps].
  final String clientApp;
  final Duration timeout;
  final http.Client _http;

  /// The token of the current login. The app sets it when the user signs in
  /// and clears it when they sign out.
  String? token;

  /// Called when the server says the login is no longer good, so the app can
  /// tell the user and return to the sign-in screen.
  void Function()? onSessionExpired;

  /// Sends a request and gives back the decoded JSON of the answer (null when
  /// it has no body). Throws [ApiFailure] or [ServerUnavailable].
  Future<Object?> send(
    String method,
    String path, {
    Map<String, String> query = const {},
    Object? body,
    bool authenticated = true,
  }) async {
    final request = http.Request(method, baseUrl.replace(path: path, queryParameters: query.isEmpty ? null : query));
    request.headers[ApiHeaders.clientApp] = clientApp;
    final current = token;
    if (authenticated && current != null) request.headers[ApiHeaders.authorization] = 'Bearer $current';
    if (body != null) {
      request.headers['content-type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    final http.Response response;
    try {
      final streamed = await _http.send(request).timeout(timeout);
      response = await http.Response.fromStream(streamed).timeout(timeout);
    } on Object catch (error) {
      // Socket errors, a refused connection, a browser that cannot reach the
      // server, a timeout: for the user it is all the same.
      throw ServerUnavailable(error);
    }

    final decoded = _decode(response);
    if (response.statusCode >= 200 && response.statusCode < 300) return decoded;

    final error = decoded is Map<String, Object?> ? ApiErrorDto.fromJson(decoded) : const ApiErrorDto(code: 'unknown');
    final sessionIsOver =
        authenticated &&
        current != null &&
        (error.code == ErrorCodes.sessionExpired ||
            (response.statusCode == 401 && error.code == ErrorCodes.unauthorized));
    if (sessionIsOver) onSessionExpired?.call();
    throw ApiFailure(response.statusCode, error);
  }

  Object? _decode(http.Response response) {
    if (response.bodyBytes.isEmpty) return null;
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      return null;
    }
  }

  void close() => _http.close();
}
