import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rs_client/src/install/install_models.dart';
import 'package:rs_client/src/install/install_store.dart';
import 'package:rs_client/src/launch/emulator_detector.dart';
import 'package:rs_client/src/launch/emulator_manifest.dart';
import 'package:rs_client/src/launch/game_launcher.dart';
import 'package:rs_client/src/launch/launch_models.dart';
import 'package:rs_core/rs_core.dart';

const _serverId = 'server-1';
const _gameId = 'chrono';
const _systemId = 'snes';
const _snes9xExecutable = '/Applications/Snes9x.app/Contents/MacOS/Snes9x';
const _retroarchExecutable =
    '/Applications/RetroArch.app/Contents/MacOS/RetroArch';
const _corePath = '/cores/My Core/snes9x_libretro.dylib';

final _folder = Directory.systemTemp.path;

final _snes9x = DetectedEmulator(
  id: 'snes9x',
  name: 'Snes9x',
  kind: EmulatorKind.standalone,
  executable: _snes9xExecutable,
  args: const ['{rom}'],
  systems: const ['snes'],
  cores: const <DetectedCore>[],
);

final _retroarch = DetectedEmulator(
  id: 'retroarch',
  name: 'RetroArch',
  kind: EmulatorKind.retroarch,
  executable: _retroarchExecutable,
  args: const ['-L', '{core}', '{rom}'],
  systems: const ['snes'],
  cores: const <DetectedCore>[],
);

final _snes9xChoice = LaunchChoice(emulatorId: 'snes9x');

