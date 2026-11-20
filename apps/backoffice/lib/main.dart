import 'package:flutter/material.dart';

import 'data/server_connection.dart';
import 'root_app.dart';

/// The real app: everything comes from the server. The version on the fake
/// repository is `main_fake.dart` (`flutter run -t lib/main_fake.dart`).
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(BackofficeRoot(connection: ServerConnection.real()));
}
