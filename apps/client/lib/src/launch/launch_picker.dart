import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rs_core/rs_core.dart';
import 'package:rs_theme/rs_theme.dart';
import 'package:rs_ui/rs_ui.dart';

import '../storage/credential_store.dart';
import 'emulator_detector.dart';
import 'emulator_manifest.dart';
import 'launch_models.dart';
import 'launch_store.dart';

/// Asks which emulator should start [game], then stores the choice.
///
/// Does not start a process. B / Esc closes the dialog without saving.
Future<void> showLaunchPicker({
  required BuildContext context,
  required WidgetRef ref,
  required Game game,
}) async {
  final detected = ref.read(detectedEmulatorsProvider);
  final credentials = ref.read(credentialStoreProvider);
  final serverId = (await credentials.load()).serverId;
  if (!context.mounted) return;
  await showRsDialog<void>(
    context: context,
    builder: (_) => _LaunchPickerDialog(
      game: game,
      detected: detected,
      serverId: serverId,
      ref: ref,
    ),
  );
}

class _LaunchPickerDialog extends StatefulWidget {
  const _LaunchPickerDialog({
    required this.game,
    required this.detected,
    required this.serverId,
    required this.ref,
  });

  final Game game;
  final List<DetectedEmulator> detected;
  final String? serverId;
  final WidgetRef ref;

  @override
  State<_LaunchPickerDialog> createState() => _LaunchPickerDialogState();
}

class _LaunchPickerDialogState extends State<_LaunchPickerDialog> {
  final _command = TextEditingController();
  LaunchChoice? _row;
  var _saving = false;

  @override
  void dispose() {
    _command.dispose();
    super.dispose();
  }

  LaunchChoice? _pending() {
    final command = _command.text.trim();
    if (command.isNotEmpty) {
      return LaunchChoice(emulatorId: customEmulatorId, customCommand: command);
    }
    return _row;
  }

  Future<void> _useForSystem(LaunchChoice choice) async {
    await widget.ref
        .read(launchOptionsProvider.notifier)
        .setSystem(widget.game.systemId, choice);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _useForGame(LaunchChoice choice, String serverId) async {
    await widget.ref
        .read(launchOptionsProvider.notifier)
        .setGame(serverId, widget.game.id, choice);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _save(Future<void> Function() write) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await write();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.rsTokens;
    final pending = _pending();
    final rows = _rowsFor(widget.detected, widget.game.systemId);
    final customWins = _command.text.trim().isNotEmpty;
    final serverId = widget.serverId;

    VoidCallback? useForSystem;
    VoidCallback? onlyThisGame;
    if (pending != null && !_saving) {
      final choice = pending;
      useForSystem = () => unawaited(_save(() => _useForSystem(choice)));
      if (serverId != null) {
        onlyThisGame = () =>
            unawaited(_save(() => _useForGame(choice, serverId)));
      }
    }

    return RsDialog(
      title: 'Emulator',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final row in rows)
            RsListRow(
              title: row.title,
              subtitle: row.subtitle,
              value: !customWins && _row == row.choice ? 'Selected' : null,
              onPressed: () => setState(() => _row = row.choice),
            ),
          if (rows.isNotEmpty) SizedBox(height: t.spacing.md),
          RsTextField(
            controller: _command,
            label: 'Custom command',
            hint: 'path and {rom}',
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        RsButton(label: 'Use for this system', onPressed: useForSystem),
        RsButton(label: 'Only this game', onPressed: onlyThisGame),
      ],
    );
  }
}

class _PickerRow {
  const _PickerRow({required this.title, required this.choice, this.subtitle});

  final String title;
  final String? subtitle;
  final LaunchChoice choice;
}

List<_PickerRow> _rowsFor(List<DetectedEmulator> detected, String systemId) {
  final rows = <_PickerRow>[];
  for (final emulator in detected) {
    if (emulator.kind == EmulatorKind.retroarch) {
      for (final core in emulator.cores) {
        if (!core.systems.contains(systemId)) continue;
        rows.add(
          _PickerRow(
            title: 'RetroArch',
            subtitle: _fileName(core.path),
            choice: LaunchChoice(emulatorId: emulator.id, corePath: core.path),
          ),
        );
      }
      continue;
    }
    if (!emulator.systems.contains(systemId)) continue;
    rows.add(
      _PickerRow(
        title: emulator.name,
        choice: LaunchChoice(emulatorId: emulator.id),
      ),
    );
  }
  return rows;
}

/// Last path segment of [path]. Separators are `/` and `\`.
String _fileName(String path) {
  final normalized = path.replaceAll(r'\', '/');
  final slash = normalized.lastIndexOf('/');
  if (slash < 0) return path;
  final name = normalized.substring(slash + 1);
  return name.isEmpty ? path : name;
}
