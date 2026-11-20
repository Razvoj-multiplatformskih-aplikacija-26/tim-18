import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../app_dependencies.dart';

/// Sign-out for the signed-in user. Without a server (the fake setup) there
/// is nobody to sign out, so nothing is drawn.
class AccountButton extends StatelessWidget {
  const AccountButton({super.key});

  @override
  Widget build(BuildContext context) {
    final dependencies = context.read<AppDependencies>();
    final onSignOut = dependencies.onSignOut;
    if (onSignOut == null) return const SizedBox.shrink();
    return IconButton(
      key: const Key('sign-out-button'),
      tooltip: 'Odjavi se (${dependencies.user.username})',
      icon: const Icon(Icons.logout),
      onPressed: onSignOut,
    );
  }
}
