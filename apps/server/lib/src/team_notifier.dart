import 'dart:io';

import 'package:domain/domain.dart';

/// What the server tells a team when its rider is penalised.
final class PenaltyNotice {
  const PenaltyNotice({
    required this.riderId,
    required this.incidentId,
    required this.penalty,
    required this.longLapAwarded,
  });

  final RiderId riderId;
  final IncidentId incidentId;
  final Penalty penalty;

  /// Whether this penalty took the rider over the threshold, so the long lap
  /// penalty was handed out with it.
  final bool longLapAwarded;
}

/// The one outside service of this system: the teams are told about a penalty.
/// Only the server talks to it, and only through this port, so the key never
/// reaches a client and the real service can replace the fake without touching
/// the rules.
abstract interface class TeamNotifier {
  Future<void> penaltyIssued(PenaltyNotice notice);
}

/// The fake used until a real service exists: it keeps what it was asked to
/// send and writes it to the log. The key is used as the real one would be (as
/// a bearer token) and never printed in full.
final class FakeTeamNotifier implements TeamNotifier {
  FakeTeamNotifier({required this.apiKey, void Function(String line)? log}) : _log = log ?? stdout.writeln;

  final String apiKey;
  final void Function(String line) _log;

  /// Everything sent so far (for tests).
  final List<PenaltyNotice> sent = [];

  @override
  Future<void> penaltyIssued(PenaltyNotice notice) async {
    sent.add(notice);
    final penalty = notice.penalty;
    _log(
      '[servis timova] ${notice.riderId.value}: ${penalty.kind.name}, ${penalty.points} poena '
      '(incident ${notice.incidentId.value})'
      '${notice.longLapAwarded ? ', dodeljen long lap' : ''} · ključ ${_masked()}',
    );
  }

  String _masked() => apiKey.length <= 4 ? '****' : '****${apiKey.substring(apiKey.length - 4)}';
}
