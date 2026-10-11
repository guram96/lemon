import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../install/install_store_io.dart' show defaultInstallDirectory;
import 'client_settings.dart';

/// Opens a store whose JSON file lives in [directory].
///
/// [directory] must be a [Directory], or null for [defaultInstallDirectory].
ClientSettingsStore openClientSettingsStore(Object? directory) {
  if (directory == null) {
    return FileClientSettingsStore(defaultInstallDirectory());
  }
  if (directory is Directory) return FileClientSettingsStore(directory);
  throw ArgumentError.value(directory, 'directory', 'Expected a Directory');
}

/// JSON file in [directory], replaced by writing a temp file and renaming it
/// over [clientSettingsFileName]. Malformed JSON loads as defaults.
class FileClientSettingsStore implements ClientSettingsStore {
  FileClientSettingsStore(this.directory);

  final Directory directory;

  Future<void> _queue = Future<void>.value();

  File get _target {
    final sep = Platform.pathSeparator;
    final base = directory.path.endsWith(sep) && directory.path.length > 1
        ? directory.path.substring(0, directory.path.length - 1)
        : directory.path;
    return File('$base$sep$clientSettingsFileName');
  }

  Future<T> _sync<T>(Future<T> Function() action) {
    final previous = _queue;
    final result = previous.then((_) => action());
    _queue = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  @override
  Future<ClientSettings> load() => _sync(() async {
    try {
      final file = _target;
      if (!await file.exists()) return const ClientSettings();
      final text = await file.readAsString();
      if (text.trim().isEmpty) return const ClientSettings();
      return ClientSettings.parse(text);
    } on Object {
      return const ClientSettings();
    }
  });

  @override
  Future<void> save(ClientSettings settings) => _sync(() async {
    await directory.create(recursive: true);
    final stamp = '${pid}_${DateTime.now().microsecondsSinceEpoch}';
    final sep = Platform.pathSeparator;
    final temp = File(
      '${_target.parent.path}$sep.$clientSettingsFileName.$stamp.tmp',
    );
    try {
      await temp.writeAsString(jsonEncode(settings.toJson()), flush: true);
      await temp.rename(_target.path);
    } on Object {
      if (await temp.exists()) await temp.delete();
      rethrow;
    }
  });
}
