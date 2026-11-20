/// Paths and headers both sides agree on.
abstract final class ApiPaths {
  static const login = '/api/auth/login';
  static const me = '/api/me';
  static const riders = '/api/riders';
  static const incidents = '/api/incidents';

  /// `DELETE /api/incidents/{id}`: a marshal takes back a report of their own.
  static String incident(String incidentId) => '$incidents/$incidentId';

  /// Public: no login needed.
  static const standings = '/api/standings';

  /// `POST /api/incidents/{id}/decision`
  static String decision(String incidentId) => '$incidents/$incidentId/decision';
}

abstract final class ApiHeaders {
  static const authorization = 'authorization';

  /// Which application is calling, so the server can refuse a login to the
  /// wrong one. It is only a label: rights never depend on it.
  static const clientApp = 'x-client-app';
}

abstract final class ClientApps {
  static const mobile = 'mobile';
  static const backoffice = 'backoffice';
}

abstract final class QueryParams {
  static const stage = 'stage';
  static const riderId = 'riderId';
  static const limit = 'limit';
  static const cursor = 'cursor';
}
