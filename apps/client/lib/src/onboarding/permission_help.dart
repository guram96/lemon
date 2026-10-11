import 'package:flutter/material.dart';
import 'package:rs_theme/rs_theme.dart';
import 'package:rs_ui/rs_ui.dart';

import 'onboarding_widgets.dart';

/// Steps to grant the server access to a folder, for the server's OS
/// (`ServerInfo.platform`: `macos`, `windows` or `linux`).
List<String> permissionSteps(String? platform, {required String path}) =>
    switch (platform) {
      'macos' => const [
        'Open System Settings › Privacy & Security › Full Disk Access.',
        'Turn on the app that runs the server: rs_server, or Terminal (or '
            'iTerm) if you started it from a terminal. Use + to add it if it '
            'is not listed.',
        'Folders on external drives may also need Files and Folders › '
            'Removable Volumes.',
        'Restart the server if macOS asks you to, then choose Check again.',
      ],
      'windows' => const [
        'In File Explorer, right-click the folder and choose Properties.',
        'Open the Security tab and choose Edit.',
        'Select the account that runs the server and allow Read (and Modify '
            'for the data folder).',
        'Choose OK, then Check again.',
      ],
      'linux' => [
        'Check who owns the folder: ls -ld "$path"',
        'Give the user that runs the server access, for example '
            'sudo chown -R \$USER "$path", or add it to the folder\'s group '
            '(sudo usermod -aG <group> \$USER, then log in again).',
        'Make sure the folder can be read: chmod u+rwx "$path"',
        'For external drives, check the mount options (uid / gid in '
            '/etc/fstab), then choose Check again.',
      ],
      _ => const [
        'Give the account that runs the server permission to read (and, for '
            'the data folder, write) this folder.',
        'Then choose Check again.',
      ],
    };

/// Inline "the OS denied access" panel with OS-specific steps and
/// [Check again].
class PermissionHelp extends StatelessWidget {
  const PermissionHelp({
    super.key,
    required this.platform,
    required this.path,
    required this.onCheckAgain,
  });

  final String? platform;
  final String path;
  final VoidCallback onCheckAgain;

  @override
  Widget build(BuildContext context) {
    final t = context.rsTokens;
    final text = Theme.of(context).textTheme;
    final steps = permissionSteps(platform, path: path);
    return Callout(
      tone: Tone.warning,
      icon: Icons.lock_outline_rounded,
      title: 'The server needs permission to use this folder',
      message:
          '${_osName(platform)} blocked the Retro Steam server from '
          'accessing it. To allow it:',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, step) in steps.indexed)
            Padding(
              padding: EdgeInsets.only(top: t.spacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${i + 1}.  ',
                    style: text.bodyMedium?.copyWith(color: t.textMuted),
                  ),
                  Expanded(
                    child: Text(
                      step,
                      style: text.bodyMedium?.copyWith(color: t.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(height: t.spacing.md),
          Align(
            alignment: Alignment.centerLeft,
            child: RsButton(
              label: 'Check again',
              icon: Icons.refresh_rounded,
              onPressed: onCheckAgain,
            ),
          ),
        ],
      ),
    );
  }

  static String _osName(String? platform) => switch (platform) {
    'macos' => 'macOS',
    'windows' => 'Windows',
    'linux' => 'Linux',
    _ => 'The operating system',
  };
}
