import 'package:blocs/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../text/auth_messages.dart';
import '../text/error_messages.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<AuthBloc>().add(SignInSubmitted(username: _username.text, password: _password.text));
  }

  /// Why the user is on this screen, when there is a reason.
  String? _noticeFor(AuthState state) {
    if (state is! SignedOut) return null;
    return state.rule?.message ?? state.notice?.message;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthBloc>().state;
    final signingIn = state is SigningIn;
    final notice = _noticeFor(state);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Race Direction', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    Text('Prijava za osoblje trke', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 24),
                    if (notice != null) ...[
                      Container(
                        key: const Key('login-notice'),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: scheme.errorContainer, borderRadius: BorderRadius.circular(8)),
                        child: Text(notice, style: TextStyle(color: scheme.onErrorContainer)),
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      key: const Key('username-field'),
                      autofocus: true,
                      controller: _username,
                      enabled: !signingIn,
                      decoration: const InputDecoration(labelText: 'Korisničko ime'),
                      autofillHints: const [AutofillHints.username],
                      textInputAction: TextInputAction.next,
                      validator: (value) => (value ?? '').trim().isEmpty ? 'Unesite korisničko ime.' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('password-field'),
                      controller: _password,
                      enabled: !signingIn,
                      decoration: const InputDecoration(labelText: 'Lozinka'),
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                      onFieldSubmitted: (_) => _submit(),
                      validator: (value) => (value ?? '').isEmpty ? 'Unesite lozinku.' : null,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      key: const Key('sign-in-button'),
                      onPressed: signingIn ? null : _submit,
                      child: signingIn
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Prijavi se'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
