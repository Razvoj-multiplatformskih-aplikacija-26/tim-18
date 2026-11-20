import '../client_app.dart';
import '../user.dart';
import 'incident.dart';

/// Who may do what. The clients use it to decide what to offer and the server
/// uses the same functions to decide what to allow.
abstract final class AccessPolicy {
  /// The mobile app is for marshals, the backoffice for the race direction.
  static bool canSignIn(User user, ClientApp app) => switch (app) {
    ClientApp.mobile => user.role == Role.marshal,
    ClientApp.backoffice => user.role.isDirection,
  };

  static bool canReport(User user) => user.role == Role.marshal;

  static bool canView(User user, Incident incident) => user.role.isDirection || incident.reporterId == user.id;

  static bool canDecide(User user) => user.role.isDirection;
}
