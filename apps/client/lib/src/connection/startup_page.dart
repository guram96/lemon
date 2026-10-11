import 'package:flutter/widgets.dart';
import 'package:rs_ui/rs_ui.dart';

/// Shown while the server is probed at startup.
class StartupPage extends StatelessWidget {
  const StartupPage({super.key});

  @override
  Widget build(BuildContext context) => const RsScaffold(
    body: Center(child: RsSpinner(label: 'Looking for your server…')),
  );
}
