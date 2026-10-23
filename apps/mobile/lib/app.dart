import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'router.dart';
import 'theme/app_theme.dart';

class RaceDirectionApp extends StatefulWidget {
  const RaceDirectionApp({super.key, this.router});

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
    return MaterialApp.router(
      title: 'Race Direction',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: _router,
    );
  }
}
