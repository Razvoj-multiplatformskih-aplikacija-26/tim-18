import 'package:blocs/auth.dart';
import 'package:contract/contract.dart';
import 'package:mapping/mapping.dart';

import 'api_client.dart';
import 'session_codec.dart';

final class ApiAuthGateway implements AuthGateway {
  ApiAuthGateway(this._api);

  final ApiClient _api;

  @override
  Future<Session> signIn({required String username, required String password}) async {
    try {
      final json = await _api.send(
        'POST',
        ApiPaths.login,
        body: LoginRequestDto(username: username, password: password).toJson(),
        authenticated: false,
      );
      return sessionFromDto(LoginResponseDto.fromJson(json! as Json));
    } on ServerUnavailable {
      throw const AuthException(AuthFailure.unavailable);
    } on ApiFailure catch (failure) {
      if (failure.status >= 500) throw const AuthException(AuthFailure.unavailable);
      switch (failure.error.code) {
        case ErrorCodes.invalidCredentials:
          throw const AuthException(AuthFailure.invalidCredentials);
        case ErrorCodes.wrongApp:
          throw AuthException(AuthFailure.wrongApp, rule: domainErrorFromDto(failure.error));
        default:
          throw const AuthException(AuthFailure.other);
      }
    } on FormatException {
      throw const AuthException(AuthFailure.other);
    } on MappingException {
      throw const AuthException(AuthFailure.other);
    } on TypeError {
      throw const AuthException(AuthFailure.other);
    }
  }
}
