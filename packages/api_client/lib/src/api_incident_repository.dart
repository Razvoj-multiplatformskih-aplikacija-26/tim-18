import 'package:blocs/blocs.dart';
import 'package:contract/contract.dart';
import 'package:domain/domain.dart';
import 'package:mapping/mapping.dart';

import 'api_client.dart';

/// The server behind the port the BLoCs already use. The screens and BLoCs do
/// not know whether data comes from here or from a fake.
final class ApiIncidentRepository implements IncidentRepository {
  ApiIncidentRepository(this._api);

  final ApiClient _api;

  static const _pageSize = 200;
  static const _maxPages = 50;

  /// The viewer is only a parameter of the port: what a user may see is
  /// decided by the server from the login.
  @override
  Future<List<Incident>> incidentsFor(User viewer) => _guard(() async {
    final incidents = <Incident>[];
    String? cursor;
    var pages = 0;
    do {
      final json = await _api.send(
        'GET',
        ApiPaths.incidents,
        query: {QueryParams.limit: '$_pageSize', QueryParams.cursor: ?cursor},
      );
      final page = IncidentPageDto.fromJson(json! as Json);
      incidents.addAll(page.items.map(incidentFromDto));
      cursor = page.nextCursor;
    } while (cursor != null && ++pages < _maxPages);
    return incidents;
  });

  @override
  Future<Incident> save(Incident incident) => _guard(() async {
    final json = await _api.send('POST', ApiPaths.incidents, body: reportRequestFromIncident(incident).toJson());
    return incidentFromDto(IncidentDto.fromJson(json! as Json));
  });

  /// The BLoC has already moved the status with the domain function; the
  /// server gets the decision that leads there and runs the same function
  /// again, with its own user and clock.
  @override
  Future<Incident> update(Incident incident) => _guard(() async {
    final json = await _api.send(
      'POST',
      ApiPaths.decision(incident.id.value),
      body: decisionFromStatus(incident.status).toJson(),
    );
    return incidentFromDto(IncidentDto.fromJson(json! as Json));
  });

  @override
  Future<void> withdraw(IncidentId id) => _guard(() async {
    await _api.send('DELETE', ApiPaths.incident(id.value));
  });

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on ServerUnavailable {
      throw const RepositoryException('Server nije dostupan.', failure: RepositoryFailure.unavailable);
    } on ApiFailure catch (failure) {
      if (failure.status >= 500) {
        throw const RepositoryException('Server ne radi.', failure: RepositoryFailure.unavailable);
      }
      if (failure.status == 401) {
        throw const RepositoryException('Prijava više ne važi.', failure: RepositoryFailure.sessionExpired);
      }
      throw RepositoryException(
        'Server je odbio zahtev (${failure.error.code}).',
        failure: RepositoryFailure.rejected,
        rule: domainErrorFromDto(failure.error),
      );
    } on FormatException {
      throw const RepositoryException('Neočekivan odgovor servera.');
    } on MappingException {
      throw const RepositoryException('Neočekivan odgovor servera.');
    } on TypeError {
      throw const RepositoryException('Neočekivan odgovor servera.');
    }
  }
}
