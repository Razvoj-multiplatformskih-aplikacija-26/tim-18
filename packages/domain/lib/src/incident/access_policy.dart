import '../user.dart';
import 'incident.dart';

abstract final class AccessPolicy {
  static bool canReport(User user) => user.role == Role.marshal;

  static bool canView(User user, Incident incident) => user.role.isDirection || incident.reporterId == user.id;

  static bool canDecide(User user) => user.role.isDirection;
}
