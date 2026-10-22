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
}

/// Transport or storage failure. Business rule violations are never thrown;
/// they travel as a `Result` with a `DomainError`.
final class RepositoryException implements Exception {
  const RepositoryException(this.message);

  final String message;

  @override
  String toString() => 'RepositoryException($message)';
}
