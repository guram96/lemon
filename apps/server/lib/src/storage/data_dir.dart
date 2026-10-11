import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import 'marker.dart';

class StorageException implements Exception {
  const StorageException(this.message, {this.path});

  final String message;
  final String? path;

  @override
  String toString() =>
      'StorageException: $message${path == null ? '' : ' ($path)'}';
}

/// The server's data directory: database, processed artwork, caches.
///
/// ```
/// <data>/
///   .retrosteam/root.json   marker {id, kind: data, label, createdAt}
///   retrosteam.db           SQLite catalog (+ -wal / -shm while running)
///   artwork/                processed artwork
///   cache/                  disposable caches
///   tmp/                    in-progress uploads/downloads, cleared on start
/// ```
///
/// It can live on any drive. A data directory found with an existing marker
/// is adopted as-is (same [id], existing database).
class DataDir {
  DataDir._(this.path, this.marker, {required this.adopted});

  static const dbFileName = 'retrosteam.db';
  static const artworkDirName = 'artwork';
  static const cacheDirName = 'cache';
  static const tmpDirName = 'tmp';

  /// Normalized absolute path.
  final String path;
  final RootMarker marker;

  /// `true` when an existing data directory (marker present) was opened.
  final bool adopted;

  String get id => marker.id;
  String get dbPath => p.join(path, dbFileName);
  String get artworkDir => p.join(path, artworkDirName);
  String get cacheDir => p.join(path, cacheDirName);
  String get tmpDir => p.join(path, tmpDirName);

  /// Whether [dbPath] exists.
  bool get hasDatabase => File(dbPath).existsSync();

  /// Opens the data directory at [dirPath], creating the folder, layout and
  /// marker if needed. An existing data marker is adopted.
  ///
  /// Throws [StorageException] if the folder is a library root, and
  /// [FileSystemException] if it can't be created or written.
  static Future<DataDir> openOrCreate(
    String dirPath, {
    String label = 'Retro Steam data',
    DateTime Function() clock = _now,
  }) async {
    final path = p.normalize(p.absolute(dirPath));
    await Directory(path).create(recursive: true);
    var marker = await MarkerStore.read(path);
    final adopted = marker != null;
    if (marker != null && marker.kind != MarkerKind.data) {
      throw StorageException(
        'The folder is a Retro Steam game library, not a data folder.',
        path: path,
      );
    }
    if (marker == null) {
      marker = RootMarker(
        id: const Uuid().v4(),
        kind: MarkerKind.data,
        label: label,
        createdAt: clock().toUtc(),
      );
      await MarkerStore.write(path, marker);
    }
    final dir = DataDir._(path, marker, adopted: adopted);
    await dir.ensureLayout();
    return dir;
  }

  /// Opens an existing data directory without creating anything.
  ///
  /// Throws [StorageException] if there is no data marker. When
  /// [expectedId] is given, the marker must match it (guards against a
  /// different drive mounted at the same path).
  static Future<DataDir> open(String dirPath, {String? expectedId}) async {
    final path = p.normalize(p.absolute(dirPath));
    final marker = await MarkerStore.read(path);
    if (marker == null || marker.kind != MarkerKind.data) {
      throw StorageException('No Retro Steam data folder found.', path: path);
    }
    if (expectedId != null && marker.id != expectedId) {
      throw StorageException(
        'A different Retro Steam data folder was found at this path.',
        path: path,
      );
    }
    final dir = DataDir._(path, marker, adopted: true);
    await dir.ensureLayout();
    return dir;
  }

  /// Creates the sub-folders if missing.
  Future<void> ensureLayout() async {
    for (final d in [artworkDir, cacheDir, tmpDir]) {
      await Directory(d).create(recursive: true);
    }
  }

  /// Deletes leftovers in [tmpDir] (interrupted uploads). Call at startup.
  Future<void> clearTmp() async {
    final tmp = Directory(tmpDir);
    if (await tmp.exists()) await tmp.delete(recursive: true);
    await tmp.create(recursive: true);
  }

  static DateTime _now() => DateTime.now();
}
