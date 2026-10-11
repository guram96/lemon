import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'install_models.dart';
import 'install_store.dart';

/// Opens a store whose JSON file lives in [directory].
///
/// [directory] must be a [Directory], or null for [defaultInstallDirectory].
InstallStore openInstallStore(Object? directory) {
  if (directory == null) return FileInstallStore(defaultInstallDirectory());
  if (directory is Directory) return FileInstallStore(directory);
  throw ArgumentError.value(directory, 'directory', 'Expected a Directory');
}

/// Fallback when [installDirectoryProvider] is left null.
///
/// Mobile has no portable data directory without a path plugin, so callers
/// on Android and iOS must override [installDirectoryProvider].
Directory defaultInstallDirectory() {
  final sep = Platform.pathSeparator;
  if (Platform.isMacOS) {
    final home = Platform.environment['HOME'];
    if (home != null && home.isNotEmpty) {
      return Directory(
        '$home${sep}Library${sep}Application Support${sep}retro_steam',
      );
    }
  } else if (Platform.isLinux) {
    final xdg = Platform.environment['XDG_DATA_HOME'];
    if (xdg != null && xdg.isNotEmpty) {
      return Directory('$xdg${sep}retro_steam');
    }
    final home = Platform.environment['HOME'];
    if (home != null && home.isNotEmpty) {
      return Directory('$home$sep.local${sep}share${sep}retro_steam');
    }
  } else if (Platform.isWindows) {
    final appData = Platform.environment['APPDATA'];
    if (appData != null && appData.isNotEmpty) {
      return Directory('$appData${sep}retro_steam');
    }
  }
  throw UnsupportedError(
    'No default install directory. Override installDirectoryProvider '
    'with the app data directory.',
  );
}

/// JSON file in [directory], replaced by writing a temp file and renaming it
/// over [installStoreFileName].
class FileInstallStore implements InstallStore {
  FileInstallStore(this.directory);

  final Directory directory;

  Future<void> _queue = Future<void>.value();

  File get _target {
    final sep = Platform.pathSeparator;
    final base = directory.path.endsWith(sep) && directory.path.length > 1
        ? directory.path.substring(0, directory.path.length - 1)
        : directory.path;
    return File('$base$sep$installStoreFileName');
  }

