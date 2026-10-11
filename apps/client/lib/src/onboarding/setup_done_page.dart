import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rs_core/rs_core.dart';
import 'package:rs_theme/rs_theme.dart';
import 'package:rs_ui/rs_ui.dart';

import '../events/scan_status_provider.dart';
import '../routing/app_routes.dart';
import 'onboarding_widgets.dart';
import 'setup_wizard_state.dart';

/// Shown after setup logs the admin in. The scan keeps running underneath;
/// this page reports what is already known and sends the user home.
class SetupDonePage extends ConsumerWidget {
  const SetupDonePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.rsTokens;
    final scan = ref.watch(scanStatusProvider);
    final detected = ref.watch(
      setupWizardProvider.select((s) => s.detectedSystems),
    );
    final files = detected.values.fold<int>(0, (n, c) => n + c);

    return RsWizardFrame(
      steps: const [],
      currentStep: 0,
      title: "You're all set",
      subtitle: _subtitle(scan, files),
      icon: Icons.celebration_outlined,
      primaryAction: RsButton(
        label: 'Go to library',
        icon: Icons.arrow_forward_rounded,
        variant: RsButtonVariant.primary,
        autofocus: true,
        onPressed: () => context.go(AppRoutes.home),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (scan.isRunning) ...[
            RsProgressBar(
              value: scan.total > 0
                  ? (scan.processed / scan.total).clamp(0.0, 1.0)
                  : null,
              label: _scanLabel(scan),
              trailing: scan.total > 0
                  ? '${scan.processed} / ${scan.total}'
                  : null,
            ),
            SizedBox(height: t.spacing.lg),
          ],
          if (scan.phase == ScanPhase.done)
            StatusLine(
              icon: Icons.check_circle_outline_rounded,
              text: '${plural(scan.added, 'game')} added',
              tone: Tone.ok,
            ),
          if (scan.phase == ScanPhase.failed)
            Callout(
              tone: Tone.danger,
              icon: Icons.error_outline_rounded,
              title: 'The scan ran into a problem',
              message:
                  scan.error ??
                  'It will try again. You can keep browsing what is '
                      'already there.',
            ),
          if (detected.isNotEmpty) ...[
            SizedBox(height: t.spacing.sm),
            StatusLine(
              icon: Icons.folder_open_rounded,
              text: files == 0
                  ? '${plural(detected.length, 'system')} ready for ROMs'
                  : '${plural(files, 'file')} across '
                        '${plural(detected.length, 'system')}',
              tone: Tone.info,
            ),
            SizedBox(height: t.spacing.md),
            SystemChips(counts: detected),
          ],
        ],
      ),
    );
  }

  static String _subtitle(ScanStatus scan, int files) {
    if (scan.isRunning) {
      return 'Retro Steam is scanning your library. Games show up on '
          'the home screen as they are found.';
    }
    if (scan.phase == ScanPhase.done) {
      return 'The first scan is finished. Your library is ready.';
    }
    if (files > 0) {
      return 'Setup found games in your folders. The home screen fills '
          'in as the scan reads them.';
    }
    return 'The server is ready. Add ROMs to your library folders and '
        'they will appear on the home screen.';
  }

  static String _scanLabel(ScanStatus scan) {
    final system = switch (scan.currentSystemId) {
      final id? => systemName(id),
      null => null,
    };
    if (scan.phase == ScanPhase.discovering || scan.total == 0) {
      return system == null ? 'Looking for games' : 'Looking in $system';
    }
    return system == null ? 'Scanning your library' : 'Scanning $system';
  }
}
