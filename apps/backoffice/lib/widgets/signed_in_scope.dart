import 'package:blocs/auth.dart';
import 'package:blocs/blocs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../app_dependencies.dart';
import '../data/server_connection.dart';

/// Everything that exists only while somebody is signed in: the incident BLoC
/// of that user. A new login (even of another user) builds it again.
class SignedInScope extends StatelessWidget {
  const SignedInScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthBloc>().state;
    if (state is! SignedIn) return const SizedBox.shrink();
    return _SessionScope(key: ValueKey(state.session.token), session: state.session, child: child);
  }
}

class _SessionScope extends StatefulWidget {
  const _SessionScope({super.key, required this.session, required this.child});

  final Session session;
  final Widget child;

  @override
  State<_SessionScope> createState() => _SessionScopeState();
}

class _SessionScopeState extends State<_SessionScope> {
  late final AppDependencies _dependencies;
  late final IncidentsBloc _bloc;

  @override
  void initState() {
    super.initState();
    final connection = context.read<ServerConnection>();
    // From here on every call carries this login.
    connection.api.token = widget.session.token;
    _dependencies = AppDependencies(
      repository: connection.repository,
      user: widget.session.user,
      onSignOut: () => context.read<AuthBloc>().add(const SignOutRequested()),
    );
    _bloc = IncidentsBloc(
      repository: _dependencies.repository,
      user: _dependencies.user,
      newId: _dependencies.newId,
      now: _dependencies.now,
    )..add(const IncidentsRequested());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<AppDependencies>.value(
      value: _dependencies,
      child: BlocProvider<IncidentsBloc>.value(value: _bloc, child: widget.child),
    );
  }
}