  Future<T> _sync<T>(Future<T> Function() action) {
    final previous = _queue;
    final result = previous.then((_) => action());
    _queue = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  @override
  Future<InstallDestination> readDestinations() =>
      _sync(() async => (await _read()).destinations);

  @override
  Future<void> writeDestinations(InstallDestination destinations) {
    return _sync(() async {
      final data = await _read();
      await _write(
        _InstallData(destinations: destinations, records: data.records),
      );
    });
  }

  @override
  Future<void> put(InstallRecord record) {
    return _sync(() async {
      final data = await _read();
      final records = [
        for (final existing in data.records)
          if (!_sameGame(existing, record)) existing,
        record,
      ];
      await _write(
        _InstallData(destinations: data.destinations, records: records),
      );
    });
  }

  @override
  Future<void> remove(String serverId, String gameId) {
    return _sync(() async {
      final data = await _read();
      final records = [
        for (final existing in data.records)
          if (existing.serverId != serverId || existing.gameId != gameId)
            existing,
      ];
      if (records.length == data.records.length) return;
      await _write(
        _InstallData(destinations: data.destinations, records: records),
      );
    });
  }

  @override
  Future<List<InstallRecord>> installs(String serverId) {
    return _sync(() async {
      final data = await _read();
      final indexed = <(int, InstallRecord)>[];
      for (var i = 0; i < data.records.length; i++) {
        final record = data.records[i];
        if (record.serverId == serverId) indexed.add((i, record));
      }
      indexed.sort((a, b) {
        final byGame = a.$2.gameId.compareTo(b.$2.gameId);
        if (byGame != 0) return byGame;
        return a.$1.compareTo(b.$1);
      });
      return [for (final entry in indexed) entry.$2];
    });
  }

  @override
  Future<List<String>> uninstall(InstallRecord record) {
    return _sync(() async {
      final data = await _read();
      final folder = data.destinations.folderFor(record.systemId);
      final skipped = <String>[];
      for (final file in record.files) {
        if (folder == null) {
          skipped.add(file.path);
          continue;
        }
        final resolved = resolveInstallFile(
          folder: folder,
          systemId: record.systemId,
          relativePath: file.path,
        );
        if (resolved == null || !await _deleteFile(resolved)) {
          skipped.add(file.path);
        }
      }
      final records = [
        for (final existing in data.records)
          if (!_sameGame(existing, record)) existing,
      ];
      if (records.length != data.records.length) {
        await _write(
          _InstallData(destinations: data.destinations, records: records),
        );
      }
      return List.unmodifiable(skipped);
    });
  }

  Future<_InstallData> _read() async {
    final file = _target;
    if (!await file.exists()) return _InstallData.empty;
    final text = await file.readAsString();
    if (text.trim().isEmpty) return _InstallData.empty;
    final decoded = jsonDecode(text);
    if (decoded is! Map) {
      throw const FormatException('install store is not a JSON object');
    }
    return _InstallData.fromJson(Map<String, Object?>.from(decoded));
  }

  Future<void> _write(_InstallData data) async {
    await directory.create(recursive: true);
    final stamp = '${pid}_${DateTime.now().microsecondsSinceEpoch}';
    final sep = Platform.pathSeparator;
    final temp = File(
      '${_target.parent.path}$sep.$installStoreFileName.$stamp.tmp',
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

class _InstallData {
  const _InstallData({required this.destinations, required this.records});

  static final empty = _InstallData(
    destinations: InstallDestination(),
    records: const [],
  );

  final InstallDestination destinations;
  final List<InstallRecord> records;

  Map<String, Object?> toJson() => {
    'destinations': destinations.toJson(),
    'records': [for (final record in records) record.toJson()],
  };

  factory _InstallData.fromJson(Map<String, Object?> json) {
    final rawDestinations = json['destinations'];
    final destinations = rawDestinations == null
        ? InstallDestination()
        : InstallDestination.fromJson(_asMap(rawDestinations, 'destinations'));
    final rawRecords = json['records'];
    final records = <InstallRecord>[];
    if (rawRecords != null) {
      for (final item in _asList(rawRecords, 'records')) {
        records.add(InstallRecord.fromJson(_asMap(item, 'records')));
      }
    }
    return _InstallData(destinations: destinations, records: records);
  }
}

bool _sameGame(InstallRecord a, InstallRecord b) =>
    a.serverId == b.serverId && a.gameId == b.gameId;

Map<String, Object?> _asMap(Object? value, String field) {
  if (value is! Map) {
    throw FormatException('install store field $field is not an object');
  }
  return Map<String, Object?>.from(value);
}

List<Object?> _asList(Object? value, String field) {
  if (value is! List) {
    throw FormatException('install store field $field is not a list');
  }
  return List<Object?>.from(value);
}

/// Lexical path of [folder]/[systemId]/[relativePath], or null when that
/// path must not be deleted.
///
/// Rejects an absolute [relativePath], an empty segment, and `..`. Does not
/// resolve symlinks. The result is null unless it is strictly inside [folder].
String? resolveInstallFile({
  required String folder,
  required String systemId,
  required String relativePath,
}) {
  if (!_safeSystemId(systemId)) return null;
  final segments = _relativeSegments(relativePath);
  if (segments == null) return null;
  final root = _normalizeAbsolute(folder);
  if (root == null) return null;
  final child = _normalizeAbsolute(_join(root, [systemId, ...segments]));
  if (child == null || !_strictlyInside(root, child)) return null;
  return child;
}

/// Deletes a regular file or a symlink. A missing file is success.
/// A directory or anything else is left in place.
Future<bool> _deleteFile(String path) async {
  final type = await FileSystemEntity.type(path, followLinks: false);
  if (type == FileSystemEntityType.notFound) return true;
  if (type != FileSystemEntityType.file && type != FileSystemEntityType.link) {
    return false;
  }
  try {
    await File(path).delete();
  } on PathNotFoundException {
    return true;
  }
  return true;
}

bool _safeSystemId(String systemId) {
  if (systemId.isEmpty || systemId == '.' || systemId == '..') return false;
  if (systemId.contains('/') ||
      systemId.contains('\\') ||
      systemId.contains('\u0000')) {
    return false;
  }
  return !_drivePrefix.hasMatch(systemId);
}

/// Segments of a system-relative path, or null when it is unsafe to join.
List<String>? _relativeSegments(String relativePath) {
  if (relativePath.isEmpty || relativePath.contains('\u0000')) return null;
  if (relativePath.startsWith('/') || relativePath.startsWith('\\')) {
    return null;
  }
  if (_drivePrefix.hasMatch(relativePath)) return null;
  final segments = <String>[];
  for (final segment in relativePath.split('/')) {
    if (segment.isEmpty || segment == '..') return null;
    if (segment.contains('\\')) return null;
    if (segment == '.') continue;
    segments.add(segment);
  }
  if (segments.isEmpty) return null;
  return segments;
}

final _drivePrefix = RegExp(r'^[A-Za-z]:');

String _join(String root, List<String> segments) {
  final sep = Platform.pathSeparator;
  final trimmed = root.length > 1 && root.endsWith(sep)
      ? root.substring(0, root.length - 1)
      : root;
  return [trimmed, ...segments].join(sep);
}

/// Absolute [input] with `.` and `..` collapsed, or null when it is not absolute.
String? _normalizeAbsolute(String input) {
  if (input.contains('\u0000')) return null;
  if (!_isAbsolute(input)) return null;
  final windows = Platform.isWindows;
  final sep = windows ? '\\' : '/';
  final raw = windows ? input.replaceAll('/', '\\') : input;
  final parts = raw.split(sep);
  final stack = <String>[];

  late final String rootPrefix;
  var index = 0;
  if (windows && parts.isNotEmpty && _drivePrefix.hasMatch(parts[0])) {
    rootPrefix = '${parts[0]}\\';
    index = 1;
  } else if (windows && raw.startsWith('\\\\')) {
    while (index < parts.length && parts[index].isEmpty) {
      index++;
    }
    if (index + 1 >= parts.length) return null;
    final server = parts[index];
    final share = parts[index + 1];
    if (server.isEmpty || share.isEmpty) return null;
    rootPrefix = '\\\\$server\\$share';
    index += 2;
  } else {
    rootPrefix = sep;
    while (index < parts.length && parts[index].isEmpty) {
      index++;
    }
  }

  for (var i = index; i < parts.length; i++) {
    final part = parts[i];
    if (part.isEmpty || part == '.') continue;
    if (part == '..') {
      if (stack.isNotEmpty) stack.removeLast();
      continue;
    }
    stack.add(part);
  }

  if (stack.isEmpty) return rootPrefix;
  if (rootPrefix == sep) return '$sep${stack.join(sep)}';
  if (rootPrefix.endsWith(sep)) return '$rootPrefix${stack.join(sep)}';
  return '$rootPrefix$sep${stack.join(sep)}';
}

bool _isAbsolute(String path) {
  if (path.startsWith('/')) return true;
  if (!Platform.isWindows) return false;
  if (path.startsWith(r'\\')) return true;
  return RegExp(r'^[A-Za-z]:[\\/]').hasMatch(path);
}

bool _strictlyInside(String parent, String child) {
  final sep = Platform.pathSeparator;
  final prefix = parent.endsWith(sep) ? parent : '$parent$sep';
  if (Platform.isMacOS || Platform.isWindows) {
    return child.toLowerCase().startsWith(prefix.toLowerCase());
  }
  return child.startsWith(prefix);
}
