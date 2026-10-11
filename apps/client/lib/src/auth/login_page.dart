import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rs_api_client/rs_api_client.dart';
import 'package:rs_core/rs_core.dart';
import 'package:rs_theme/rs_theme.dart';
import 'package:rs_ui/rs_ui.dart';

import '../connection/connection_provider.dart';
import '../onboarding/onboarding_widgets.dart';
import '../session/session_provider.dart';

/// Username and password for a server that is already set up. A successful
/// login leaves this page on its own: the router goes to the home screen.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _usernameFocus = FocusNode(debugLabel: 'Login.username');
  final _passwordFocus = FocusNode(debugLabel: 'Login.password');
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final username = _username.text.trim();
    final password = _password.text;
    if (username.isEmpty || password.isEmpty) {
      setState(() => _error = 'Enter your username and password.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(sessionProvider.notifier).login(username, password);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = _message(e));
    } on Object {
      if (!mounted) return;
      setState(() => _error = 'Could not sign in. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  static String _message(ApiException e) {
    if (e.isUnreachable) {
      return 'Lost the connection to the server. Make sure it is still '
          'running.';
    }
    return switch (e.error.code) {
      ApiErrorCodes.invalidCredentials =>
        'That username or password is not right.',
      ApiErrorCodes.rateLimited =>
        'Too many attempts. Wait a moment, then try again.',
      _ => e.error.message,
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = context.rsTokens;
    final name = ref.watch(serverInfoProvider)?.name;

    return RsWizardFrame(
      steps: const [],
      currentStep: 0,
      title: 'Sign in',
      subtitle: name == null
          ? 'Use the account created during setup.'
          : 'Sign in to $name.',
      icon: Icons.lock_outline_rounded,
      primaryAction: RsButton(
        label: _busy ? 'Signing in…' : 'Sign in',
        icon: Icons.login_rounded,
        variant: RsButtonVariant.primary,
        onPressed: _busy ? null : _submit,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error case final error?) ...[
            Callout(
              tone: Tone.danger,
              icon: Icons.error_outline_rounded,
              title: 'Could not sign in',
              message: error,
            ),
            SizedBox(height: t.spacing.lg),
          ],
          RsTextField(
            key: const Key('login-username'),
            controller: _username,
            focusNode: _usernameFocus,
            label: 'Username',
            hint: 'admin',
            icon: Icons.person_outline_rounded,
            autofocus: true,
            enabled: !_busy,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.username],
            onSubmitted: (_) => _passwordFocus.requestFocus(),
          ),
          SizedBox(height: t.spacing.lg),
          RsTextField(
            key: const Key('login-password'),
            controller: _password,
            focusNode: _passwordFocus,
            label: 'Password',
            icon: Icons.key_rounded,
            obscure: true,
            enabled: !_busy,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
    );
  }
}
