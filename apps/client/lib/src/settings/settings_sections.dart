import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rs_core/rs_core.dart';
import 'package:rs_theme/rs_theme.dart';
import 'package:rs_ui/rs_ui.dart';

import '../app/component_set_provider.dart';
import '../app/theme_settings_provider.dart';
import '../connection/connection_provider.dart';
import '../install/download_queue.dart';
import '../install/install_models.dart';
import '../install/install_store.dart';
import '../launch/emulator_detector.dart';
import '../launch/emulator_manifest.dart';
import '../launch/launch_models.dart';
import '../launch/launch_store.dart';
import '../onboarding/folder_browser_dialog.dart';
import '../platform/client_capabilities.dart';
import '../session/session_provider.dart';
import 'client_settings.dart';
import 'settings_focus.dart';

/// Look, display mode and accent. Changes apply immediately.
class InterfaceSettings extends ConsumerWidget {
  const InterfaceSettings({
    super.key,
    required this.link,
    required this.onHorizontal,
  });

  final SettingsColumnLink link;
  final void Function(TraversalDirection direction) onHorizontal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(themeSettingsProvider);
    final look = ref.watch(lookProvider);
    return SettingsFocusColumn(
      link: link,
      length: 3,
      onHorizontal: onHorizontal,
      itemBuilder: (context, index, node) {
        if (index == 0) {
          return RsListRow(
            focusNode: node,
            title: 'Look',
            value: look.displayName,
            chevron: true,
            onPressed: () => _pickLook(context, ref),
          );
        }
        if (index == 1) {
          return RsListRow(
            focusNode: node,
            title: 'Display',
            value: themeModeLabel(settings.mode),
            chevron: true,
            onPressed: () => _pickMode(context, ref),
          );
        }
        return RsListRow(
          focusNode: node,
          title: 'Accent',
          value: accentLabel(settings.accent),
          leading: _AccentSwatch(color: settings.accent),
          chevron: true,
          onPressed: () => _pickAccent(context, ref),
        );
      },
    );
  }

  Future<void> _pickLook(BuildContext context, WidgetRef ref) async {
    final current = ref.read(themeSettingsProvider);
    final active = ref.read(lookProvider).id;
    final looks = ref.read(availableLooksProvider);
    await showRsDialog<void>(
      context: context,
      builder: (dialogContext) => RsDialog(
        title: 'Look',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final look in looks)
              RsListRow(
                title: look.displayName,
                value: active == look.id ? 'Selected' : null,
                autofocus: active == look.id,
                onPressed: () async {
                  await ref
                      .read(themeSettingsProvider.notifier)
                      .update(current.copyWith(look: look.id));
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickMode(BuildContext context, WidgetRef ref) async {
    final current = ref.read(themeSettingsProvider);
    await showRsDialog<void>(
      context: context,
      builder: (dialogContext) => RsDialog(
        title: 'Display',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final mode in const [
              ThemeMode.dark,
              ThemeMode.light,
              ThemeMode.system,
            ])
              RsListRow(
                title: themeModeLabel(mode),
                value: current.mode == mode ? 'Selected' : null,
                autofocus: current.mode == mode,
                onPressed: () async {
                  await ref
                      .read(themeSettingsProvider.notifier)
                      .update(current.copyWith(mode: mode));
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAccent(BuildContext context, WidgetRef ref) async {
    final current = ref.read(themeSettingsProvider);
    await showRsDialog<void>(
      context: context,
      builder: (dialogContext) => RsDialog(
        title: 'Accent',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final preset in accentPresets)
              RsListRow(
                title: preset.name,
                leading: _AccentSwatch(color: preset.color),
                value: current.accent == preset.color ? 'Selected' : null,
                autofocus: current.accent == preset.color,
                onPressed: () async {
                  await ref
                      .read(themeSettingsProvider.notifier)
                      .update(current.copyWith(accent: preset.color));
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// One persisted switch. Nothing is played.
class AudioSettings extends ConsumerWidget {
  const AudioSettings({
    super.key,
    required this.link,
    required this.onHorizontal,
  });

  final SettingsColumnLink link;
  final void Function(TraversalDirection direction) onHorizontal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(uiSoundsProvider);
    return SettingsFocusColumn(
      link: link,
      length: 1,
      onHorizontal: onHorizontal,
      itemBuilder: (context, index, node) => RsListRow(
        focusNode: node,
        title: 'UI sounds',
        switchValue: enabled,
        onPressed: () {
          unawaited(ref.read(uiSoundsProvider.notifier).setEnabled(!enabled));
        },
      ),
    );
  }
}

/// System-wide emulator choices. Game overrides stay on the game page.
class EmulatorSettings extends ConsumerWidget {
  const EmulatorSettings({
    super.key,
    required this.link,
    required this.onHorizontal,
  });

  final SettingsColumnLink link;
  final void Function(TraversalDirection direction) onHorizontal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.rsTokens;
    final text = Theme.of(context).textTheme;
    final canLaunch = ref.watch(
      clientCapabilitiesProvider.select((caps) => caps.canLaunchGames),
    );
    final detected = ref.watch(detectedEmulatorsProvider);
    final options = ref.watch(launchOptionsProvider);
    if (options.isLoading && !options.hasValue) {
      return const Center(child: RsSpinner());
    }
    final saved = options.value?.systems ?? const <String, LaunchChoice>{};
    final ids = _systemIds(detected, saved);
    final note = canLaunch
        ? 'No emulators found.'
        : 'This device does not start games.';
    if (ids.isEmpty) {
      return Align(
        alignment: Alignment.topLeft,
        child: Text(
          note,
          style: text.bodyLarge?.copyWith(color: t.textSecondary),
        ),
      );
    }
    final rows = SettingsFocusColumn(
      link: link,
      length: ids.length,
      onHorizontal: onHorizontal,
      itemBuilder: (context, index, node) {
        final id = ids[index];
        return RsListRow(
          focusNode: node,
          title: systemLabel(id),
          value: emulatorChoiceLabel(saved[id], detected),
          chevron: true,
          onPressed: () => _editSystem(
            context,
            ref,
            systemId: id,
            detected: detected,
            current: saved[id],
          ),
        );
      },
    );
    if (canLaunch) return rows;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(note, style: text.bodyLarge?.copyWith(color: t.textSecondary)),
        SizedBox(height: t.spacing.md),
        Expanded(child: rows),
      ],
    );
  }

  Future<void> _editSystem(
    BuildContext context,
    WidgetRef ref, {
    required String systemId,
    required List<DetectedEmulator> detected,
    required LaunchChoice? current,
  }) async {
    await showRsDialog<void>(
      context: context,
      builder: (dialogContext) => _SystemEmulatorDialog(
        systemName: systemLabel(systemId),
        options: _optionsFor(detected, systemId),
        current: current,
        onSave: (choice) => ref
            .read(launchOptionsProvider.notifier)
            .setSystem(systemId, choice),
        onClear: () =>
            ref.read(launchOptionsProvider.notifier).clearSystem(systemId),
      ),
    );
  }
}

/// Global install folder and one row per system that overrides it or has an
/// installed game.
class StorageSettings extends ConsumerWidget {
  const StorageSettings({
    super.key,
    required this.link,
    required this.onHorizontal,
  });

  final SettingsColumnLink link;
  final void Function(TraversalDirection direction) onHorizontal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.rsTokens;
    final text = Theme.of(context).textTheme;
    final destinations = ref.watch(destinationsProvider);
    if (destinations.isLoading && !destinations.hasValue) {
      return const Center(child: RsSpinner());
    }
    if (destinations.hasError && !destinations.hasValue) {
      return Align(
        alignment: Alignment.topLeft,
        child: Text(
          "Couldn't load install folders.",
          style: text.bodyLarge?.copyWith(color: t.textSecondary),
        ),
      );
    }
    final destination = destinations.value ?? InstallDestination();
    final records = ref.watch(downloadQueueProvider);
    final systems = _storageSystems(destination, records);
    return SettingsFocusColumn(
      link: link,
      length: 1 + systems.length,
      onHorizontal: onHorizontal,
      itemBuilder: (context, index, node) {
        if (index == 0) {
          final global = destination.globalFolder;
          return RsListRow(
            focusNode: node,
            title: 'Install folder',
            subtitle: 'Every system without its own folder',
            value: global ?? 'Not set',
            chevron: true,
            onPressed: () => _pickGlobal(context, ref, global),
          );
        }
        final id = systems[index - 1];
        final override = destination.foldersBySystem[id];
        return RsListRow(
          focusNode: node,
          title: systemLabel(id),
          subtitle: override == null ? 'Global folder' : 'Custom folder',
          value: destination.folderFor(id) ?? 'Not set',
          chevron: true,
          onPressed: () => _editSystem(context, ref, id),
        );
      },
    );
  }

  Future<void> _pickGlobal(
    BuildContext context,
    WidgetRef ref,
    String? current,
  ) async {
    final path = await showFolderBrowser(
      context: context,
      api: ref.read(apiClientProvider),
      title: 'Install folder',
      initialPath: current,
      selectLabel: 'Use this folder',
    );
    if (!context.mounted || path == null) return;
    await ref.read(destinationsProvider.notifier).setGlobalFolder(path);
  }

  Future<void> _editSystem(
    BuildContext context,
    WidgetRef ref,
    String systemId,
  ) async {
    final destination = ref.read(destinationsProvider).value;
    final name = systemLabel(systemId);
    final current = destination?.folderFor(systemId);
    final hasOverride =
        destination?.foldersBySystem.containsKey(systemId) ?? false;
    final action = await showRsDialog<_FolderAction>(
      context: context,
      builder: (dialogContext) => RsDialog(
        title: name,
        message: current ?? 'No folder selected',
        actions: [
          RsButton(
            label: 'Choose folder',
            onPressed: () =>
                Navigator.of(dialogContext).pop(_FolderAction.choose),
          ),
          if (hasOverride)
            RsButton(
              label: 'Use global folder',
              onPressed: () =>
                  Navigator.of(dialogContext).pop(_FolderAction.clear),
            ),
          RsButton(
            label: 'Cancel',
            autofocus: true,
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
        ],
      ),
    );
    if (!context.mounted || action == null) return;
    switch (action) {
      case _FolderAction.clear:
        await ref
            .read(destinationsProvider.notifier)
            .setSystemFolder(systemId, null);
      case _FolderAction.choose:
        final path = await showFolderBrowser(
          context: context,
          api: ref.read(apiClientProvider),
          title: name,
          initialPath: current,
          selectLabel: 'Use this folder',
        );
        if (!context.mounted || path == null) return;
        await ref
            .read(destinationsProvider.notifier)
            .setSystemFolder(systemId, path);
    }
  }
}

/// Signed-in user. Sign out matches the avatar dialog.
class AccountSettings extends ConsumerWidget {
  const AccountSettings({
    super.key,
    required this.link,
    required this.onHorizontal,
  });

  final SettingsColumnLink link;
  final void Function(TraversalDirection direction) onHorizontal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final username = ref.watch(sessionProvider)?.username;
    return SettingsFocusColumn(
      link: link,
      length: 2,
      onHorizontal: onHorizontal,
      itemBuilder: (context, index, node) {
        if (index == 0) {
          return RsListRow(
            focusNode: node,
            title: username ?? 'Account',
            subtitle: 'Signed in on this device.',
          );
        }
        return Align(
          alignment: Alignment.centerLeft,
          child: RsButton(
            focusNode: node,
            label: 'Sign out',
            variant: RsButtonVariant.danger,
            onPressed: () {
              unawaited(ref.read(sessionProvider.notifier).logout());
            },
          ),
        );
      },
    );
  }
}

/// The look's own accent first, then a short set of accents.
const accentPresets = <_AccentPreset>[
  _AccentPreset('Look default', RsThemeSettings.defaultAccent),
  _AccentPreset('Violet', Color(0xFF7B5CFF)),
  _AccentPreset('Green', Color(0xFF3D9B4F)),
  _AccentPreset('Orange', Color(0xFFE08A2C)),
  _AccentPreset('Red', Color(0xFFD24B4B)),
  _AccentPreset('Teal', Color(0xFF2A9D8F)),
];

class _AccentPreset {
  const _AccentPreset(this.name, this.color);

  final String name;
  final Color color;
}

String themeModeLabel(ThemeMode mode) => switch (mode) {
  ThemeMode.dark => 'Dark',
  ThemeMode.light => 'Light',
  ThemeMode.system => 'Match system',
};

String accentLabel(Color accent) {
  for (final preset in accentPresets) {
    if (preset.color == accent) return preset.name;
  }
  return 'Custom';
}

String systemLabel(String id) => GameSystems.byId(id)?.name ?? id;

class _AccentSwatch extends StatelessWidget {
  const _AccentSwatch({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final size = context.rsTokens.sizes.icon;
    return ColoredBox(
      color: color,
      child: SizedBox(width: size, height: size),
    );
  }
}

enum _FolderAction { choose, clear }

List<String> _systemIds(
  List<DetectedEmulator> detected,
  Map<String, LaunchChoice> saved,
) {
  final ids = <String>{
    ...saved.keys,
    for (final emulator in detected) ...emulator.systems,
  };
  final ordered = ids.toList()
    ..sort((a, b) {
      final rank = _systemRank(a).compareTo(_systemRank(b));
      if (rank != 0) return rank;
      return a.compareTo(b);
    });
  return ordered;
}

List<String> _storageSystems(
  InstallDestination destination,
  List<InstallRecord> records,
) {
  final ids = <String>{
    ...destination.foldersBySystem.keys,
    for (final record in records)
      if (record.phase == InstallPhase.installed) record.systemId,
  };
  final ordered = ids.toList()
    ..sort((a, b) {
      final rank = _systemRank(a).compareTo(_systemRank(b));
      if (rank != 0) return rank;
      return a.compareTo(b);
    });
  return ordered;
}

int _systemRank(String id) {
  final index = GameSystems.all.indexWhere((system) => system.id == id);
  if (index < 0) return GameSystems.all.length;
  return index;
}

String emulatorChoiceLabel(
  LaunchChoice? choice,
  List<DetectedEmulator> detected,
) {
  if (choice == null) return 'Ask when playing';
  if (choice.emulatorId == customEmulatorId) {
    final command = choice.customCommand;
    if (command == null || command.isEmpty) return 'Custom';
    return command;
  }
  var name = choice.emulatorId;
  for (final emulator in detected) {
    if (emulator.id == choice.emulatorId) {
      name = emulator.name;
      break;
    }
  }
  final core = choice.corePath;
  if (core == null) return name;
  return '$name · ${_fileName(core)}';
}

List<_EmulatorOption> _optionsFor(
  List<DetectedEmulator> detected,
  String systemId,
) {
  final rows = <_EmulatorOption>[];
  for (final emulator in detected) {
    if (emulator.kind == EmulatorKind.retroarch) {
      for (final core in emulator.cores) {
        if (!core.systems.contains(systemId)) continue;
        rows.add(
          _EmulatorOption(
            title: emulator.name,
            subtitle: _fileName(core.path),
            choice: LaunchChoice(emulatorId: emulator.id, corePath: core.path),
          ),
        );
      }
      continue;
    }
    if (!emulator.systems.contains(systemId)) continue;
    rows.add(
      _EmulatorOption(
        title: emulator.name,
        choice: LaunchChoice(emulatorId: emulator.id),
      ),
    );
  }
  return rows;
}

String _fileName(String path) {
  final normalized = path.replaceAll(r'\', '/');
  final slash = normalized.lastIndexOf('/');
  if (slash < 0) return path;
  final name = normalized.substring(slash + 1);
  return name.isEmpty ? path : name;
}

class _EmulatorOption {
  const _EmulatorOption({
    required this.title,
    required this.choice,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final LaunchChoice choice;
}

class _SystemEmulatorDialog extends StatefulWidget {
  const _SystemEmulatorDialog({
    required this.systemName,
    required this.options,
    required this.current,
    required this.onSave,
    required this.onClear,
  });

  final String systemName;
  final List<_EmulatorOption> options;
  final LaunchChoice? current;
  final Future<void> Function(LaunchChoice choice) onSave;
  final Future<void> Function() onClear;

  @override
  State<_SystemEmulatorDialog> createState() => _SystemEmulatorDialogState();
}

class _SystemEmulatorDialogState extends State<_SystemEmulatorDialog> {
  final _command = TextEditingController();
  LaunchChoice? _selected;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    final current = widget.current;
    if (current == null) return;
    if (current.emulatorId == customEmulatorId) {
      _command.text = current.customCommand ?? '';
      return;
    }
    for (final option in widget.options) {
      if (option.choice == current) {
        _selected = option.choice;
        return;
      }
    }
  }

  @override
  void dispose() {
    _command.dispose();
    super.dispose();
  }

  LaunchChoice? get _pending {
    final command = _command.text.trim();
    if (command.isNotEmpty) {
      return LaunchChoice(emulatorId: customEmulatorId, customCommand: command);
    }
    return _selected;
  }

  Future<void> _commit(Future<void> Function() write) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await write();
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.rsTokens;
    final pending = _pending;
    final customWins = _command.text.trim().isNotEmpty;
    VoidCallback? save;
    if (pending != null && !_saving) {
      final choice = pending;
      save = () => unawaited(_commit(() => widget.onSave(choice)));
    }
    final clear = widget.current == null || _saving
        ? null
        : () => unawaited(_commit(widget.onClear));
    return RsDialog(
      title: widget.systemName,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final option in widget.options)
            RsListRow(
              title: option.title,
              subtitle: option.subtitle,
              value: !customWins && _selected == option.choice
                  ? 'Selected'
                  : null,
              onPressed: () => setState(() => _selected = option.choice),
            ),
          if (widget.options.isNotEmpty) SizedBox(height: t.spacing.md),
          RsTextField(
            controller: _command,
            label: 'Custom command',
            hint: 'path and {rom}',
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        RsButton(label: 'Save', onPressed: save),
        RsButton(label: 'Clear', onPressed: clear),
      ],
    );
  }
}
