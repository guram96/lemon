import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rs_core/rs_core.dart';

import '../install/install_models.dart';
import '../install/install_store.dart';
import 'emulator_detector.dart';
import 'emulator_manifest.dart';
import 'game_launcher_stub.dart'
    if (dart.library.io) 'game_launcher_io.dart'
    as launcher_io;
import 'launch_models.dart';

/// Starts a process and does not wait for it to exit.
abstract interface class ProcessStarter {
  /// Starts [executable] with [args] and does not wait for it to exit.
  /// Returns the pid.
  Future<int> start(String executable, List<String> args);
}

/// Outcome of [GameLauncher.launch].
sealed class LaunchResult {
  const LaunchResult();
}

/// The emulator process was started. The client does not wait for it.
final class LaunchStarted extends LaunchResult {
  const LaunchStarted(this.pid);

  final int pid;

  @override
  String toString() => 'LaunchStarted($pid)';
}

/// Launch was refused, or the process could not be started.
final class LaunchFailed extends LaunchResult {
  const LaunchFailed(this.message);

  final String message;

  @override
  String toString() => 'LaunchFailed($message)';
}

/// This platform cannot start an emulator.
final class LaunchUnsupported extends LaunchResult {
  const LaunchUnsupported();

  @override
  String toString() => 'LaunchUnsupported()';
}

/// Starts an installed game with a detected emulator or a custom command.
///
/// [launch] takes every input explicitly. It does not read providers.
class GameLauncher {
  const GameLauncher({required this.starter});

  final ProcessStarter starter;

  /// Starts [game] and returns without waiting for the emulator to exit.
  ///
  /// Android, iOS, and web return [LaunchUnsupported] and do not start a
  /// process. A missing install, a path outside [folder], a missing emulator,
  /// or a bad command returns [LaunchFailed].
  Future<LaunchResult> launch({
    required String platform,
    required Game game,
    required InstallRecord? record,
    required String? folder,
    required LaunchChoice? choice,
    required List<DetectedEmulator> detected,
  }) async {
    if (platform == 'android' || platform == 'ios' || platform == 'web') {
      return const LaunchUnsupported();
    }
    if (record == null || record.phase != InstallPhase.installed) {
      return const LaunchFailed('Game is not installed');
    }
    if (folder == null || folder.isEmpty) {
      return const LaunchFailed('No install folder is set');
    }
    if (game.files.isEmpty) {
      return const LaunchFailed('Game has no files');
    }
    if (record.systemId != game.systemId || record.gameId != game.id) {
      return const LaunchFailed('Install record does not match this game');
    }

    final resolved = resolveInstallFile(
      folder: folder,
      systemId: game.systemId,
      relativePath: _preferredRelativePath(game.files),
    );
    if (resolved == null) {
      return const LaunchFailed('Game file is outside the install folder');
    }
    if (choice == null) {
      return const LaunchFailed('No emulator is selected');
    }

    final plan = choice.emulatorId == customEmulatorId
        ? _fromCustom(choice, resolved)
        : _fromDetected(choice, detected, resolved);
    final failure = plan.message;
    if (failure != null) return LaunchFailed(failure);

    try {
      final pid = await starter.start(plan.executable, plan.args);
      return LaunchStarted(pid);
    } catch (error) {
      return LaunchFailed(error.toString());
    }
  }
}

/// Starter for this process. On the web, [ProcessStarter.start] throws.
ProcessStarter openProcessStarter() => launcher_io.openProcessStarter();

/// Launcher for this process.
///
/// Tests construct [GameLauncher] with a fake [ProcessStarter].
final gameLauncherProvider = Provider<GameLauncher>(
  (ref) => GameLauncher(starter: openProcessStarter()),
);

String _preferredRelativePath(List<GameFile> files) {
  for (final suffix in const ['.m3u', '.cue', '.gdi']) {
    for (final file in files) {
      if (file.path.toLowerCase().endsWith(suffix)) return file.path;
    }
  }
  return files.first.path;
}

_CommandPlan _fromDetected(
  LaunchChoice choice,
  List<DetectedEmulator> detected,
  String rom,
) {
  DetectedEmulator? emulator;
  for (final candidate in detected) {
    if (candidate.id == choice.emulatorId) {
      emulator = candidate;
      break;
    }
  }
  if (emulator == null) {
    return const _CommandPlan.failed('Emulator is not installed');
  }
  final core = choice.corePath;
  if (emulator.kind == EmulatorKind.retroarch &&
      (core == null || core.isEmpty)) {
    return const _CommandPlan.failed('RetroArch needs a core');
  }
  final expanded = _expandAll(emulator.args, rom: rom, core: core);
  final failure = expanded.message;
  if (failure != null) return _CommandPlan.failed(failure);
  return _CommandPlan.ready(emulator.executable, expanded.args);
}

