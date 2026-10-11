import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rs_core/rs_core.dart';
import 'package:rs_theme/rs_theme.dart';
import 'package:rs_ui/rs_ui.dart';

import '../connection/connection_provider.dart';
import '../routing/app_routes.dart';
import 'folder_browser_dialog.dart';
import 'onboarding_widgets.dart';
import 'permission_help.dart';
import 'setup_wizard_state.dart';

/// First-run wizard: admin account, data folder, library folders, review.
///
/// Finishing calls `POST /setup` and adopts the session. The router then
/// moves to the done page; this page does not navigate on success.
class SetupWizardPage extends ConsumerStatefulWidget {
  const SetupWizardPage({super.key});

  @override
  ConsumerState<SetupWizardPage> createState() => _SetupWizardPageState();
}

class _SetupWizardPageState extends ConsumerState<SetupWizardPage> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _usernameFocus = FocusNode(debugLabel: 'Setup.username');
  final _passwordFocus = FocusNode(debugLabel: 'Setup.password');
  final _confirmFocus = FocusNode(debugLabel: 'Setup.confirm');
  final _browseData = FocusNode(debugLabel: 'Setup.browseData');
  final _addRoot = FocusNode(debugLabel: 'Setup.addRoot');
  final _finish = FocusNode(debugLabel: 'Setup.finish');

  @override
  void initState() {
    super.initState();
    final state = ref.read(setupWizardProvider);
    _username.text = state.username;
    _password.text = state.password;
    _confirm.text = state.confirm;
    // Suggest <home>/RetroSteam so Continue can be the next keypress.
    unawaited(ref.read(setupWizardProvider.notifier).prepare());
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _confirm.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    _browseData.dispose();
    _addRoot.dispose();
    _finish.dispose();
    super.dispose();
  }

  SetupWizardNotifier get _notifier => ref.read(setupWizardProvider.notifier);

  void _focusStep(SetupStep step) {
    final node = switch (step) {
      SetupStep.account => _usernameFocus,
      SetupStep.data => _browseData,
      SetupStep.library => _addRoot,
      SetupStep.review => _finish,
    };
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) node.requestFocus();
    });
  }

  void _continue(SetupWizardState state) {
    if (state.step == SetupStep.review) {
      unawaited(_notifier.finish());
      return;
    }
    _notifier.next();
  }

  void _back(SetupWizardState state) {
    if (state.step == SetupStep.account) {
      context.go(AppRoutes.welcome);
      return;
    }
    _notifier.back();
  }

  Future<void> _pickData(SetupWizardState state) async {
    final current = state.data?.path;
    final path = await showFolderBrowser(
      context: context,
      api: ref.read(apiClientProvider),
      title: 'Data folder',
      initialPath: current ?? state.homePath,
      selectLabel: 'Use this folder',
    );
    if (!mounted || path == null) return;
    await _notifier.chooseDataDir(path);
  }

  Future<void> _pickRoot(SetupWizardState state) async {
    final path = await showFolderBrowser(
      context: context,
      api: ref.read(apiClientProvider),
      title: 'Game library',
      initialPath: state.homePath,
      selectLabel: 'Add this folder',
    );
    if (!mounted || path == null) return;
    await _notifier.addRoot(path);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(setupWizardProvider);
    ref.listen(setupWizardProvider.select((s) => s.step), (previous, next) {
      if (previous != null && previous != next) _focusStep(next);
    });

    final finishing = state.finishing;
    final copy = _copy(state.step);
    final canContinue = switch (state.step) {
      SetupStep.account => !finishing,
      SetupStep.data => state.dataValid,
      SetupStep.library => state.libraryValid,
      SetupStep.review => state.canLeave(SetupStep.review),
    };

    return RsWizardFrame(
      steps: [for (final step in SetupStep.values) step.label],
      currentStep: state.step.index,
      title: finishing ? 'Setting up…' : copy.title,
      subtitle: finishing
          ? 'Creating the admin account, the data folder, and the '
                'library. This stays here until the server is ready.'
          : copy.subtitle,
      icon: finishing ? Icons.auto_awesome_rounded : copy.icon,
      secondaryAction: finishing
          ? null
          : RsButton(label: 'Back', onPressed: () => _back(state)),
      primaryAction: finishing
          ? null
          : RsButton(
              label: state.step == SetupStep.review
                  ? 'Finish setup'
                  : 'Continue',
              icon: state.step == SetupStep.review
                  ? Icons.check_rounded
                  : Icons.arrow_forward_rounded,
              variant: RsButtonVariant.primary,
              focusNode: state.step == SetupStep.review ? _finish : null,
              onPressed: canContinue ? () => _continue(state) : null,
            ),
      child: finishing
          ? _Finishing(state: state)
          : _StepBody(
              state: state,
              username: _username,
              password: _password,
              confirm: _confirm,
              usernameFocus: _usernameFocus,
              passwordFocus: _passwordFocus,
              confirmFocus: _confirmFocus,
              browseData: _browseData,
              addRoot: _addRoot,
              platform: ref.watch(serverInfoProvider)?.platform,
              onUsername: _notifier.setUsername,
              onPassword: _notifier.setPassword,
              onConfirm: _notifier.setConfirm,
              onContinue: () => _continue(state),
              onPickData: () => _pickData(state),
              onRecheckData: _notifier.recheckData,
              onPickRoot: () => _pickRoot(state),
              onRecheckRoot: _notifier.recheckRoot,
              onRemoveRoot: _notifier.removeRoot,
              onEdit: _notifier.goTo,
            ),
    );
  }
}

