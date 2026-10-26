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
  bool _emptyNext = false;

  /// The next request will fail with a [RepositoryException].
  void failNextRequest() => _failNext = true;

  /// The next list request will come back empty, once.
  void emptyNextRequest() => _emptyNext = true;

  @override
  Future<List<Incident>> incidentsFor(User viewer) async {
    await _simulateNetwork();
    if (_emptyNext) {
      _emptyNext = false;
      return [];
    }
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

  @override
  Future<Incident> update(Incident incident) async {
    await _simulateNetwork();
    final index = _incidents.indexWhere((stored) => stored.id == incident.id);
    if (index == -1) throw const RepositoryException('Incident ne postoji.');
    _incidents[index] = incident;
    return incident;
  }

  Future<void> _simulateNetwork() async {
    await Future<void>.delayed(latency);
    if (!_failNext) return;
    _failNext = false;
    throw const RepositoryException('Simulirana greška servera.');
  }
}
