import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';

const marshal = User(id: UserId('u-marshal'), username: 'marshal1', role: Role.marshal);
const otherMarshal = User(id: UserId('u-marshal-2'), username: 'marshal2', role: Role.marshal);
const director = User(id: UserId('u-director'), username: 'director1', role: Role.director);

const rider93 = RiderId('r-93');

final raceStart = DateTime.utc(2026, 11, 8, 14);

Incident incident(
  String id, {
  UserId reporterId = const UserId('u-marshal'),
  int minutes = 0,
  IncidentStatus status = const Reported(),
}) {
  return Incident(
    id: IncidentId(id),
    reporterId: reporterId,
    riderId: rider93,
    kind: IncidentKind.trackLimits,
    description: IncidentDescription.parse('Vozač je prešao liniju staze u krivini.').valueOrNull!,
    turn: TurnNumber.parse(5).valueOrNull!,
    reportedAt: raceStart.add(Duration(minutes: minutes)),
    status: status,
  );
}

/// In-memory stand-in for the real data source, with a switch that fails the
/// next call.
class FakeIncidentRepository implements IncidentRepository {
  FakeIncidentRepository([List<Incident> seed = const []]) : _incidents = [...seed];

  final List<Incident> _incidents;
  bool failNext = false;
  int saveCalls = 0;
  int updateCalls = 0;
  int withdrawCalls = 0;

  /// What the next failing call throws. Defaults to a plain failure.
  RepositoryException? failWith;

  @override
  Future<List<Incident>> incidentsFor(User viewer) async {
    _failIfRequested();
    return [
      for (final incident in _incidents)
        if (AccessPolicy.canView(viewer, incident)) incident,
    ];
  }

  @override
  Future<Incident> save(Incident incident) async {
    saveCalls++;
    _failIfRequested();
    _incidents.add(incident);
    return incident;
  }

  @override
  Future<Incident> update(Incident incident) async {
    updateCalls++;
    _failIfRequested();
    final index = _incidents.indexWhere((stored) => stored.id == incident.id);
    if (index == -1) throw const RepositoryException('unknown incident');
    _incidents[index] = incident;
    return incident;
  }

  @override
  Future<void> withdraw(IncidentId id) async {
    withdrawCalls++;
    _failIfRequested();
    _incidents.removeWhere((stored) => stored.id == id);
  }

  void _failIfRequested() {
    if (!failNext) return;
    failNext = false;
    final failure = failWith;
    failWith = null;
    throw failure ?? const RepositoryException('simulated failure');
  }
}
