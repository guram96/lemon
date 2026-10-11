import 'package:flutter/foundation.dart';

/// Where a download is in its life on this device.
enum InstallPhase { queued, downloading, paused, installed, failed }

/// Where this device puts installed games.
///
/// [globalFolder] and every per-system folder are absolute path strings.
/// Nothing is set until the user picks a folder.
@immutable
class InstallDestination {
  InstallDestination({
    this.globalFolder,
    Map<String, String> foldersBySystem = const {},
  }) : foldersBySystem = Map.unmodifiable(
         Map<String, String>.of(foldersBySystem),
       );

  /// Used for every system that has no entry in [foldersBySystem].
  final String? globalFolder;

  /// Absolute folder keyed by EmulationStation system id (`snes`, `psx`, …).
  final Map<String, String> foldersBySystem;

  /// Per-system override, otherwise [globalFolder], otherwise null.
  String? folderFor(String systemId) =>
      foldersBySystem[systemId] ?? globalFolder;

  InstallDestination withGlobalFolder(String? folder) => InstallDestination(
    globalFolder: folder,
    foldersBySystem: foldersBySystem,
  );

  /// Sets the folder for [systemId]. A null [folder] clears the override.
  InstallDestination withSystemFolder(String systemId, String? folder) {
    final next = Map<String, String>.of(foldersBySystem);
    if (folder == null) {
      next.remove(systemId);
    } else {
      next[systemId] = folder;
    }
    return InstallDestination(
      globalFolder: globalFolder,
      foldersBySystem: next,
    );
  }

  Map<String, Object?> toJson() => {
    'globalFolder': globalFolder,
    'foldersBySystem': foldersBySystem,
  };

  factory InstallDestination.fromJson(Map<String, Object?> json) {
    final raw = json['foldersBySystem'];
    final folders = <String, String>{};
    if (raw != null) {
      if (raw is! Map) {
        throw const FormatException(
          'install destinations foldersBySystem is not an object',
        );
      }
      for (final entry in raw.entries) {
        final key = entry.key;
        final value = entry.value;
        if (key is! String || value is! String) {
          throw const FormatException(
            'install destinations foldersBySystem has a non-string entry',
          );
        }
        folders[key] = value;
      }
    }
    final global = json['globalFolder'];
    if (global is! String?) {
      throw const FormatException(
        'install destinations globalFolder is not a string',
      );
    }
    return InstallDestination(globalFolder: global, foldersBySystem: folders);
  }

  @override
  bool operator ==(Object other) =>
      other is InstallDestination &&
      other.globalFolder == globalFolder &&
      mapEquals(other.foldersBySystem, foldersBySystem);

  @override
  int get hashCode => Object.hash(globalFolder, _mapHash(foldersBySystem));

  @override
  String toString() =>
      'InstallDestination(global: $globalFolder, bySystem: $foldersBySystem)';
}

/// Download progress for one file of a game.
///
/// [path] is relative to the system folder, with `/` separators, the same
/// shape as `GameFile.path`.
@immutable
class InstallFileProgress {
  const InstallFileProgress({
    required this.index,
    required this.path,
    required this.receivedBytes,
    required this.sizeBytes,
    required this.complete,
  });

  final int index;
  final String path;
  final int receivedBytes;
  final int sizeBytes;
  final bool complete;

  InstallFileProgress copyWith({
    int? index,
    String? path,
    int? receivedBytes,
    int? sizeBytes,
    bool? complete,
  }) => InstallFileProgress(
    index: index ?? this.index,
    path: path ?? this.path,
    receivedBytes: receivedBytes ?? this.receivedBytes,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    complete: complete ?? this.complete,
  );

  Map<String, Object?> toJson() => {
    'index': index,
    'path': path,
    'receivedBytes': receivedBytes,
    'sizeBytes': sizeBytes,
    'complete': complete,
  };

  factory InstallFileProgress.fromJson(Map<String, Object?> json) =>
      InstallFileProgress(
        index: _requireInt(json, 'index'),
        path: _requireString(json, 'path'),
        receivedBytes: _requireInt(json, 'receivedBytes'),
        sizeBytes: _requireInt(json, 'sizeBytes'),
        complete: _requireBool(json, 'complete'),
      );

  @override
  bool operator ==(Object other) =>
      other is InstallFileProgress &&
      other.index == index &&
      other.path == path &&
      other.receivedBytes == receivedBytes &&
      other.sizeBytes == sizeBytes &&
      other.complete == complete;

