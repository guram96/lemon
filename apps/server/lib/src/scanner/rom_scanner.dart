/// The ROM scanner: walks a library root, groups game units, hashes files.
library;

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:rs_core/rs_core.dart';

import 'grouping.dart';
import 'hashing.dart';
import 'scan_models.dart';
import 'sheet_parser.dart';

/// EmulationStation media sub-folders that never contain ROMs.
const skippedFolderNames = {
  'media',
  'images',
  'videos',
  'manuals',
  'downloaded_media',
};

/// Tuning knobs for [Scanner].
class ScannerOptions {
  const ScannerOptions({
    this.hashWorkers,
    this.progressInterval = const Duration(milliseconds: 250),
    this.partialHashThreshold = defaultPartialHashThreshold,
    this.partialHashChunk = defaultPartialHashChunk,
    this.maxDepth = 8,
    this.maxSheetBytes = 1024 * 1024,
  });

  /// Hashing isolates. Null: half the CPUs, clamped to 1..4 (keeps spinning
  /// disks from thrashing while still using SSDs well).
  final int? hashWorkers;

  /// Minimum time between two progress events of the same phase.
  /// Phase changes and the final event are always emitted.
  final Duration progressInterval;

  /// Files larger than this get a partial hash (default 4 GiB).
  final int partialHashThreshold;

  /// Head/tail bytes used for partial hashes (default 64 MiB).
  final int partialHashChunk;

  /// Maximum folder depth below a system folder.
  final int maxDepth;

  /// `.cue`/`.gdi`/`.m3u` files larger than this are not parsed.
  final int maxSheetBytes;

  int get effectiveWorkers {
    final n = hashWorkers ?? (Platform.numberOfProcessors ~/ 2);
    return n.clamp(1, hashWorkers == null ? 4 : 64);
  }
}

/// Scans library roots. Stateless; one [Scanner] can run many scans.
class Scanner {
  const Scanner({this.options = const ScannerOptions()});

  final ScannerOptions options;

  /// Starts scanning [rootPath] (the absolute path of library root
  /// [rootId]). The scan begins asynchronously, so listeners attached right
  /// after this call see every event.
  ///
  /// [previous] holds the files known from the last scan; files with the same
  /// size and mtime are not hashed again. [systems] limits the scan to those
  /// systems (default: [GameSystems.all]).
  ScanJob scan({
    required String rootId,
    required String rootPath,
    ScanIndex? previous,
    Iterable<GameSystem>? systems,
  }) {
    final job = ScanJob._(
      rootId,
      rootPath,
      previous ?? ScanIndex.empty(),
      List.of(systems ?? GameSystems.all),
      options,
    );
    Timer.run(job._start);
    return job;
  }
}

/// A running scan.
class ScanJob {
  ScanJob._(
    this.rootId,
    this.rootPath,
    this._previous,
    this._systems,
    this._options,
  );

  final String rootId;
  final String rootPath;
  final ScanIndex _previous;
  final List<GameSystem> _systems;
  final ScannerOptions _options;

  final _progress = StreamController<ScanProgress>.broadcast();
  final _games = StreamController<ScannedGame>.broadcast();
  final _result = Completer<ScanResult>();
  final _stopwatch = Stopwatch();
  final _warnings = <ScanWarning>[];

  bool _cancelled = false;
  HashPool? _pool;

  ScannerPhase _phase = ScannerPhase.discovering;
  int _processed = 0;
  int _total = 0;
  int _processedBytes = 0;
  int _totalBytes = 0;
  int _gamesFound = 0;
  String? _currentSystem;
  String? _currentFile;
  ScannerPhase? _lastEmittedPhase;
  DateTime _lastEmit = DateTime.fromMillisecondsSinceEpoch(0);

  /// Throttled progress. Broadcast; closes after the final event
  /// ([ScannerPhase.done], [ScannerPhase.cancelled] or [ScannerPhase.failed]).
  Stream<ScanProgress> get progress => _progress.stream;

  /// Each game as soon as all its files are hashed, so the catalog can fill
  /// in live. Broadcast; closes when the scan ends.
  Stream<ScannedGame> get games => _games.stream;

  /// Completes with the full result, or fails with
  /// [ScanCancelledException] / [ScanException].
  Future<ScanResult> get result => _result.future;

  bool get isCancelled => _cancelled;

  /// Warnings collected so far.
  List<ScanWarning> get warnings => List.unmodifiable(_warnings);

