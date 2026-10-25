import 'package:domain/domain.dart';

import '../data/seed_data.dart';

/// Serbian wording for domain values. The domain stays language-free; every
/// client decides how to word it.
extension IncidentKindLabel on IncidentKind {
  String get label => switch (this) {
    IncidentKind.crash => 'Pad',
    IncidentKind.illegalOvertake => 'Nedozvoljeno preticanje',
    IncidentKind.trackLimits => 'Prelazak granica staze',
    IncidentKind.jumpStart => 'Prerani start',
    IncidentKind.dangerousRiding => 'Opasna vožnja',
  };
}

extension PenaltyKindLabel on PenaltyKind {
  String get label => switch (this) {
    PenaltyKind.warning => 'Upozorenje',
    PenaltyKind.longLap => 'Long lap penalty',
    PenaltyKind.rideThrough => 'Ride through penalty',
    PenaltyKind.positionDrop => 'Gubitak pozicija',
  };
}

extension IncidentStatusLabel on IncidentStatus {
  String get label => switch (this) {
    Reported() => 'Prijavljen',
    Confirmed() => 'Potvrđen',
    UnderReview() => 'U razmatranju',
    PenaltyIssued() => 'Kazna izrečena',
    Dismissed() => 'Odbačen',
  };
}

String pointsLabel(int points) => points == 1 ? '1 poen' : '$points poena';

String formatTime(DateTime time) {
  final utc = time.toUtc();
  return '${_twoDigits(utc.hour)}:${_twoDigits(utc.minute)}';
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');

String riderLabel(RiderId id) {
  for (final rider in riders) {
    if (rider.id == id) return '#${rider.number} ${rider.name}';
  }
  return id.value;
}

/// One line about how the incident was handled, or null while it is only reported.
String? statusNote(IncidentStatus status) => switch (status) {
  Reported() => null,
  Confirmed(:final at) => 'Potvrđen u ${formatTime(at)}',
  UnderReview(:final at) => 'U razmatranju od ${formatTime(at)}',
  PenaltyIssued(:final penalty, :final at) =>
    '${penalty.kind.label}, ${pointsLabel(penalty.points)} (${formatTime(at)})',
  Dismissed(:final reason) => 'Razlog: $reason',
};

extension IncidentStageLabel on IncidentStage {
  String get label => switch (this) {
    IncidentStage.reported => 'Prijavljen',
    IncidentStage.confirmed => 'Potvrđen',
    IncidentStage.underReview => 'U razmatranju',
    IncidentStage.penaltyIssued => 'Kazna izrečena',
    IncidentStage.dismissed => 'Odbačen',
  };
}

extension DecisionLabel on Decision {
  String get label => switch (this) {
    Decision.confirm => 'Potvrdi',
    Decision.startReview => 'Započni razmatranje',
    Decision.issuePenalty => 'Izreci kaznu',
    Decision.dismiss => 'Odbaci',
  };
}