typedef _Copy = ({String title, String subtitle, IconData icon});

_Copy _copy(SetupStep step) => switch (step) {
  SetupStep.account => (
    title: 'Create the admin account',
    subtitle:
        'One admin manages the server. You can sign in with this '
        'account from any device that joins later.',
    icon: Icons.admin_panel_settings_outlined,
  ),
  SetupStep.data => (
    title: 'Choose a data folder',
    subtitle:
        'The database, artwork, and caches live here — not next to '
        'your ROMs. A folder on a fast drive works best.',
    icon: Icons.storage_rounded,
  ),
  SetupStep.library => (
    title: 'Add your games',
    subtitle:
        'Point at folders laid out like EmulationStation: a folder '
        'per system (snes, psx, …) inside each one.',
    icon: Icons.folder_copy_outlined,
  ),
  SetupStep.review => (
    title: 'Review and finish',
    subtitle: 'Setup creates the library and signs you in.',
    icon: Icons.checklist_rounded,
  ),
};

class _StepBody extends StatelessWidget {
  const _StepBody({
    required this.state,
    required this.username,
    required this.password,
    required this.confirm,
    required this.usernameFocus,
    required this.passwordFocus,
    required this.confirmFocus,
    required this.browseData,
    required this.addRoot,
    required this.platform,
    required this.onUsername,
    required this.onPassword,
    required this.onConfirm,
    required this.onContinue,
    required this.onPickData,
    required this.onRecheckData,
    required this.onPickRoot,
    required this.onRecheckRoot,
    required this.onRemoveRoot,
    required this.onEdit,
  });

  final SetupWizardState state;
  final TextEditingController username;
  final TextEditingController password;
  final TextEditingController confirm;
  final FocusNode usernameFocus;
  final FocusNode passwordFocus;
  final FocusNode confirmFocus;
  final FocusNode browseData;
  final FocusNode addRoot;
  final String? platform;
  final ValueChanged<String> onUsername;
  final ValueChanged<String> onPassword;
  final ValueChanged<String> onConfirm;
  final VoidCallback onContinue;
  final VoidCallback onPickData;
  final VoidCallback onRecheckData;
  final VoidCallback onPickRoot;
  final ValueChanged<String> onRecheckRoot;
  final ValueChanged<String> onRemoveRoot;
  final ValueChanged<SetupStep> onEdit;