  /// Stops the scan as soon as possible; hashing isolates are killed even in
  /// the middle of a large file.
  void cancel() {
    if (_cancelled || _result.isCompleted) return;
    _cancelled = true;
    _pool?.kill();
  }

  Future<void> _start() async {
    _stopwatch.start();
    ScanResult? result;
    Object? error;
    StackTrace? stack;
    try {
      result = await _run();
      if (_cancelled) throw const ScanCancelledException();
      _phase = ScannerPhase.done;
      _currentFile = null;
    } on ScanCancelledException catch (e, st) {
      _phase = ScannerPhase.cancelled;
      (error, stack) = (e, st);
    } on Object catch (e, st) {
      _phase = ScannerPhase.failed;
      (error, stack) = (e is ScanException ? e : ScanException('$e'), st);
    }
    _pool?.kill();
    _emit(force: true);
    // Deliver the final progress event and close both streams before the
    // result completes, so listeners see the full sequence first.
    await _progress.close();
    await _games.close();
    if (error != null) {
      _result.completeError(error, stack);
    } else {
      _result.complete(result);
    }
  }

  void _checkCancelled() {
    if (_cancelled) throw const ScanCancelledException();
  }

  void _warn(ScanWarning w) => _warnings.add(w);

  void _emit({bool force = false}) {
    if (_progress.isClosed) return;
    final now = DateTime.now();
    final phaseChanged = _phase != _lastEmittedPhase;
    if (!force &&
        !phaseChanged &&
        now.difference(_lastEmit) < _options.progressInterval) {
      return;
    }
    _lastEmit = now;
    _lastEmittedPhase = _phase;
    _progress.add(
      ScanProgress(
        phase: _phase,
        processed: _processed,
        total: _total,
        processedBytes: _processedBytes,
        totalBytes: _totalBytes,
        gamesFound: _gamesFound,
        warningCount: _warnings.length,
        currentSystemId: _currentSystem,
        currentFile: _currentFile,
      ),
    );
  }

  Future<ScanResult> _run() async {
    final root = Directory(rootPath);
    if (!await root.exists()) {
      throw ScanException('Library root not found: $rootPath');
    }

    // Find system folders (case-insensitive match on the ES id).
    final byId = {for (final s in _systems) s.id.toLowerCase(): s};
    final systemDirs = <(GameSystem, Directory, String)>[];
    try {
      await for (final e in root.list(followLinks: false)) {
        if (e is! Directory) continue;
        final name = p.basename(e.path);
        final system = byId[name.toLowerCase()];
        if (system != null) systemDirs.add((system, e, name));
      }
    } on FileSystemException catch (e) {
      throw ScanException('Cannot read library root $rootPath: ${_msg(e)}');
    }
    systemDirs.sort((a, b) => a.$3.compareTo(b.$3));

    // Phase 1: discover + group.
    _phase = ScannerPhase.discovering;
    _total = systemDirs.length;
    _emit(force: true);
    final units = <GameUnit>[];
    for (final (system, dir, name) in systemDirs) {
      _checkCancelled();
      _currentSystem = system.id;
      _emit();
      final files = <DiscoveredFile>[];
      final dirGames = <DiscoveredDirectory>[];
      await _walk(system, dir, name, 0, files, dirGames);
      _checkCancelled();
      units.addAll(
        groupGameUnits(
          system: system,
          systemDirRel: name,
          files: files,
          directoryGames: dirGames,
          onWarning: _warn,
        ),
      );
      _processed++;
      _gamesFound = units.length;
      _emit();
    }

    // Phase 2: hash.
    _phase = ScannerPhase.hashing;
    _processed = 0;
    _total = units.fold(0, (s, u) => s + u.files.length);
    _totalBytes = units.fold(0, (s, u) => s + u.totalSize);
    _gamesFound = 0;
    _emit(force: true);

    var filesHashed = 0;
    var filesReused = 0;
    var bytesHashed = 0;
    final games = List<ScannedGame?>.filled(units.length, null);
    final needsHashing = units.any(
      (u) => u.files.any(
        (f) => _previous.reusable(f.relPath, f.size, f.modified) == null,
      ),
    );
    final workers = _options.effectiveWorkers;
    if (needsHashing) {
      _pool = await HashPool.spawn(workers);
      if (_cancelled) _pool!.kill();
    }
    final slots = _Semaphore(workers * 2);
    final unitFutures = <Future<void>>[];

    for (var i = 0; i < units.length; i++) {
      _checkCancelled();
      final unit = units[i];
      final fileFutures = <Future<ScannedFile>>[];
      for (final f in unit.files) {
        final reused = _previous.reusable(f.relPath, f.size, f.modified);
        if (reused != null) {
          filesReused++;
          _fileDone(unit, f);
          fileFutures.add(
            Future.value(
              ScannedFile(
                relPath: f.relPath,
                size: f.size,
                modified: f.modified,
                crc32: reused.crc32,
                md5: reused.md5,
                sha1: reused.sha1,
                partialHash: reused.partialHash,
              ),
            ),
          );
          continue;
        }
        await slots.acquire();
        _checkCancelled();
        _currentSystem = unit.systemId;
        _currentFile = f.relPath;
        _emit();
        fileFutures.add(
          _hashOne(f)
              .then((scanned) {
                if (scanned.hasHashes && !_cancelled) {
                  filesHashed++;
                  bytesHashed += f.size;
                }
                _fileDone(unit, f);
                return scanned;
              })
              .whenComplete(slots.release),
        );
      }
      final index = i;
      unitFutures.add(
        Future.wait(fileFutures).then((files) {
          final game = ScannedGame(
            rootId: rootId,
            systemId: unit.systemId,
            primaryRelPath: unit.primaryRelPath,
            title: unit.title,
            region: unit.region,
            files: List.unmodifiable(files),
            discCount: unit.discCount,
            isDirectory: unit.isDirectory,
          );
          games[index] = game;
          _gamesFound++;
          if (!_cancelled && !_games.isClosed) _games.add(game);
          _emit();
        }),
      );
    }
    await Future.wait(unitFutures, eagerError: true);
    _checkCancelled();

    return ScanResult(
      rootId: rootId,
      systemIds: {for (final (s, _, _) in systemDirs) s.id},
      games: List.unmodifiable(games.whereType<ScannedGame>()),
      warnings: List.unmodifiable(_warnings),
      filesHashed: filesHashed,
      filesReused: filesReused,
      bytesHashed: bytesHashed,
      elapsed: _stopwatch.elapsed,
    );
  }

