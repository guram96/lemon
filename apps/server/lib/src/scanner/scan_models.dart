/// Result and progress types produced by the ROM scanner.
///
/// All relative paths (`relPath`, `primaryRelPath`) are relative to the
/// library root and always use `/` as the separator, on every OS.
library;

/// One file that belongs to a scanned game unit.
///
/// This is also the record the caller persists and later hands back through
/// [ScanIndex] so unchanged files are not hashed again.
class ScannedFile {
  const ScannedFile({
    required this.relPath,
    required this.size,
    required this.modified,
    this.crc32,
    this.md5,
    this.sha1,
    this.partialHash = false,
  });

  /// Path relative to the library root, `/`-separated (`psx/Game/Game.cue`).
  final String relPath;

  /// Size in bytes at scan time.
  final int size;

  /// Last modification time at scan time (UTC).
  final DateTime modified;

  /// Lowercase hex CRC32 (8 chars). Null when the file could not be read.
  final String? crc32;

  /// Lowercase hex MD5. Null when the file could not be read.
  final String? md5;

  /// Lowercase hex SHA1. Null when the file could not be read.
  final String? sha1;

  /// True when the file was larger than the partial-hash threshold and the
  /// hashes cover only `first chunk + last chunk + size` (see `hashing.dart`).
  final bool partialHash;

  bool get hasHashes => crc32 != null && md5 != null && sha1 != null;

  @override
  String toString() => 'ScannedFile($relPath, $size bytes)';
}

/// Stable identity of a game for diffing between scans:
/// (root id, system id, primary file rel path).
class GameKey {
  const GameKey(this.rootId, this.systemId, this.primaryRelPath);

  final String rootId;
  final String systemId;
  final String primaryRelPath;

  @override
  bool operator ==(Object other) =>
      other is GameKey &&
      other.rootId == rootId &&
      other.systemId == systemId &&
      other.primaryRelPath == primaryRelPath;

  @override
  int get hashCode => Object.hash(rootId, systemId, primaryRelPath);

  @override
  String toString() => '$rootId:$systemId:$primaryRelPath';
}

/// One game unit found on disk: a single ROM, a `.cue` + its tracks,
/// a `.gdi` + its tracks, an `.m3u` + its discs, a `(Disc N)` set, or a
/// directory game such as `Game.ps3/`.
class ScannedGame {
  const ScannedGame({
    required this.rootId,
    required this.systemId,
    required this.primaryRelPath,
    required this.title,
    required this.files,
    this.region,
    this.discCount = 1,
    this.isDirectory = false,
  });

  final String rootId;

  /// EmulationStation system id (`snes`, `psx`, …), always lowercase.
  final String systemId;

  /// Rel path of the file the emulator opens (the `.m3u`, `.cue`, `.gdi`,
  /// disc 1, or the ROM itself). For directory games, the directory path.
  final String primaryRelPath;

  /// Cleaned display title (tags and extension stripped).
  final String title;

  /// Region parsed from tags, e.g. `USA` or `USA, Europe`. Null if none.
  final String? region;

  /// All files of the unit, primary first (directory games: sorted).
  final List<ScannedFile> files;

  /// Number of discs in the unit (1 for cartridges).
  final int discCount;

  /// True for directory-based games (`Game.ps3/`).
  final bool isDirectory;

  GameKey get key => GameKey(rootId, systemId, primaryRelPath);

  int get totalSize => files.fold(0, (sum, f) => sum + f.size);

  @override
  String toString() => 'ScannedGame($systemId, $primaryRelPath, "$title")';
}

/// Previous scan results, used to skip re-hashing files whose size and
/// modification time did not change.
class ScanIndex {
  ScanIndex(Iterable<ScannedFile> files) {
    for (final f in files) {
      _exact[f.relPath] = f;
      _folded.putIfAbsent(f.relPath.toLowerCase(), () => f);
    }
  }

  /// An empty index: everything is hashed.
  ScanIndex.empty();

  final Map<String, ScannedFile> _exact = {};
  final Map<String, ScannedFile> _folded = {};

  int get length => _exact.length;

  /// Looks up a file by rel path. Falls back to a case-insensitive match so
  /// a case-only rename on a case-insensitive filesystem still hits.
  ScannedFile? lookup(String relPath) =>
      _exact[relPath] ?? _folded[relPath.toLowerCase()];

