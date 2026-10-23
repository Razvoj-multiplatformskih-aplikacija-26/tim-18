import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';

/// Everything the app needs from the outside: where data comes from and who is
/// signed in. Screens never see the concrete repository.
class AppDependencies {
  AppDependencies({required this.repository, required this.user, this.onFailNextRequest, IncidentId Function()? newId})
    : newId = newId ?? _timestampId;

  final IncidentRepository repository;
  final User user;
  final IncidentId Function() newId;

  /// Set only while a fake repository is plugged in; it drives the demo menu.
  final void Function()? onFailNextRequest;

  static IncidentId _timestampId() => IncidentId('i-${DateTime.now().microsecondsSinceEpoch}');
}
