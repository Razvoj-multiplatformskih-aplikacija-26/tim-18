import 'package:blocs/blocs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'app_dependencies.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class RaceDirectionApp extends StatefulWidget {
  const RaceDirectionApp({super.key, required this.dependencies, this.router});

  final AppDependencies dependencies;

  /// Tests pass their own router; the app builds one when it is null.
  final GoRouter? router;

  @override
  State<RaceDirectionApp> createState() => _RaceDirectionAppState();
}

class _RaceDirectionAppState extends State<RaceDirectionApp> {
  late final GoRouter _router = widget.router ?? buildRouter();

  @override
  void dispose() {
    if (widget.router == null) _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dependencies = widget.dependencies;
    return RepositoryProvider<AppDependencies>.value(
      value: dependencies,
      child: BlocProvider<IncidentsBloc>(
        create: (_) =>
            IncidentsBloc(repository: dependencies.repository, user: dependencies.user, newId: dependencies.newId)
              ..add(const IncidentsRequested()),
        child: MaterialApp.router(
          title: 'Race Direction',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          routerConfig: _router,
        ),
      ),
    );
  }
}