  @override
  Widget build(BuildContext context) {
    final t = context.rsTokens;
    final error = state.error?.step == state.step ? state.error : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (error != null) ...[
          Callout(
            tone: Tone.danger,
            icon: Icons.error_outline_rounded,
            title: 'Setup stopped',
            message: error.message,
          ),
          SizedBox(height: t.spacing.lg),
        ],
        switch (state.step) {
          SetupStep.account => _AccountStep(
            state: state,
            username: username,
            password: password,
            confirm: confirm,
            usernameFocus: usernameFocus,
            passwordFocus: passwordFocus,
            confirmFocus: confirmFocus,
            onUsername: onUsername,
            onPassword: onPassword,
            onConfirm: onConfirm,
            onContinue: onContinue,
          ),
          SetupStep.data => _DataStep(
            state: state,
            platform: platform,
            browseFocus: browseData,
            onBrowse: onPickData,
            onRecheck: onRecheckData,
          ),
          SetupStep.library => _LibraryStep(
            state: state,
            platform: platform,
            addFocus: addRoot,
            onAdd: onPickRoot,
            onRecheck: onRecheckRoot,
            onRemove: onRemoveRoot,
          ),
          SetupStep.review => _ReviewStep(state: state, onEdit: onEdit),
        },
      ],
    );
  }
}

class _AccountStep extends StatelessWidget {
  const _AccountStep({
    required this.state,
    required this.username,
    required this.password,
    required this.confirm,
    required this.usernameFocus,
    required this.passwordFocus,
    required this.confirmFocus,
    required this.onUsername,
    required this.onPassword,
    required this.onConfirm,
    required this.onContinue,
  });

  final SetupWizardState state;
  final TextEditingController username;
  final TextEditingController password;
  final TextEditingController confirm;
  final FocusNode usernameFocus;
  final FocusNode passwordFocus;
  final FocusNode confirmFocus;
  final ValueChanged<String> onUsername;
  final ValueChanged<String> onPassword;
  final ValueChanged<String> onConfirm;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final t = context.rsTokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RsTextField(
          key: const Key('setup-username'),
          controller: username,
          focusNode: usernameFocus,
          label: 'Username',
          hint: 'admin',
          icon: Icons.person_outline_rounded,
          autofocus: true,
          errorText: state.usernameError,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.newUsername],
          onChanged: onUsername,
          onSubmitted: (_) => passwordFocus.requestFocus(),
        ),
        SizedBox(height: t.spacing.lg),
        RsTextField(
          key: const Key('setup-password'),
          controller: password,
          focusNode: passwordFocus,
          label: 'Password',
          icon: Icons.key_rounded,
          obscure: true,
          errorText: state.passwordError,
          helperText: 'At least ${SetupRequest.minPasswordLength} characters',
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.newPassword],
          onChanged: onPassword,
          onSubmitted: (_) => confirmFocus.requestFocus(),
        ),
        SizedBox(height: t.spacing.lg),
        RsTextField(
          key: const Key('setup-confirm'),
          controller: confirm,
          focusNode: confirmFocus,
          label: 'Confirm password',
          icon: Icons.key_rounded,
          obscure: true,
          errorText: state.confirmError,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.newPassword],
          onChanged: onConfirm,
          onSubmitted: (_) => onContinue(),
        ),
      ],
    );
  }
}

class _DataStep extends StatelessWidget {
  const _DataStep({
    required this.state,
    required this.platform,
    required this.browseFocus,
    required this.onBrowse,
    required this.onRecheck,
  });

  final SetupWizardState state;
  final String? platform;
  final FocusNode browseFocus;
  final VoidCallback onBrowse;
  final VoidCallback onRecheck;

  @override
  Widget build(BuildContext context) {
    final t = context.rsTokens;
    final data = state.data;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (data == null)
          const StatusLine(
            icon: Icons.travel_explore_rounded,
            text: 'Choose a folder on this computer.',
          )
        else
          _CheckedFolder(
            checked: data,
            platform: platform,
            kindLabel: 'data folder',
            onRecheck: onRecheck,
          ),
        SizedBox(height: t.spacing.lg),
        Align(
          alignment: Alignment.centerLeft,
          child: RsButton(
            label: data == null ? 'Browse' : 'Change folder',
            icon: Icons.folder_open_rounded,
            focusNode: browseFocus,
            autofocus: true,
            onPressed: onBrowse,
          ),
        ),
      ],
    );
  }
}

class _LibraryStep extends StatelessWidget {
  const _LibraryStep({
    required this.state,
    required this.platform,
    required this.addFocus,
    required this.onAdd,
    required this.onRecheck,
    required this.onRemove,
  });