_CommandPlan _fromCustom(LaunchChoice choice, String rom) {
  final command = choice.customCommand;
  if (command == null || command.isEmpty) {
    return const _CommandPlan.failed('Custom command is empty');
  }
  final tokens = _splitCommand(command);
  if (tokens == null) {
    return const _CommandPlan.failed('Custom command has an unclosed quote');
  }
  if (tokens.isEmpty) {
    return const _CommandPlan.failed('Custom command is empty');
  }
  final expanded = _expandAll(tokens, rom: rom, core: choice.corePath);
  final failure = expanded.message;
  if (failure != null) return _CommandPlan.failed(failure);
  if (expanded.args.isEmpty || expanded.args.first.isEmpty) {
    return const _CommandPlan.failed('Custom command is empty');
  }
  final args = expanded.args.sublist(1);
  if (!expanded.sawRom) args.add(rom);
  return _CommandPlan.ready(expanded.args.first, args);
}

/// Splits [command] on whitespace. Double quotes group one token and are not
/// kept. There is no shell and no backslash escaping. Returns null when a
/// quote is never closed.
List<String>? _splitCommand(String command) {
  final tokens = <String>[];
  final buffer = StringBuffer();
  var inQuote = false;
  var started = false;
  for (var index = 0; index < command.length; index++) {
    final char = command[index];
    if (inQuote) {
      if (char == '"') {
        inQuote = false;
        continue;
      }
      buffer.write(char);
      continue;
    }
    if (char == '"') {
      inQuote = true;
      started = true;
      continue;
    }
    if (_isWhitespace(char)) {
      if (!started) continue;
      tokens.add(buffer.toString());
      buffer.clear();
      started = false;
      continue;
    }
    buffer.write(char);
    started = true;
  }
  if (inQuote) return null;
  if (started) tokens.add(buffer.toString());
  return tokens;
}

bool _isWhitespace(String char) => char.trim().isEmpty;

_ExpandedArgs _expandAll(
  List<String> tokens, {
  required String rom,
  required String? core,
}) {
  final args = <String>[];
  var sawRom = false;
  for (final token in tokens) {
    final expanded = _expandToken(token, rom: rom, core: core);
    final failure = expanded.message;
    if (failure != null) return _ExpandedArgs.fail(failure);
    if (expanded.sawRom) sawRom = true;
    args.add(expanded.text);
  }
  return _ExpandedArgs.ok(args, sawRom: sawRom);
}

/// Replaces `{rom}` and `{core}` in [token]. Any other `{token}` fails.
/// The replacement is not split on spaces.
_TokenResult _expandToken(String token, {required String rom, String? core}) {
  final buffer = StringBuffer();
  var sawRom = false;
  var index = 0;
  while (index < token.length) {
    final open = token.indexOf('{', index);
    if (open < 0) {
      buffer.write(token.substring(index));
      break;
    }
    final close = token.indexOf('}', open + 1);
    if (close < 0) {
      buffer.write(token.substring(index));
      break;
    }
    final name = token.substring(open + 1, close);
    buffer.write(token.substring(index, open));
    if (name == 'rom') {
      sawRom = true;
      buffer.write(rom);
    } else if (name == 'core') {
      if (core == null || core.isEmpty) {
        return const _TokenResult.fail('Core path is missing');
      }
      buffer.write(core);
    } else {
      return _TokenResult.fail('Unknown launch token {$name}');
    }
    index = close + 1;
  }
  return _TokenResult.ok(buffer.toString(), sawRom: sawRom);
}

class _CommandPlan {
  _CommandPlan.ready(this.executable, this.args) : message = null;

  const _CommandPlan.failed(this.message) : executable = '', args = const [];

  final String executable;
  final List<String> args;
  final String? message;
}

class _ExpandedArgs {
  _ExpandedArgs.ok(this.args, {required this.sawRom}) : message = null;

  const _ExpandedArgs.fail(this.message) : args = const [], sawRom = false;

  final List<String> args;
  final bool sawRom;
  final String? message;
}

class _TokenResult {
  _TokenResult.ok(this.text, {required this.sawRom}) : message = null;

  const _TokenResult.fail(this.message) : text = '', sawRom = false;

  final String text;
  final bool sawRom;
  final String? message;
}
