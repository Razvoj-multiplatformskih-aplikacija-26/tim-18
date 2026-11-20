import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';

/// A login the server issued: the token, when it runs out, and who it is for.
final class Session extends Equatable {
  const Session({required this.token, required this.expiresAt, required this.user});

  final String token;
  final DateTime expiresAt;
  final User user;

  bool hasExpired(DateTime now) => !now.isBefore(expiresAt);

  @override
  List<Object?> get props => [token, expiresAt, user];
}
