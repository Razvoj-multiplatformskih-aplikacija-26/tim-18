import 'package:blocs/blocs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../app_dependencies.dart';

enum _DebugAction { refresh, failNext }

/// Menu for the demo: reload the list, or make the next request fail so the
/// error screen can be shown. The failure item exists only with a fake repository.
class DebugMenu extends StatelessWidget {
  const DebugMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final failNext = context.read<AppDependencies>().onFailNextRequest;
    return PopupMenuButton<_DebugAction>(
      key: const Key('debug-menu'),
      tooltip: 'Meni',
      onSelected: (action) {
        switch (action) {
          case _DebugAction.refresh:
            context.read<IncidentsBloc>().add(const IncidentsRequested());
          case _DebugAction.failNext:
            failNext?.call();
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: _DebugAction.refresh, child: Text('Osveži')),
        if (failNext != null)
          const PopupMenuItem(value: _DebugAction.failNext, child: Text('Simuliraj grešku sledećeg zahteva')),
      ],
    );
  }
}
