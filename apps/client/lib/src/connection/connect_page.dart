import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rs_theme/rs_theme.dart';
import 'package:rs_ui/rs_ui.dart';

import 'connection_provider.dart';
import 'server_address.dart';

/// "Server not found": Retry, or connect to a typed address.
class ConnectPage extends ConsumerStatefulWidget {
  const ConnectPage({super.key});

  @override
  ConsumerState<ConnectPage> createState() => _ConnectPageState();
}

class _ConnectPageState extends ConsumerState<ConnectPage> {
  late final TextEditingController _address;
  String? _addressError;

  @override
  void initState() {
    super.initState();
    final uri = ref.read(connectionProvider).baseUri;
    _address = TextEditingController(
      text: uri == defaultLocalServerUri ? '' : displayAddress(uri),
    );
  }

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  void _connect() {
    final uri = parseServerAddress(_address.text);
    if (uri == null) {
      setState(() => _addressError = 'Enter an address like 192.168.1.10');
      return;
    }
    setState(() => _addressError = null);
    ref.read(connectionProvider.notifier).connectTo(uri);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.rsTokens;
    final text = Theme.of(context).textTheme;
    final connection = ref.watch(connectionProvider);
    final searching = connection.status == ConnectionStatus.searching;

    return RsScaffold(
      hints: const RsButtonHints(
        hints: [RsButtonHint(button: RsControllerButton.a, label: 'Select')],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(context.rsPageGutter),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: t.sizes.dialogMaxWidth),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Server not found',
                  style: text.headlineMedium?.copyWith(color: t.textPrimary),
                ),
                SizedBox(height: t.spacing.sm),
                Text(
                  connection.error ??
                      'Start the Retro Steam server on this computer, or '
                          'enter the address of the computer it runs on.',
                  style: text.bodyLarge?.copyWith(color: t.textSecondary),
                ),
                SizedBox(height: t.spacing.xl),
                if (searching)
                  RsSpinner(
                    label:
                        'Connecting to ${displayAddress(connection.baseUri)}…',
                  )
                else
                  Align(
                    alignment: Alignment.centerLeft,
                    child: RsButton(
                      label: 'Retry',
                      icon: Icons.refresh_rounded,
                      variant: RsButtonVariant.primary,
                      autofocus: true,
                      onPressed: () =>
                          ref.read(connectionProvider.notifier).retry(),
                    ),
                  ),
                SizedBox(height: t.spacing.xl),
                RsTextField(
                  controller: _address,
                  label: 'Server address',
                  hint: '192.168.1.10 or myserver.local:47320',
                  errorText: _addressError,
                  enabled: !searching,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.go,
                  onSubmitted: (_) => _connect(),
                ),
                SizedBox(height: t.spacing.md),
                Align(
                  alignment: Alignment.centerLeft,
                  child: RsButton(
                    label: 'Connect',
                    onPressed: searching ? null : _connect,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
