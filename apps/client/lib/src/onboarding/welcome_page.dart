import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rs_theme/rs_theme.dart';
import 'package:rs_ui/rs_ui.dart';

import '../connection/connection_provider.dart';
import '../routing/app_routes.dart';
import 'onboarding_widgets.dart';

/// First screen on an unconfigured server: what Retro Steam is, and one
/// way forward.
class WelcomePage extends ConsumerWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(serverInfoProvider)?.name;
    return RsWizardFrame(
      steps: const [],
      currentStep: 0,
      title: 'Welcome to Retro Steam',
      subtitle: name == null
          ? 'A Big Picture library for the games you already own.'
          : 'Connected to $name. A Big Picture library for the games '
                'you already own.',
      icon: Icons.sports_esports_rounded,
      primaryAction: RsButton(
        label: 'Get started',
        icon: Icons.arrow_forward_rounded,
        variant: RsButtonVariant.primary,
        autofocus: true,
        onPressed: () => context.go(AppRoutes.setup),
      ),
      child: const _WelcomePoints(),
    );
  }
}

class _WelcomePoints extends StatelessWidget {
  const _WelcomePoints();

  static const _points = [
    (
      Icons.person_outline_rounded,
      'Create the admin account that manages this server.',
    ),
    (
      Icons.folder_open_outlined,
      'Pick a data folder, then the folders that hold your ROMs.',
    ),
    (
      Icons.grid_view_rounded,
      'The home screen fills in while the library scans.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final motion = context.rsTokens.motion;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (i, point) in _points.indexed)
          Entrance(
            delay: motion.fast * i,
            child: StatusLine(icon: point.$1, text: point.$2),
          ),
      ],
    );
  }
}
