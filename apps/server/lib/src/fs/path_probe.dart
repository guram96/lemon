import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:rs_core/rs_core.dart';

import '../storage/marker.dart';
import 'fs_errors.dart';
import 'path_guard.dart';

/// What a probed path is meant to become.
enum ProbeKind { dataDir, libraryRoot }

/// Non-fatal findings, shown to the admin during setup.
enum PathWarning {
  readOnlyFilesystem('The drive is mounted read-only.'),
  notWritable('Retro Steam cannot write to this folder.'),
  permissionDenied(
    'The operating system denied access to this folder. Grant the server '
    'access (on macOS: System Settings › Privacy & Security › Full Disk '
    'Access or Files and Folders).',
  ),
  notEmpty('The folder is not empty and is not a Retro Steam data folder.'),
  willBeCreated('The folder does not exist yet and will be created.'),
  noSystemsDetected(
    'No system folders found. Use EmulationStation folder names such as '
    '"snes" or "psx".',
  ),
  markerKindMismatch(
    'This folder is already used by Retro Steam for something else '
    '(a data folder vs. a game library).',
  ),
  notADirectory('The path is a file, not a folder.'),
  notFound('The folder does not exist.');

  const PathWarning(this.message);

  /// English, human-readable text.
  final String message;
}

/// One EmulationStation system folder found in a library root.
class DetectedSystemCount {
  const DetectedSystemCount({required this.systemId, required this.fileCount});

  final String systemId;

  /// Files with an extension accepted by the system (not game units: a
  /// `.cue` and its `.bin` count as two).
  final int fileCount;

  @override
  String toString() => 'DetectedSystemCount($systemId, $fileCount)';
}

/// Result of [PathProbe.check]. Fields mirror the API's `PathCheckResult`.
class PathProbeResult {
  const PathProbeResult({
    required this.path,
    required this.kind,
    required this.exists,
    required this.readable,
    required this.writable,
    required this.permissionDenied,
    required this.readOnlyFilesystem,
    required this.creatable,
    this.existingMarkerId,
    this.existingMarkerKind,
    this.detectedSystems = const [],
    this.freeBytes,
    this.warnings = const [],
  });

  /// Normalized absolute path.
  final String path;
  final ProbeKind kind;
  final bool exists;
  final bool readable;

  /// For a missing path: whether it could be created (nearest existing parent
  /// is writable).
  final bool writable;
  final bool permissionDenied;
  final bool readOnlyFilesystem;

  /// The path doesn't exist but its nearest existing parent is writable.
  final bool creatable;
  final String? existingMarkerId;
  final MarkerKind? existingMarkerKind;
  final List<DetectedSystemCount> detectedSystems;
  final int? freeBytes;
  final List<PathWarning> warnings;

  bool get ok => switch (kind) {
    ProbeKind.dataDir =>
      (exists || creatable) &&
          writable &&
          !permissionDenied &&
          existingMarkerKind != MarkerKind.library,
    ProbeKind.libraryRoot =>
      exists &&
          readable &&
          !permissionDenied &&
          existingMarkerKind != MarkerKind.data,
  };
}

/// Inspects a folder picked during setup or in settings: existence, access,
/// read-only mounts, an existing Retro Steam marker, free space, and (for
/// library roots) which EmulationStation system folders it contains.
///
/// Never throws for filesystem problems; they become flags and [PathWarning]s.
class PathProbe {
  const PathProbe({this.homeDir, this.freeSpace = queryFreeBytes});

  final String? homeDir;

  /// Free-space lookup, injectable for tests.
  final Future<int?> Function(String path) freeSpace;

  /// Folders skipped while counting ROMs (ES media folders and our own).
  static const ignoredDirs = {
    MarkerStore.dirName,
    'media',
    'images',
    'videos',
    'manuals',
    'downloaded_media',
  };

  /// How deep into a system folder ROMs are counted (a sub-folder per game).
  static const maxCountDepth = 3;

