import 'package:flutter/material.dart';

import 'app.dart';
import 'app_dependencies.dart';
import 'data/fake_incident_repository.dart';
import 'data/seed_data.dart';

void main() {
  final repository = FakeIncidentRepository();
  runApp(
    RaceDirectionApp(
      dependencies: AppDependencies(
        repository: repository,
        user: demoMarshal,
        onFailNextRequest: repository.failNextRequest,
        onEmptyNextRequest: repository.emptyNextRequest,
      ),
    ),
  );
}