  void _fileDone(GameUnit unit, DiscoveredFile f) {
    _processed++;
    _processedBytes += f.size;
    _currentSystem = unit.systemId;
    _currentFile = f.relPath;
    _emit();
  }

  Future<ScannedFile> _hashOne(DiscoveredFile f) async {
    try {
      final h = await _pool!.hash(
        _absolute(f.relPath),
        partialThreshold: _options.partialHashThreshold,
        partialChunk: _options.partialHashChunk,
      );
      return ScannedFile(
        relPath: f.relPath,
        size: f.size,
        modified: f.modified,
        crc32: h.crc32,
        md5: h.md5,
        sha1: h.sha1,
        partialHash: h.partial,
      );
    } on HashFailure catch (e) {
      _warn(ScanWarning(ScanWarningKind.unreadableFile, f.relPath, e.message));
      return ScannedFile(
        relPath: f.relPath,
        size: f.size,
        modified: f.modified,
      );
    } on HashPoolClosed {
      // Cancelled; the main loop notices and stops.
      return ScannedFile(
        relPath: f.relPath,
        size: f.size,
        modified: f.modified,
      );
    }
  }

  String _absolute(String relPath) =>
      p.joinAll([rootPath, ...relPath.split('/')]);

  /// Walks [dir] (rel path [rel]) collecting candidate files.
  Future<void> _walk(
    GameSystem system,
    Directory dir,
    String rel,
    int depth,
    List<DiscoveredFile> files,
    List<DiscoveredDirectory> dirGames,
  ) async {
    if (depth > _options.maxDepth) {
      _warn(
        ScanWarning(
          ScanWarningKind.tooDeep,
          rel,
          'Folder is nested deeper than ${_options.maxDepth} levels',
        ),
      );
      return;
    }
    final subdirs = <(Directory, String)>[];
    try {
      await for (final e in dir.list(followLinks: false)) {
        if (_cancelled) return;
        final name = p.basename(e.path);
        if (name.startsWith('.')) continue;
        final childRel = '$rel/$name';
        if (e is Link) {
          _warn(
            ScanWarning(
              ScanWarningKind.skippedLink,
              childRel,
              'Symbolic links are not followed',
            ),
          );
        } else if (e is Directory) {
          if (skippedFolderNames.contains(name.toLowerCase())) continue;
          subdirs.add((e, name));
        } else if (e is File) {
          final file = await _discoverFile(system, e, childRel);
          if (file != null) files.add(file);
        }
      }
    } on FileSystemException catch (e) {
      _warn(ScanWarning(ScanWarningKind.unreadableDirectory, rel, _msg(e)));
    }
    subdirs.sort((a, b) => a.$2.compareTo(b.$2));
    for (final (sub, name) in subdirs) {
      if (_cancelled) return;
      final childRel = '$rel/$name';
      final ext = p.extension(name).toLowerCase();
      if (directoryGameExtensions.contains(ext) &&
          system.extensions.contains(ext)) {
        final inner = <DiscoveredFile>[];
        await _collectAll(sub, childRel, depth + 1, inner);
        dirGames.add(DiscoveredDirectory(relPath: childRel, files: inner));
      } else {
        await _walk(system, sub, childRel, depth + 1, files, dirGames);
      }
    }
  }

