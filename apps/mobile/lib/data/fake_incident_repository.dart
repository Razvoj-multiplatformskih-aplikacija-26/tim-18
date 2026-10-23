import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';

import 'seed_data.dart';

/// In-memory stand-in for the server. Every call takes [latency], and
/// [failNextRequest] makes the next call throw, so the loading and error
/// screens can be shown on demand.
class FakeIncidentRepository implements IncidentRepository {
  FakeIncidentRepository({List<Incident>? seed, this.latency = const Duration(milliseconds: 700)})
    : _incidents = [...(seed ?? seedIncidents())];

  final Duration latency;
  final List<Incident> _incidents;
  bool _failNext = false;

  /// The next request will fail with a [RepositoryException].
  void failNextRequest() => _failNext = true;

  @override
  Future<List<Incident>> incidentsFor(User viewer) async {
    await _simulateNetwork();
    return [
      for (final incident in _incidents)
        if (AccessPolicy.canView(viewer, incident)) incident,
    ];
  }

  @override
  Future<Incident> save(Incident incident) async {
    await _simulateNetwork();
    _incidents.add(incident);
    return incident;
  }

  Future<void> _simulateNetwork() async {
    await Future<void>.delayed(latency);
    if (!_failNext) return;
    _failNext = false;
    throw const RepositoryException('Simulirana greška servera.');
  }
}
