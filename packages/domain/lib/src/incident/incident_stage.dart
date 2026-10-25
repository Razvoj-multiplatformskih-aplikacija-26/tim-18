import 'incident_status.dart';

/// The status without its data: what a filter or a column can compare.
enum IncidentStage { reported, confirmed, underReview, penaltyIssued, dismissed }

extension IncidentStatusStage on IncidentStatus {
  IncidentStage get stage => switch (this) {
    Reported() => IncidentStage.reported,
    Confirmed() => IncidentStage.confirmed,
    UnderReview() => IncidentStage.underReview,
    PenaltyIssued() => IncidentStage.penaltyIssued,
    Dismissed() => IncidentStage.dismissed,
  };
}