void main() {
  group('file to launch', () {
    test('m3u is preferred over cue, gdi, and a bare rom', () async {
      await _expectRom(const [
        'game.sfc',
        'game.cue',
        'disc.gdi',
        'First.M3U',
        'Second.m3u',
      ], 'First.M3U');
    });

    test('cue is preferred when there is no m3u', () async {
      await _expectRom(const [
        'notes.m3u.txt',
        'track.bin',
        'Game.CUE',
        'disc.gdi',
      ], 'Game.CUE');
    });

    test('gdi is preferred when there is no m3u or cue', () async {
      await _expectRom(const [
        'game.bin',
        'notes.cue.bak',
        'Disc.GDI',
      ], 'Disc.GDI');
    });

    test('the first file is used otherwise', () async {
      await _expectRom(const ['alpha.chd', 'beta.bin'], 'alpha.chd');
    });

    test('a path that escapes the folder does not start', () async {
      const relative = '../outside.sfc';
      expect(_resolve('Chrono Trigger.sfc'), isNotNull);
      expect(_resolve(relative), isNull);

      final starter = _FakeStarter();
      final result = await _launch(starter, files: const [relative]);
      _expectNoStart(result, starter);
    });
  });

  group('install state', () {
    test('a record that is not installed does not start', () async {
      for (final phase in const [
        InstallPhase.queued,
        InstallPhase.downloading,
        InstallPhase.paused,
        InstallPhase.failed,
      ]) {
        final starter = _FakeStarter();
        final result = await _launch(starter, record: _installed(phase: phase));
        _expectNoStart(result, starter);
      }
    });

    test('a null record does not start', () async {
      final starter = _FakeStarter();
      final result = await _launch(starter, includeRecord: false);
      _expectNoStart(result, starter);
    });

    test('a null folder does not start', () async {
      final starter = _FakeStarter();
      final result = await _launch(starter, includeFolder: false);
      _expectNoStart(result, starter);
    });

    test('an empty folder does not start', () async {
      final starter = _FakeStarter();
      final result = await _launch(starter, folder: '');
      _expectNoStart(result, starter);
    });

    test('a game with no files does not start', () async {
      final starter = _FakeStarter();
      final result = await _launch(starter, files: const []);
      _expectNoStart(result, starter);
    });

    test('a system mismatch does not start', () async {
      final starter = _FakeStarter();
      final result = await _launch(
        starter,
        record: _installed(systemId: 'nes'),
      );
      _expectNoStart(result, starter);
    });

    test('a game id mismatch does not start', () async {
      final starter = _FakeStarter();
      final result = await _launch(
        starter,
        record: _installed(gameId: 'other'),
      );
      _expectNoStart(result, starter);
    });
  });

  group('command', () {
    test('retroarch args keep the core and rom as whole arguments', () async {
      final starter = _FakeStarter();
      final rom = _requireRom('Chrono Trigger.sfc');
      final result = await _launch(
        starter,
        choice: LaunchChoice(emulatorId: 'retroarch', corePath: _corePath),
        detected: [_snes9x, _retroarch],
      );
      _expectStarted(
        starter,
        result,
        executable: _retroarchExecutable,
        args: ['-L', _corePath, rom],
      );
    });

    test('retroarch without a core does not start', () async {
      final starter = _FakeStarter();
      final result = await _launch(
        starter,
        choice: LaunchChoice(emulatorId: 'retroarch'),
        detected: [_retroarch],
      );
      _expectNoStart(result, starter);
    });

    test('standalone args are the rom path', () async {
      final starter = _FakeStarter();
      final rom = _requireRom('Chrono Trigger.sfc');
      final result = await _launch(starter, detected: [_retroarch, _snes9x]);
      _expectStarted(
        starter,
        result,
        executable: _snes9xExecutable,
        args: [rom],
      );
    });

    test('custom command honors quotes and {rom}', () async {
      final starter = _FakeStarter();
      final rom = _requireRom('Chrono Trigger.sfc');
      final result = await _launch(
        starter,
        choice: LaunchChoice(
          emulatorId: customEmulatorId,
          corePath: _corePath,
          customCommand: '"/Emulators/My Emu" -L "{core}" "{rom}"',
        ),
        detected: const [],
      );
      _expectStarted(
        starter,
        result,
        executable: '/Emulators/My Emu',
        args: ['-L', _corePath, rom],
      );
    });

    test('custom command without {rom} appends the rom', () async {
      final starter = _FakeStarter();
      final rom = _requireRom('Chrono Trigger.sfc');
      final result = await _launch(
        starter,
        choice: LaunchChoice(
          emulatorId: customEmulatorId,
          customCommand: '/usr/bin/snes9x  -fullscreen',
        ),
        detected: const [],
      );
      _expectStarted(
        starter,
        result,
        executable: '/usr/bin/snes9x',
        args: ['-fullscreen', rom],
      );
    });

    test('an unknown {token} does not start', () async {
      final starter = _FakeStarter();
      final result = await _launch(
        starter,
        choice: LaunchChoice(
          emulatorId: customEmulatorId,
          customCommand: '/usr/bin/emu {rom} {bios}',
        ),
      );
      _expectNoStart(result, starter);
    });

    test('an unclosed quote does not start', () async {
      final starter = _FakeStarter();
      final result = await _launch(
        starter,
        choice: LaunchChoice(
          emulatorId: customEmulatorId,
          customCommand: '"/usr/bin/emu" "{rom}',
        ),
      );
      _expectNoStart(result, starter);
    });

    test('{core} without a core path does not start', () async {
      final starter = _FakeStarter();
      final result = await _launch(
        starter,
        choice: LaunchChoice(
          emulatorId: customEmulatorId,
          customCommand: '/usr/bin/emu -L {core} {rom}',
        ),
      );
      _expectNoStart(result, starter);
    });

    test('an emulator id that was not detected does not start', () async {
      final starter = _FakeStarter();
      final result = await _launch(
        starter,
        choice: LaunchChoice(emulatorId: 'dolphin'),
        detected: [_snes9x],
      );
      _expectNoStart(result, starter);
    });

    test('no selected emulator does not start', () async {
      final starter = _FakeStarter();
      final result = await _launch(starter, includeChoice: false);
      _expectNoStart(result, starter);
    });
  });

  test('android, ios, and web are unsupported and do not start', () async {
    for (final platform in const ['android', 'ios', 'web']) {
      final starter = _FakeStarter();
      final result = await _launch(starter, platform: platform);
      expect(result, isA<LaunchUnsupported>());
      expect(starter.calls, isEmpty);
    }
  });

  test('a starter error becomes LaunchFailed', () async {
    final starter = _FakeStarter(error: Exception('could not start'));
    final result = await _launch(starter);
    expect(result, isA<LaunchFailed>());
    expect((result as LaunchFailed).message, contains('could not start'));
    expect(starter.calls, hasLength(1));
  });

  test('gameLauncherProvider builds a launcher', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(gameLauncherProvider), isA<GameLauncher>());
  });
}