  /// Throws [PathGuardException] if [input] is not a syntactically valid
  /// absolute path.
  Future<PathProbeResult> check(String input, ProbeKind kind) async {
    final path = PathGuard.normalizeAbsolute(input, homeDir: homeDir);
    final warnings = <PathWarning>[];
    final type = await FileSystemEntity.type(path);

    if (type == FileSystemEntityType.notFound) {
      return _checkMissing(path, kind, warnings);
    }
    if (type != FileSystemEntityType.directory) {
      return PathProbeResult(
        path: path,
        kind: kind,
        exists: true,
        readable: false,
        writable: false,
        permissionDenied: false,
        readOnlyFilesystem: false,
        creatable: false,
        warnings: const [PathWarning.notADirectory],
      );
    }

    // Readability: actually list the folder. On macOS, privacy protection
    // (TCC) lets `stat` succeed but fails the listing with EPERM.
    var readable = true;
    var permissionDenied = false;
    final children = <FileSystemEntity>[];
    try {
      await for (final e in Directory(path).list(followLinks: false)) {
        children.add(e);
      }
    } on FileSystemException catch (e) {
      readable = false;
      permissionDenied = classifyFsError(e) == FsErrorKind.permissionDenied;
    }

    final write = await probeWritable(path);
    permissionDenied =
        permissionDenied || (!readable && write.permissionDenied);
    if (permissionDenied) warnings.add(PathWarning.permissionDenied);
    if (write.readOnlyFilesystem) {
      warnings.add(PathWarning.readOnlyFilesystem);
    } else if (!write.writable && !permissionDenied) {
      warnings.add(PathWarning.notWritable);
    }

    final marker = readable ? await MarkerStore.read(path) : null;
    final expectedKind = kind == ProbeKind.dataDir
        ? MarkerKind.data
        : MarkerKind.library;
    if (marker != null && marker.kind != expectedKind) {
      warnings.add(PathWarning.markerKindMismatch);
    }

    var detected = const <DetectedSystemCount>[];
    if (kind == ProbeKind.libraryRoot && readable) {
      detected = await detectSystems(path, children: children);
      if (detected.isEmpty) warnings.add(PathWarning.noSystemsDetected);
    }
    if (kind == ProbeKind.dataDir &&
        readable &&
        marker == null &&
        children.any((e) => !_isHidden(p.basename(e.path)))) {
      warnings.add(PathWarning.notEmpty);
    }

    return PathProbeResult(
      path: path,
      kind: kind,
      exists: true,
      readable: readable,
      writable: write.writable,
      permissionDenied: permissionDenied,
      readOnlyFilesystem: write.readOnlyFilesystem,
      creatable: false,
      existingMarkerId: marker?.id,
      existingMarkerKind: marker?.kind,
      detectedSystems: detected,
      freeBytes: await freeSpace(path),
      warnings: warnings,
    );
  }

  Future<PathProbeResult> _checkMissing(
    String path,
    ProbeKind kind,
    List<PathWarning> warnings,
  ) async {
    if (kind == ProbeKind.libraryRoot) {
      return PathProbeResult(
        path: path,
        kind: kind,
        exists: false,
        readable: false,
        writable: false,
        permissionDenied: false,
        readOnlyFilesystem: false,
        creatable: false,
        warnings: const [PathWarning.notFound],
      );
    }
    // Data dir: fine if it can be created. Find the nearest existing parent.
    var parent = p.dirname(path);
    while (await FileSystemEntity.type(parent) ==
        FileSystemEntityType.notFound) {
      final next = p.dirname(parent);
      if (next == parent) break;
      parent = next;
    }
    final isDir = await FileSystemEntity.isDirectory(parent);
    final write = isDir
        ? await probeWritable(parent)
        : const WriteProbeResult(writable: false);
    if (write.permissionDenied) warnings.add(PathWarning.permissionDenied);
    if (write.readOnlyFilesystem) warnings.add(PathWarning.readOnlyFilesystem);
    if (write.writable) {
      warnings.add(PathWarning.willBeCreated);
    } else if (!write.permissionDenied && !write.readOnlyFilesystem) {
      warnings.add(PathWarning.notWritable);
    }
    return PathProbeResult(
      path: path,
      kind: kind,
      exists: false,
      readable: false,
      writable: write.writable,
      permissionDenied: write.permissionDenied,
      readOnlyFilesystem: write.readOnlyFilesystem,
      creatable: write.writable,
      freeBytes: isDir ? await freeSpace(parent) : null,
      warnings: warnings,
    );
  }

