import '../errors.dart';
import '../result.dart';
import '../user.dart';
import 'access_policy.dart';
import 'incident.dart';
import 'incident_status.dart';

/// Whether nobody has acted on the report yet. The clients use it to decide
/// whether to offer the action, the server to decide whether to allow it.
bool isWithdrawable(Incident incident) => incident.status is Reported;

/// A marshal takes back a report of their own, as long as it is still
/// "reported". Gives back the incident that is to be removed.
Result<Incident> withdrawIncident(Incident incident, {required User by}) {
  if (!AccessPolicy.canWithdraw(by, incident)) return const Failure(NotAllowed());
  if (!isWithdrawable(incident)) return const Failure(NotWithdrawable());
  return Success(incident);
}