Future<void> _expectRom(List<String> files, String chosen) async {
  final starter = _FakeStarter();
  final result = await _launch(starter, files: files);
  _expectStarted(
    starter,
    result,
    executable: _snes9xExecutable,
    args: [_requireRom(chosen)],
  );
}

void _expectStarted(
  _FakeStarter starter,
  LaunchResult result, {
  required String executable,
  required List<String> args,
}) {
  expect(result, isA<LaunchStarted>());
  expect((result as LaunchStarted).pid, starter.pid);
  expect(starter.calls, hasLength(1));
  expect(starter.calls.single.executable, executable);
  expect(starter.calls.single.args, args);
}

void _expectNoStart(LaunchResult result, _FakeStarter starter) {
  expect(result, isA<LaunchFailed>());
  expect((result as LaunchFailed).message, isNotEmpty);
  expect(starter.calls, isEmpty);
}

String? _resolve(String relativePath) => resolveInstallFile(
  folder: _folder,
  systemId: _systemId,
  relativePath: relativePath,
);

String _requireRom(String relativePath) {
  final resolved = _resolve(relativePath);
  if (resolved == null) {
    fail('$relativePath did not resolve inside $_folder');
  }
  return resolved;
}

Game _game(List<String> paths) => Game(
  id: _gameId,
  systemId: _systemId,
  title: 'Chrono Trigger',
  rootId: 'root-1',
  files: [for (final path in paths) GameFile(path: path, sizeBytes: 1024)],
  addedAt: DateTime.utc(1995, 3, 11),
);

InstallRecord _installed({
  String gameId = _gameId,
  String systemId = _systemId,
  InstallPhase phase = InstallPhase.installed,
}) => InstallRecord(
  serverId: _serverId,
  gameId: gameId,
  systemId: systemId,
  phase: phase,
  receivedBytes: 1024,
  totalBytes: 1024,
);

Future<LaunchResult> _launch(
  _FakeStarter starter, {
  String platform = 'macos',
  List<String> files = const ['Chrono Trigger.sfc'],
  InstallRecord? record,
  bool includeRecord = true,
  String? folder,
  bool includeFolder = true,
  LaunchChoice? choice,
  bool includeChoice = true,
  List<DetectedEmulator>? detected,
}) {
  return GameLauncher(starter: starter).launch(
    platform: platform,
    game: _game(files),
    record: includeRecord ? (record ?? _installed()) : null,
    folder: includeFolder ? (folder ?? _folder) : null,
    choice: includeChoice ? (choice ?? _snes9xChoice) : null,
    detected: detected ?? [_snes9x],
  );
}

class _FakeStarter implements ProcessStarter {
  _FakeStarter({this.error});

  final Object? error;
  final int pid = 4242;
  final calls = <_StartCall>[];

  @override
  Future<int> start(String executable, List<String> args) async {
    calls.add(_StartCall(executable, List<String>.from(args)));
    final thrown = error;
    if (thrown != null) throw thrown;
    return pid;
  }
}

class _StartCall {
  _StartCall(this.executable, this.args);

  final String executable;
  final List<String> args;
}
