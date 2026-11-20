import 'package:domain/domain.dart';

/// The port through which every client reaches incident data.
///
/// The app supplies an implementation: an in-memory fake now, a server client
/// later. The BLoC only ever talks to this interface.
abstract interface class IncidentRepository {
  /// Incidents [viewer] is allowed to see.
  ///
  /// Throws [RepositoryException] when the data cannot be loaded.
  Future<List<Incident>> incidentsFor(User viewer);

  /// Stores a new incident and returns it as stored.
  ///
  /// Throws [RepositoryException] when it cannot be saved.
  Future<Incident> save(Incident incident);

  /// Replaces the stored incident that has the same id, and returns it.
  ///
  /// Throws [RepositoryException] when it cannot be saved or does not exist.
  Future<Incident> update(Incident incident);

  /// Takes back a report of the signed-in marshal.
  ///
  /// Throws [RepositoryException] when it cannot be done.
  Future<void> withdraw(IncidentId id);
}

/// Why a call to the data source failed, in the terms a screen cares about.
enum RepositoryFailure {
  /// No answer: no network, the server is down or too slow.
  unavailable,

  /// The login ran out or is no longer valid.
  sessionExpired,

  /// The server answered and said no (a rule, or a request it does not accept).
  rejected,

  /// Anything else.
  other,
}

/// Transport or storage failure. Business rule violations are never thrown;
/// they travel as a `Result` with a `DomainError`.
final class RepositoryException implements Exception {
  const RepositoryException(this.message, {this.failure = RepositoryFailure.other, this.rule});

  final String message;
  final RepositoryFailure failure;

  /// The rule the server refused, when it is one this client knows. Null for a
  /// rule from a newer server: the client then shows a plain message.
  final DomainError? rule;

  @override
  String toString() => 'RepositoryException($message)';
}