  /// Finds EmulationStation system folders directly inside [rootPath] and
  /// counts the files each one accepts. Folder names match case-insensitively.
  static Future<List<DetectedSystemCount>> detectSystems(
    String rootPath, {
    List<FileSystemEntity>? children,
  }) async {
    final byId = {for (final s in GameSystems.all) s.id: s};
    final entries =
        children ?? await Directory(rootPath).list(followLinks: false).toList();
    final result = <DetectedSystemCount>[];
    for (final entry in entries) {
      final name = p.basename(entry.path);
      final system = byId[name.toLowerCase()];
      if (system == null) continue;
      if (!await FileSystemEntity.isDirectory(entry.path)) continue;
      final count = await _countFiles(entry.path, system, 0);
      result.add(DetectedSystemCount(systemId: system.id, fileCount: count));
    }
    result.sort((a, b) => a.systemId.compareTo(b.systemId));
    return result;
  }

  static Future<int> _countFiles(
    String dir,
    GameSystem system,
    int depth,
  ) async {
    var count = 0;
    try {
      await for (final e in Directory(dir).list(followLinks: false)) {
        final name = p.basename(e.path);
        if (_isHidden(name)) continue;
        if (e is Directory) {
          if (depth + 1 >= maxCountDepth) continue;
          if (ignoredDirs.contains(name.toLowerCase())) continue;
          count += await _countFiles(e.path, system, depth + 1);
        } else if (e is File && system.acceptsFile(name)) {
          count++;
        }
      }
    } on FileSystemException {
      // Unreadable sub-folder: count what we can.
    }
    return count;
  }

  static bool _isHidden(String name) => name.startsWith('.');
}

/// Free bytes on the volume holding [path], or `null` if unknown.
///
/// Uses `df` on macOS/Linux and PowerShell on Windows; `dart:io` has no API.
Future<int?> queryFreeBytes(String path) async {
  try {
    if (Platform.isWindows) {
      final drive = p.rootPrefix(p.absolute(path));
      final escaped = drive.replaceAll("'", "''");
      final r = await Process.run('powershell', [
        '-NoProfile',
        '-NonInteractive',
        '-Command',
        "([System.IO.DriveInfo]::new('$escaped')).AvailableFreeSpace",
      ]);
      if (r.exitCode != 0) return null;
      return int.tryParse((r.stdout as String).trim());
    }
    final r = await Process.run('df', [
      '-kP',
      path,
    ], stdoutEncoding: const SystemEncoding());
    if (r.exitCode != 0) return null;
    final lines = const LineSplitter()
        .convert(r.stdout as String)
        .where((l) => l.trim().isNotEmpty)
        .toList();
    if (lines.length < 2) return null;
    return parseDfAvailable(lines.last);
  } on Object {
    return null;
  }
}

/// Parses the "Available" column (in KiB) of a `df -kP` data line into bytes.
///
/// Columns: Filesystem, 1024-blocks, Used, Available, Capacity, Mounted on.
/// Both the filesystem name and the mount point may contain spaces, so the
/// line is anchored on the `NN%` capacity column.
int? parseDfAvailable(String line) {
  final cols = line.trim().split(RegExp(r'\s+'));
  final capacity = cols.indexWhere((c) => RegExp(r'^\d+%$').hasMatch(c));
  if (capacity < 3) return null;
  final available = int.tryParse(cols[capacity - 1]);
  return available == null ? null : available * 1024;
}
