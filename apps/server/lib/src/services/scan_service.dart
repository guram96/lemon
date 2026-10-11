import 'dart:async';

import 'package:logging/logging.dart';
import 'package:rs_core/rs_core.dart';

import '../db/game_repo.dart';
import '../db/root_repo.dart';
import '../scanner/scanner.dart';
import 'event_hub.dart';
import 'mappers.dart';
import 'root_service.dart';

final _log = Logger('scan');

/// Runs library scans, one at a time, over every reachable library root.
///
/// - Games are persisted in batches while the scan runs ([batchSize] games or
///   [batchInterval], whichever comes first), each batch publishing a
///   `libraryChanged` event, so clients fill in live.
/// - When a root finishes, games of the scanned systems that no longer exist
///   are removed. Cancelled or failed roots never remove anything, and
///   offline roots are never scanned.
/// - [status] always holds the latest [ScanStatus]; `scanProgress` events are
///   throttled to one per [progressInterval] (the last status is always
///   delivered).
class ScanService {
  ScanService({
    required this._roots,
    required this._games,
    required this._events,
    this._scanner = const Scanner(),
    this.batchSize = 25,
    this.batchInterval = const Duration(seconds: 1),
    this.progressInterval = const Duration(milliseconds: 250),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final RootService _roots;
  final GameRepo _games;
  final EventHub _events;
  final Scanner _scanner;
  final DateTime Function() _clock;

  final int batchSize;
  final Duration batchInterval;
  final Duration progressInterval;

  ScanStatus _status = ScanStatus.idle;
  Future<void>? _running;
  ScanJob? _job;
  bool _stopping = false;

  // Progress bookkeeping across roots.
  int _filesBefore = 0;
  int _rootFiles = 0;

  // Throttling.
  final _sincePublish = Stopwatch();
  Timer? _publishTimer;

  /// The current or last scan's status.
  ScanStatus get status => _status;

  bool get isRunning => _running != null;

  /// Completes when the running scan (if any) has finished.
  Future<void> get done => _running ?? Future<void>.value();

  /// Starts a scan in the background. Returns `false` if one is running.
  bool start() {
    if (_running != null || _stopping) return false;
    _running = _run().whenComplete(() => _running = null);
    return true;
  }

  /// Cancels a running scan and waits for it to stop. No further scans can
  /// be started.
  Future<void> shutdown() async {
    _stopping = true;
    _job?.cancel();
    await _running;
    _publishTimer?.cancel();
    _publishTimer = null;
  }

  Future<void> _run() async {
    _filesBefore = 0;
    _rootFiles = 0;
    _update(
      ScanStatus(phase: ScanPhase.discovering, startedAt: _clock().toUtc()),
    );
    final errors = <String>[];
    try {
      final roots = await _roots.refresh();
      for (final root in roots) {
        if (_stopping) break;
        if (root.status == LibraryRootStatus.offline) continue;
        try {
          await _scanRoot(root);
        } on ScanCancelledException {
          errors.add('Scan cancelled.');
          break;
        } on Object catch (e, st) {
          final message = e is ScanException ? e.message : '$e';
          _log.warning('Scan of "${root.label}" failed: $message', e, st);
          errors.add('${root.label}: $message');
        }
      }
    } on Object catch (e, st) {
      _log.severe('Scan failed', e, st);
      errors.add('$e');
    }
    _update(
      _status.copyWith(
        phase: errors.isEmpty ? ScanPhase.done : ScanPhase.failed,
        processed: _filesBefore,
        total: _filesBefore,
        currentSystemId: null,
        currentFile: null,
        finishedAt: _clock().toUtc(),
        error: errors.isEmpty ? null : errors.join('\n'),
      ),
    );
    _log.info(
      'Scan ${_status.phase.name}: +${_status.added} '
      '~${_status.updated} -${_status.removed}',
    );
  }

  Future<void> _scanRoot(RootRecord root) async {
    _rootFiles = 0;
    final previous = ScanIndex(
      _games.fileIndex(root.id).values.map(Mappers.scannedFile),
    );
    final job = _scanner.scan(
      rootId: root.id,
      rootPath: root.lastPath,
      previous: previous,
    );
    _job = job;

    final buffer = <ScannedGame>[];
    Timer? flushTimer;
    void flush() {
      flushTimer?.cancel();
      flushTimer = null;
      if (buffer.isEmpty) return;
      final batch = buffer.map(Mappers.scannedGame).toList();
      buffer.clear();
      // An empty system set: a batch only adds and updates, never removes.
      _apply(_games.upsertScanned(root.id, batch, systems: const {}));
    }

    final gamesSub = job.games.listen((game) {
      buffer.add(game);
      if (buffer.length >= batchSize) {
        flush();
      } else {
        flushTimer ??= Timer(batchInterval, flush);
      }
    });
    final progressSub = job.progress.listen(_onProgress);
    try {
      final ScanResult result;
      try {
        result = await job.result;
      } finally {
        // Games found before a cancel or failure are still valid.
        flush();
      }
      _update(
        _status.copyWith(
          phase: ScanPhase.saving,
          processed: _filesBefore + _rootFiles,
          total: _filesBefore + _rootFiles,
          currentFile: null,
        ),
      );
      _apply(
        _games.upsertScanned(
          root.id,
          result.games.map(Mappers.scannedGame).toList(),
          systems: result.systemIds,
        ),
      );
      if (result.warnings.isNotEmpty) {
        _log.info(
          'Scan of "${root.label}": ${result.warnings.length} warning(s)',
        );
      }
    } finally {
      flushTimer?.cancel();
      _filesBefore += _rootFiles;
      _rootFiles = 0;
      _job = null;
      await gamesSub.cancel();
      await progressSub.cancel();
    }
  }

  void _onProgress(ScanProgress p) {
    switch (p.phase) {
      case ScannerPhase.discovering:
        _update(
          _status.copyWith(
            phase: ScanPhase.discovering,
            processed: _filesBefore,
            total: 0,
            currentSystemId: p.currentSystemId,
            currentFile: null,
          ),
        );
      case ScannerPhase.hashing:
        _rootFiles = p.total;
        _update(
          _status.copyWith(
            phase: ScanPhase.hashing,
            processed: _filesBefore + p.processed,
            total: _filesBefore + p.total,
            currentSystemId: p.currentSystemId,
            currentFile: p.currentFile,
          ),
        );
      // Final states are reported from the job's result.
      case ScannerPhase.done || ScannerPhase.cancelled || ScannerPhase.failed:
        break;
    }
  }

  void _apply(GameDiff diff) {
    if (diff.isEmpty) return;
    _status = _status.copyWith(
      added: _status.added + diff.added.length,
      updated: _status.updated + diff.updated.length,
      removed: _status.removed + diff.removed.length,
    );
    _events.publish(
      ServerEvent.libraryChanged(
        addedIds: diff.added,
        updatedIds: diff.updated,
        removedIds: diff.removed,
      ),
    );
    _schedulePublish();
  }

  void _update(ScanStatus status) {
    _status = status;
    _schedulePublish();
  }

  /// Publishes [status] at most once per [progressInterval]; a status that
  /// arrives too early is sent (as the then-latest status) when the interval
  /// ends.
  void _schedulePublish() {
    if (_publishTimer != null) return;
    final elapsed = _sincePublish.isRunning
        ? _sincePublish.elapsed
        : progressInterval;
    if (elapsed >= progressInterval) {
      _publishNow();
    } else {
      _publishTimer = Timer(progressInterval - elapsed, () {
        _publishTimer = null;
        _publishNow();
      });
    }
  }

  void _publishNow() {
    _sincePublish
      ..reset()
      ..start();
    _events.publish(ServerEvent.scanProgress(status: _status));
  }
}
