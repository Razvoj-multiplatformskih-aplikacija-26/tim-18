import '../identifiers.dart';
import '../incident/incident.dart';
import '../incident/incident_stage.dart';

/// Incidents that match every filter that is set. A null filter matches all.
List<Incident> filterIncidents(Iterable<Incident> incidents, {IncidentStage? stage, RiderId? riderId}) {
  return [
    for (final incident in incidents)
      if ((stage == null || incident.status.stage == stage) && (riderId == null || incident.riderId == riderId))
        incident,
  ];
}
