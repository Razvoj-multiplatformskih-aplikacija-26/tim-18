import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';

/// Everything the app needs from the outside: where data comes from, who is
/// signed in, and how ids and time are produced. Screens never see the
/// concrete repository.
class AppDependencies {
  AppDependencies({
    required this.repository,
    required this.user,
    this.onFailNextRequest,
    IncidentId Function()? newId,
    this.now,
  }) : newId = newId ?? _timestampId;

  final IncidentRepository repository;
  final User user;
  final IncidentId Function() newId;

  /// The clock the BLoC stamps reports with. Null means the real clock.
  final DateTime Function()? now;

  /// Set only while a fake repository is plugged in; it drives the demo menu.
  final void Function()? onFailNextRequest;

  static IncidentId _timestampId() => IncidentId('i-${DateTime.now().microsecondsSinceEpoch}');
}
