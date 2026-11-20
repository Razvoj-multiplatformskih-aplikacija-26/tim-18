import 'dart:convert';

import 'package:blocs/auth.dart';
import 'package:contract/contract.dart';
import 'package:mapping/mapping.dart';

Session sessionFromDto(LoginResponseDto dto) =>
    Session(token: dto.token, expiresAt: DateTime.parse(dto.expiresAt).toUtc(), user: userFromDto(dto.user));

/// What a [SessionStore] keeps: the same message the server sent at sign-in.
/// It holds the token and the user, never the password.
String encodeSession(Session session) => jsonEncode(
  LoginResponseDto(
    token: session.token,
    expiresAt: session.expiresAt.toUtc().toIso8601String(),
    user: userToDto(session.user),
  ).toJson(),
);

/// A stored value that cannot be read is no session at all.
Session? decodeSession(String text) {
  try {
    return sessionFromDto(LoginResponseDto.fromJson(jsonDecode(text) as Json));
  } on Object {
    return null;
  }
}
