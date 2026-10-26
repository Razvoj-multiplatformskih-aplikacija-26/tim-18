import 'package:blocs/blocs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../app_dependencies.dart';

enum _DebugAction { refresh, failNext, showEmpty }

/// Menu for the demo: reload the list, make the next request fail, or show the
/// empty list. The last two exist only with a fake repository.
class DebugMenu extends StatelessWidget {
  const DebugMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final dependencies = context.read<AppDependencies>();
    final failNext = dependencies.onFailNextRequest;
    final emptyNext = dependencies.onEmptyNextRequest;
    return PopupMenuButton<_DebugAction>(
      key: const Key('debug-menu'),
      tooltip: 'Meni',
      onSelected: (action) {
        final bloc = context.read<IncidentsBloc>();
        switch (action) {
          case _DebugAction.refresh:
            bloc.add(const IncidentsRequested());
          case _DebugAction.failNext:
            failNext?.call();
          case _DebugAction.showEmpty:
            emptyNext?.call();
            bloc.add(const IncidentsRequested());
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: _DebugAction.refresh, child: Text('Osveži')),
        if (failNext != null)
          const PopupMenuItem(value: _DebugAction.failNext, child: Text('Simuliraj grešku sledećeg zahteva')),
        if (emptyNext != null) const PopupMenuItem(value: _DebugAction.showEmpty, child: Text('Prikaži praznu listu')),
      ],
    );
  }
}