  final SetupWizardState state;
  final String? platform;
  final FocusNode addFocus;
  final VoidCallback onAdd;
  final ValueChanged<String> onRecheck;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final t = context.rsTokens;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: RsButton(
            label: 'Add folder',
            icon: Icons.create_new_folder_outlined,
            focusNode: addFocus,
            autofocus: true,
            onPressed: onAdd,
          ),
        ),
        SizedBox(height: t.spacing.lg),
        if (state.roots.isEmpty)
          Text(
            'No library folders yet. Add at least one.',
            style: text.bodyLarge?.copyWith(color: t.textMuted),
          ),
        if (state.rootClashesWithData)
          const Callout(
            tone: Tone.warning,
            icon: Icons.warning_amber_rounded,
            title: 'A library folder is the data folder',
            message:
                'Keep ROMs and the data folder apart, so a library '
                'scan never walks the database.',
          ),
        for (final root in state.roots) ...[
          SizedBox(height: t.spacing.md),
          _CheckedFolder(
            checked: root,
            platform: platform,
            kindLabel: 'library folder',
            onRecheck: () => onRecheck(root.path),
          ),
          SizedBox(height: t.spacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: RsButton(
              key: ValueKey('remove:${root.path}'),
              label: 'Remove',
              icon: Icons.close_rounded,
              onPressed: () => onRemove(root.path),
            ),
          ),
        ],
        if (state.detectedSystems.isNotEmpty) ...[
          SizedBox(height: t.spacing.lg),
          SystemChips(counts: state.detectedSystems),
        ],
      ],
    );
  }
}

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({required this.state, required this.onEdit});

  final SetupWizardState state;
  final ValueChanged<SetupStep> onEdit;

  @override
  Widget build(BuildContext context) {
    final t = context.rsTokens;
    final data = state.data;
    final files = state.detectedSystems.values.fold<int>(0, (n, c) => n + c);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RsListRow(
          icon: Icons.person_outline_rounded,
          title: 'Admin account',
          subtitle: state.username.trim(),
          chevron: true,
          onPressed: () => onEdit(SetupStep.account),
        ),
        SizedBox(height: t.spacing.sm),
        RsListRow(
          icon: Icons.storage_rounded,
          title: 'Data folder',
          subtitle: data?.path ?? 'Not chosen',
          value: _dataValue(data),
          chevron: true,
          onPressed: () => onEdit(SetupStep.data),
        ),
        SizedBox(height: t.spacing.sm),
        RsListRow(
          icon: Icons.folder_copy_outlined,
          title: 'Game library',
          subtitle: state.roots.isEmpty
              ? 'No folders'
              : state.roots.map((r) => r.path).join('\n'),
          value: state.detectedSystems.isEmpty
              ? plural(state.roots.length, 'folder')
              : '${plural(files, 'file')} · '
                    '${plural(state.detectedSystems.length, 'system')}',
          chevron: true,
          onPressed: () => onEdit(SetupStep.library),
        ),
        if (state.detectedSystems.isNotEmpty) ...[
          SizedBox(height: t.spacing.lg),
          SystemChips(counts: state.detectedSystems),
        ],
      ],
    );
  }

  static String? _dataValue(CheckedPath? data) {
    final result = data?.result;
    if (result == null) return null;
    if (result.existingMarkerId != null) return 'Will be adopted';
    final free = result.freeBytes;
    if (free == null) return null;
    return '${formatBytes(free)} free';
  }
}

class _Finishing extends StatelessWidget {
  const _Finishing({required this.state});

  final SetupWizardState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StatusLine(
          icon: Icons.person_outline_rounded,
          text: 'Creating the admin account ${state.username.trim()}',
        ),
        if (state.data case final data?)
          StatusLine(
            icon: Icons.storage_rounded,
            text: 'Preparing ${data.path}',
          ),
        StatusLine(
          icon: Icons.folder_copy_outlined,
          text: 'Adding ${plural(state.roots.length, 'library folder')}',
        ),
      ],
    );
  }
}

/// Verdict for one server-side folder: access, space, systems, warnings.
class _CheckedFolder extends StatelessWidget {
  const _CheckedFolder({
    required this.checked,
    required this.platform,
    required this.kindLabel,
    required this.onRecheck,
  });

  final CheckedPath checked;
  final String? platform;
  final String kindLabel;
  final VoidCallback onRecheck;

