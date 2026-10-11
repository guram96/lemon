import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:rs_core/rs_core.dart';
import 'package:uuid/uuid.dart';

import '../fs/fs_errors.dart';
import 'data_dir.dart';
import 'marker.dart';

/// Result of [LibraryRoots.register].
class RootRegistration {
  const RootRegistration({
    required this.id,
    required this.label,
    required this.path,
    required this.status,
    required this.markerWritten,
    required this.adopted,
  });

  final String id;
  final String label;

  /// Normalized absolute path. Store it as the root's `last_path`.
  final String path;
  final LibraryRootStatus status;

  /// `false` on read-only roots: they are identified by stored id + last path.
  final bool markerWritten;

  /// An existing library marker was found and its id reused.
  final bool adopted;
}

/// Result of [LibraryRoots.locate].
class RootLocation {
  const RootLocation({required this.status, this.path});

  final LibraryRootStatus status;

  /// Where the root is now; `null` when [status] is offline. May differ from
  /// the stored last path when the drive was mounted elsewhere.
  final String? path;
}

/// Library root identity: marker files, registration and finding roots again
/// after a drive is unplugged, re-mounted or moved to another machine.
class LibraryRoots {
  const LibraryRoots({this._clock});

  final DateTime Function()? _clock;

  DateTime _now() => (_clock ?? DateTime.now)().toUtc();

  /// Registers [dirPath] as a library root.
  ///
  /// - Existing library marker → its id is reused ([RootRegistration.adopted]).
  /// - Writable → a new marker is written, status online.
  /// - Read-only mount → no marker can be written; a fresh id is returned with
  ///   status readOnly, and the root is found again by id + last path.
  ///
  /// Throws [StorageException] if the folder is a data directory, and
  /// [FsAccessException] if it is missing, not a folder or unreadable.
  Future<RootRegistration> register(String dirPath, {String? label}) async {
    final path = p.normalize(p.absolute(dirPath));
    await _requireReadableDir(path);
    final existing = await MarkerStore.read(path);
    if (existing != null && existing.kind != MarkerKind.library) {
      throw StorageException(
        'The folder is a Retro Steam data folder, not a game library.',
        path: path,
      );
    }
    final write = await probeWritable(path);
    final status = write.writable
        ? LibraryRootStatus.online
        : LibraryRootStatus.readOnly;
    if (existing != null) {
      return RootRegistration(
        id: existing.id,
        label: label ?? existing.label,
        path: path,
        status: status,
        markerWritten: true,
        adopted: true,
      );
    }
    final marker = RootMarker(
      id: const Uuid().v4(),
      kind: MarkerKind.library,
      label: label ?? defaultLabel(path),
      createdAt: _now(),
    );
    var written = false;
    if (write.writable) {
      try {
        await MarkerStore.write(path, marker);
        written = true;
      } on FileSystemException {
        written = false;
      }
    }
    return RootRegistration(
      id: marker.id,
      label: marker.label,
      path: path,
      status: written ? LibraryRootStatus.online : LibraryRootStatus.readOnly,
      markerWritten: written,
      adopted: false,
    );
  }

  /// Finds root [id] again and reports its status.
  ///
  /// 1. At [lastPath]: a marker with [id] → online/readOnly by writability.
  ///    No marker but the folder is readable → it is the same root identified
  ///    by last path (read-only roots never get a marker). If it is writable
  ///    now (for example NTFS re-mounted read-write), the marker is written.
  ///    A marker with a *different* id means another drive is mounted there.
  /// 2. Otherwise each folder in [searchDirs] and its direct children are
  ///    checked for a marker with [id] (drive mounted under a new name).
  /// 3. Not found → offline. Its games stay in the catalog.
  Future<RootLocation> locate(
    String id,
    String lastPath, {
    String label = '',
    List<String> searchDirs = const [],
  }) async {
    final path = p.normalize(p.absolute(lastPath));
    if (await FileSystemEntity.isDirectory(path)) {
      final marker = await MarkerStore.read(path);
      if (marker != null && marker.id == id) {
        return RootLocation(status: await _statusOf(path), path: path);
      }
      if (marker == null && await _canList(path)) {
        final write = await probeWritable(path);
        if (!write.writable) {
          return RootLocation(status: LibraryRootStatus.readOnly, path: path);
        }
        try {
          await MarkerStore.write(
            path,
            RootMarker(
              id: id,
              kind: MarkerKind.library,
              label: label.isEmpty ? defaultLabel(path) : label,
              createdAt: _now(),
            ),
          );
        } on FileSystemException {
          return RootLocation(status: LibraryRootStatus.readOnly, path: path);
        }
        return RootLocation(status: LibraryRootStatus.online, path: path);
      }
    }
    for (final candidate in await _candidates(searchDirs)) {
      if (p.equals(candidate, path)) continue;
      final marker = await MarkerStore.read(candidate);
      if (marker != null &&
          marker.id == id &&
          marker.kind == MarkerKind.library) {
        return RootLocation(
          status: await _statusOf(candidate),
          path: candidate,
        );
      }
    }
    return const RootLocation(status: LibraryRootStatus.offline);
  }

  /// Folder name, or the path for a drive root.
  static String defaultLabel(String path) {
    final name = p.basename(path);
    return name.isEmpty || name == p.rootPrefix(path) ? path : name;
  }

  Future<LibraryRootStatus> _statusOf(String path) async {
    final write = await probeWritable(path);
    return write.writable
        ? LibraryRootStatus.online
        : LibraryRootStatus.readOnly;
  }

  static Future<List<String>> _candidates(List<String> searchDirs) async {
    final result = <String>[];
    for (final dir in searchDirs) {
      if (!await FileSystemEntity.isDirectory(dir)) continue;
      result.add(p.normalize(dir));
      try {
        await for (final e in Directory(dir).list()) {
          if (e is Directory && !p.basename(e.path).startsWith('.')) {
            result.add(p.normalize(e.path));
          }
        }
      } on FileSystemException {
        continue;
      }
    }
    return result;
  }

  static Future<bool> _canList(String path) async {
    try {
      await Directory(path).list().take(1).drain<void>();
      return true;
    } on FileSystemException {
      return false;
    }
  }

  static Future<void> _requireReadableDir(String path) async {
    final type = await FileSystemEntity.type(path);
    if (type == FileSystemEntityType.notFound) {
      throw FsAccessException(FsErrorKind.notFound, path);
    }
    if (type != FileSystemEntityType.directory) {
      throw FsAccessException(FsErrorKind.notADirectory, path);
    }
    try {
      await Directory(path).list().take(1).drain<void>();
    } on FileSystemException catch (e) {
      throw FsAccessException(classifyFsError(e), path, e.message);
    }
  }
}