  /// Collects every (non-hidden) file below a directory game.
  Future<void> _collectAll(
    Directory dir,
    String rel,
    int depth,
    List<DiscoveredFile> out,
  ) async {
    if (depth > _options.maxDepth + 8) {
      _warn(
        ScanWarning(ScanWarningKind.tooDeep, rel, 'Folder nested too deep'),
      );
      return;
    }
    final subdirs = <(Directory, String)>[];
    try {
      await for (final e in dir.list(followLinks: false)) {
        if (_cancelled) return;
        final name = p.basename(e.path);
        if (name.startsWith('.')) continue;
        final childRel = '$rel/$name';
        if (e is Directory) {
          subdirs.add((e, name));
        } else if (e is File) {
          final f = await _statFile(e, childRel);
          if (f != null) out.add(f);
        } else if (e is Link) {
          _warn(
            ScanWarning(
              ScanWarningKind.skippedLink,
              childRel,
              'Symbolic links are not followed',
            ),
          );
        }
      }
    } on FileSystemException catch (e) {
      _warn(ScanWarning(ScanWarningKind.unreadableDirectory, rel, _msg(e)));
    }
    for (final (sub, name) in subdirs) {
      await _collectAll(sub, '$rel/$name', depth + 1, out);
    }
  }

  Future<DiscoveredFile?> _discoverFile(
    GameSystem system,
    File file,
    String rel,
  ) async {
    final stat = await _statFile(file, rel);
    if (stat == null) return null;
    final ext = stat.extension;
    if (!sheetExtensions.contains(ext) || !system.extensions.contains(ext)) {
      return stat;
    }
    List<String>? entries;
    if (stat.size <= _options.maxSheetBytes) {
      try {
        entries = parseSheet(ext, decodeSheet(await file.readAsBytes()));
      } on FileSystemException catch (e) {
        _warn(ScanWarning(ScanWarningKind.unreadableFile, rel, _msg(e)));
      }
    }
    return DiscoveredFile(
      relPath: stat.relPath,
      size: stat.size,
      modified: stat.modified,
      sheetEntries: entries ?? const [],
    );
  }

  Future<DiscoveredFile?> _statFile(File file, String rel) async {
    try {
      final s = await file.stat();
      if (s.type == FileSystemEntityType.notFound) {
        _warn(
          ScanWarning(ScanWarningKind.unreadableFile, rel, 'File vanished'),
        );
        return null;
      }
      return DiscoveredFile(
        relPath: rel,
        size: s.size,
        modified: s.modified.toUtc(),
      );
    } on FileSystemException catch (e) {
      _warn(ScanWarning(ScanWarningKind.unreadableFile, rel, _msg(e)));
      return null;
    }
  }
}

String _msg(FileSystemException e) {
  final os = e.osError?.message;
  return os == null || os.isEmpty ? e.message : '${e.message}: $os';
}

class _Semaphore {
  _Semaphore(this._available);

  int _available;
  final _waiters = <Completer<void>>[];

  Future<void> acquire() {
    if (_available > 0) {
      _available--;
      return Future.value();
    }
    final c = Completer<void>();
    _waiters.add(c);
    return c.future;
  }

  void release() {
    if (_waiters.isNotEmpty) {
      _waiters.removeAt(0).complete();
    } else {
      _available++;
    }
  }
}