  @override
  int get hashCode =>
      Object.hash(index, path, receivedBytes, sizeBytes, complete);

  @override
  String toString() =>
      'InstallFileProgress($index $path $receivedBytes/$sizeBytes '
      'complete: $complete)';
}

/// One game's install on this device.
///
/// Identity is [serverId] plus [gameId]. The install store replaces a record
/// with the same pair.
@immutable
class InstallRecord {
  InstallRecord({
    required this.serverId,
    required this.gameId,
    required this.systemId,
    required this.phase,
    required this.receivedBytes,
    required this.totalBytes,
    this.error,
    List<InstallFileProgress> files = const [],
  }) : files = List.unmodifiable(files);

  final String serverId;
  final String gameId;

  /// EmulationStation system id. Joined under the destination folder.
  final String systemId;
  final InstallPhase phase;
  final int receivedBytes;
  final int totalBytes;
  final String? error;
  final List<InstallFileProgress> files;

  (String, String) get identity => (serverId, gameId);

  InstallRecord copyWith({
    String? serverId,
    String? gameId,
    String? systemId,
    InstallPhase? phase,
    int? receivedBytes,
    int? totalBytes,
    Object? error = _keep,
    List<InstallFileProgress>? files,
  }) => InstallRecord(
    serverId: serverId ?? this.serverId,
    gameId: gameId ?? this.gameId,
    systemId: systemId ?? this.systemId,
    phase: phase ?? this.phase,
    receivedBytes: receivedBytes ?? this.receivedBytes,
    totalBytes: totalBytes ?? this.totalBytes,
    error: identical(error, _keep) ? this.error : error as String?,
    files: files ?? this.files,
  );

  Map<String, Object?> toJson() => {
    'serverId': serverId,
    'gameId': gameId,
    'systemId': systemId,
    'phase': phase.name,
    'receivedBytes': receivedBytes,
    'totalBytes': totalBytes,
    'error': error,
    'files': [for (final file in files) file.toJson()],
  };

  factory InstallRecord.fromJson(Map<String, Object?> json) {
    final phase = _phase(_requireString(json, 'phase'));
    final error = json['error'];
    if (error is! String?) {
      throw const FormatException('install record error is not a string');
    }
    final rawFiles = json['files'];
    final files = <InstallFileProgress>[];
    if (rawFiles != null) {
      if (rawFiles is! List) {
        throw const FormatException('install record files is not a list');
      }
      for (final item in rawFiles) {
        if (item is! Map) {
          throw const FormatException('install record file is not an object');
        }
        files.add(
          InstallFileProgress.fromJson(Map<String, Object?>.from(item)),
        );
      }
    }
    return InstallRecord(
      serverId: _requireString(json, 'serverId'),
      gameId: _requireString(json, 'gameId'),
      systemId: _requireString(json, 'systemId'),
      phase: phase,
      receivedBytes: _requireInt(json, 'receivedBytes'),
      totalBytes: _requireInt(json, 'totalBytes'),
      error: error,
      files: files,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is InstallRecord &&
      other.serverId == serverId &&
      other.gameId == gameId &&
      other.systemId == systemId &&
      other.phase == phase &&
      other.receivedBytes == receivedBytes &&
      other.totalBytes == totalBytes &&
      other.error == error &&
      listEquals(other.files, files);

  @override
  int get hashCode => Object.hash(
    serverId,
    gameId,
    systemId,
    phase,
    receivedBytes,
    totalBytes,
    error,
    Object.hashAll(files),
  );

  @override
  String toString() =>
      'InstallRecord($serverId/$gameId $systemId ${phase.name} '
      '$receivedBytes/$totalBytes files: ${files.length})';
}

const _keep = Object();

int _mapHash(Map<String, String> map) {
  final keys = map.keys.toList()..sort();
  return Object.hashAll([for (final key in keys) Object.hash(key, map[key])]);
}

InstallPhase _phase(String name) {
  for (final phase in InstallPhase.values) {
    if (phase.name == name) return phase;
  }
  throw FormatException('unknown install phase "$name"');
}

String _requireString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String) {
    throw FormatException('install store field $key is not a string');
  }
  return value;
}

int _requireInt(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! int) {
    throw FormatException('install store field $key is not an int');
  }
  return value;
}

bool _requireBool(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! bool) {
    throw FormatException('install store field $key is not a bool');
  }
  return value;
}