  /// The previous record for [relPath] if it can be reused as-is:
  /// same size, same mtime (millisecond precision) and complete hashes.
  ScannedFile? reusable(String relPath, int size, DateTime modified) {
    final prev = lookup(relPath);
    if (prev == null || !prev.hasHashes) return null;
    if (prev.size != size) return null;
    if (prev.modified.millisecondsSinceEpoch !=
        modified.millisecondsSinceEpoch) {
      return null;
    }
    return prev;
  }
}

enum ScannerPhase {
  /// Walking system folders and grouping files into game units.
  discovering,

  /// Hashing files (or reusing previous hashes).
  hashing,

  /// Finished successfully. Last event of the stream.
  done,

  /// Cancelled by the caller. Last event of the stream.
  cancelled,

  /// Failed (for example the root is missing). Last event of the stream.
  failed,
}

/// A progress snapshot. Events are throttled (see
/// `ScannerOptions.progressInterval`); phase changes are always emitted.
class ScanProgress {
  const ScanProgress({
    required this.phase,
    required this.processed,
    required this.total,
    this.processedBytes = 0,
    this.totalBytes = 0,
    this.gamesFound = 0,
    this.warningCount = 0,
    this.currentSystemId,
    this.currentFile,
  });

  final ScannerPhase phase;

  /// Discovering: system folders walked. Hashing and later: files processed.
  final int processed;

  /// Discovering: system folders to walk. Hashing and later: files total.
  final int total;

  /// Bytes hashed or reused so far (hashing phase).
  final int processedBytes;

  /// Total bytes of all files of all units (known after discovery).
  final int totalBytes;

  /// Discovering: units found so far. Hashing: games completed so far.
  final int gamesFound;

  final int warningCount;

  /// System currently being walked or hashed.
  final String? currentSystemId;

  /// Rel path of the file currently being processed (hashing phase).
  final String? currentFile;

  /// 0..1, or null when the total is still unknown.
  double? get fraction {
    if (phase == ScannerPhase.done) return 1;
    if (phase == ScannerPhase.hashing && totalBytes > 0) {
      return processedBytes / totalBytes;
    }
    if (total <= 0) return null;
    return processed / total;
  }

  bool get isFinal =>
      phase == ScannerPhase.done ||
      phase == ScannerPhase.cancelled ||
      phase == ScannerPhase.failed;

  @override
  String toString() =>
      'ScanProgress(${phase.name} $processed/$total, '
      '$currentSystemId, $currentFile)';
}

enum ScanWarningKind {
  /// A directory could not be listed (permissions, unplugged drive).
  unreadableDirectory,

  /// A file could not be stat'ed or read; the game is kept without hashes.
  unreadableFile,

  /// A `.cue`/`.gdi`/`.m3u` references a file that does not exist.
  missingReference,

  /// A `.cue`/`.gdi`/`.m3u` references a path outside its system folder.
  invalidReference,

  /// Symbolic links are not followed.
  skippedLink,

  /// Directory nesting deeper than `ScannerOptions.maxDepth`.
  tooDeep,
}

/// A non-fatal problem found during a scan.
class ScanWarning {
  const ScanWarning(this.kind, this.relPath, this.message);

  final ScanWarningKind kind;

  /// Rel path (from the root, `/`-separated) the warning is about.
  final String relPath;
  final String message;

  @override
  String toString() => 'ScanWarning(${kind.name}, $relPath: $message)';
}

/// Final result of a completed (not cancelled) scan.
///
/// [games] is the complete set of games in the root for the scanned systems,
/// so the caller can diff it against the catalog by [GameKey].
class ScanResult {
  const ScanResult({
    required this.rootId,
    required this.systemIds,
    required this.games,
    required this.warnings,
    required this.filesHashed,
    required this.filesReused,
    required this.bytesHashed,
    required this.elapsed,
  });

  final String rootId;

  /// System folders that were found and walked (lowercase ES ids).
  final Set<String> systemIds;
  final List<ScannedGame> games;
  final List<ScanWarning> warnings;
  final int filesHashed;
  final int filesReused;
  final int bytesHashed;
  final Duration elapsed;
}

/// Thrown by `ScanJob.result` when the scan was cancelled. A cancelled scan
/// must never be used to remove games from the catalog.
class ScanCancelledException implements Exception {
  const ScanCancelledException();

  @override
  String toString() => 'ScanCancelledException';
}

/// Thrown by `ScanJob.result` for fatal errors (root missing or unreadable).
class ScanException implements Exception {
  const ScanException(this.message);

  final String message;

  @override
  String toString() => 'ScanException: $message';
}