  @override
  Widget build(BuildContext context) {
    final t = context.rsTokens;
    final text = Theme.of(context).textTheme;
    final result = checked.result;
    return Container(
      padding: EdgeInsets.all(t.spacing.md),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(t.radii.md),
        border: Border.all(color: t.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            checked.path,
            style: text.titleSmall?.copyWith(color: t.textPrimary),
          ),
          SizedBox(height: t.spacing.sm),
          if (checked.checking)
            const StatusLine(
              icon: Icons.hourglass_top_rounded,
              text: 'Checking this folder…',
            )
          else if (checked.error case final error?)
            Callout(
              tone: Tone.danger,
              icon: Icons.error_outline_rounded,
              title: 'Could not check this folder',
              message: error,
            )
          else if (result != null) ...[
            if (result.permissionDenied)
              PermissionHelp(
                platform: platform,
                path: result.path,
                onCheckAgain: onRecheck,
              )
            else ...[
              for (final line in _lines(result, kindLabel)) line,
              if (result.kind == PathKind.libraryRoot &&
                  result.detectedSystems.isNotEmpty) ...[
                SizedBox(height: t.spacing.sm),
                SystemChips(
                  counts: {
                    for (final s in result.detectedSystems)
                      s.systemId: s.fileCount,
                  },
                ),
              ],
            ],
          ],
        ],
      ),
    );
  }

  static List<Widget> _lines(PathCheckResult result, String kindLabel) {
    final lines = <Widget>[];
    if (result.ok) {
      lines.add(
        StatusLine(
          icon: Icons.check_circle_outline_rounded,
          text: result.kind == PathKind.dataDir
              ? (result.exists ? 'Ready to use' : 'This folder will be created')
              : 'Ready to scan',
          tone: Tone.ok,
        ),
      );
    } else {
      lines.add(
        StatusLine(
          icon: Icons.error_outline_rounded,
          text: _blockedReason(result, kindLabel),
          tone: Tone.danger,
        ),
      );
    }
    if (result.existingMarkerId != null) {
      lines.add(
        StatusLine(
          icon: Icons.inventory_2_outlined,
          text: result.kind == PathKind.dataDir
              ? 'This folder already holds a Retro Steam library. '
                    'It will be adopted, and the admin account has to '
                    'match the one already there.'
              : 'This folder is already a Retro Steam library. It will '
                    'be added as it is.',
          tone: Tone.info,
        ),
      );
    }
    final free = result.freeBytes;
    if (free != null && result.kind == PathKind.dataDir) {
      lines.add(
        StatusLine(
          icon: Icons.disc_full_outlined,
          text: '${formatBytes(free)} free',
        ),
      );
    }
    if (result.kind == PathKind.libraryRoot && result.ok && !result.writable) {
      lines.add(
        const StatusLine(
          icon: Icons.lock_outline_rounded,
          text:
              'Read-only. You can browse and play; the server cannot '
              'add or delete games here until the folder is writable.',
          tone: Tone.warning,
        ),
      );
    }
    for (final warning in result.warnings) {
      lines.add(
        StatusLine(
          icon: Icons.warning_amber_rounded,
          text: warning,
          tone: Tone.warning,
        ),
      );
    }
    if (result.kind == PathKind.libraryRoot && result.ok) {
      final files = result.detectedSystems.fold<int>(
        0,
        (n, s) => n + s.fileCount,
      );
      lines.add(
        StatusLine(
          icon: Icons.videogame_asset_outlined,
          text: files == 0
              ? 'No game files yet. Systems appear when their folders do.'
              : '${plural(files, 'file')} across '
                    '${plural(result.detectedSystems.length, 'system')}',
          tone: files == 0 ? Tone.muted : Tone.info,
        ),
      );
    }
    return lines;
  }

  static String _blockedReason(PathCheckResult result, String kindLabel) {
    if (!result.exists && result.kind == PathKind.libraryRoot) {
      return 'This folder does not exist.';
    }
    if (!result.readable && result.kind == PathKind.libraryRoot) {
      return 'The server cannot read this folder.';
    }
    if (!result.writable && result.kind == PathKind.dataDir) {
      return 'The server cannot create or write this $kindLabel. '
          'Pick another one, or grant write access.';
    }
    return 'This $kindLabel cannot be used.';
  }
}
