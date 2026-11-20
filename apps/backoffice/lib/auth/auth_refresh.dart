import 'dart:async';

import 'package:blocs/auth.dart';
import 'package:flutter/foundation.dart';

/// Tells the router to run its redirect again whenever the login changes.
final class AuthRefresh extends ChangeNotifier {
  AuthRefresh(Stream<AuthState> states) {
    _subscription = states.listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
