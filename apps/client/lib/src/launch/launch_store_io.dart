import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../install/install_store_io.dart' show defaultInstallDirectory;
import 'launch_models.dart';
import 'launch_store.dart';

/// Opens a store whose JSON file lives in [directory].
///
/// [directory] must be a [Directory], or null for [defaultInstallDirectory].
LaunchStore openLaunchStore(Object? directory) {
  if (directory == null) return FileLaunchStore(defaultInstallDirectory());
  if (directory is Directory) return FileLaunchStore(directory);
  throw ArgumentError.value(directory, 'directory', 'Expected a Directory');
}

/// JSON file in [directory], replaced by writing a temp file and renaming it
/// over [launchStoreFileName].
class FileLaunchStore implements LaunchStore {
  FileLaunchStore(this.directory);

  final Directory directory;

  Future<void> _queue = Future<void>.value();

  File get _target {
    final sep = Platform.pathSeparator;
    final base = directory.path.endsWith(sep) && directory.path.length > 1
        ? directory.path.substring(0, directory.path.length - 1)
        : directory.path;
    return File('$base$sep$launchStoreFileName');
  }

  Future<T> _sync<T>(Future<T> Function() action) {
    final previous = _queue;
    final result = previous.then((_) => action());
    _queue = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  @override
  Future<LaunchOptions> read() => _sync(_read);

  @override
  Future<void> putSystem(String systemId, LaunchChoice choice) {
    final persisted = _checked(choice);
    return _sync(() async {
      final data = await _read();
      await _write(data.withSystem(systemId, persisted));
    });
  }

  @override
  Future<void> removeSystem(String systemId) {
    return _sync(() async {
      final data = await _read();
      if (!data.systems.containsKey(systemId)) return;
      await _write(data.withoutSystem(systemId));
    });
  }

  @override
  Future<void> putGame(String serverId, String gameId, LaunchChoice choice) {
    final persisted = _checked(choice);
    return _sync(() async {
      final data = await _read();
      await _write(data.withGame(serverId, gameId, persisted));
    });
  }

  @override
  Future<void> removeGame(String serverId, String gameId) {
    return _sync(() async {
      final data = await _read();
      if (data.games[serverId]?.containsKey(gameId) != true) return;
      await _write(data.withoutGame(serverId, gameId));
    });
  }

  Future<LaunchOptions> _read() async {
    final file = _target;
    if (!await file.exists()) return LaunchOptions();
    final text = await file.readAsString();
    if (text.trim().isEmpty) return LaunchOptions();
    final decoded = jsonDecode(text);
    if (decoded is! Map) {
      throw const FormatException('launch store is not a JSON object');
    }
    return LaunchOptions.fromJson(Map<String, Object?>.from(decoded));
  }

  Future<void> _write(LaunchOptions data) async {
    await directory.create(recursive: true);
    final stamp = '${pid}_${DateTime.now().microsecondsSinceEpoch}';
    final sep = Platform.pathSeparator;
    final temp = File(
      '${_target.parent.path}$sep.$launchStoreFileName.$stamp.tmp',
    );
    try {
      await temp.writeAsString(jsonEncode(data.toJson()), flush: true);
      await temp.rename(_target.path);
    } on Object {
      if (await temp.exists()) await temp.delete();
      rethrow;
    }
  }
}

/// Runs [choice] through [LaunchChoice] again so an invalid choice is rejected
/// before it is written.
LaunchChoice _checked(LaunchChoice choice) => LaunchChoice(
  emulatorId: choice.emulatorId,
  corePath: choice.corePath,
  customCommand: choice.customCommand,
);
