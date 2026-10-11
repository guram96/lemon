import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rs_api_client/rs_api_client.dart';
import 'package:rs_core/rs_core.dart';

import '../connection/connection_provider.dart';
import '../storage/credential_store.dart';
import 'download_writer_stub.dart'
    if (dart.library.io) 'download_writer_io.dart'
    as writer;
import 'install_models.dart';
import 'install_store.dart';
import 'install_store_stub.dart'
    if (dart.library.io) 'install_store_io.dart'
    as install_paths;

/// Byte writer used by [DownloadQueueNotifier]. The default writes on IO and
/// throws on the web, where installs are unavailable.
final downloadFileWriterProvider = Provider<DownloadFileWriter>(
  (ref) => writer.writeDownloadFile,
);

/// Appends [bytes] under a destination folder. False means the path was refused.
typedef DownloadFileWriter = Future<bool> Function({
  required String folder,
  required String path,
  required List<int> bytes,
  required bool append,
});

/// Install jobs for the active server. Every phase is included.
final downloadQueueProvider =
    NotifierProvider<DownloadQueueNotifier, List<InstallRecord>>(
      DownloadQueueNotifier.new,
    );

/// One download at a time. Pause, resume, cancel, and uninstall update
/// [InstallStore] so a later launch reloads the same jobs.
class DownloadQueueNotifier extends Notifier<List<InstallRecord>> {
  late Future<void> _ready;
  var _ticket = 0;
  String? _active;
  Future<void>? _downloadDone;
  final _pending = <String>{};
  final _pauseFlags = <String>{};
  final _cancelled = <String>{};
  final _streams = <String, _LiveDownload>{};

  @override
  List<InstallRecord> build() {
    final ticket = ++_ticket;
    _pending.clear();
    _pauseFlags.clear();
    _cancelled.clear();
    _active = null;
    _haltStreams();
    ref.onDispose(() {
      if (_ticket == ticket) {
        _ticket++;
        _haltStreams();
      }
    });
    _ready = _restore(ticket);
    return const [];
  }

  /// Queues [game] on the active server.
  ///
  /// A game that already has a record is left alone. When no destination
  /// folder is set, or there is no server id, this returns without a record.
  Future<void> enqueue(Game game) async {
    await _ready;
    final ticket = _ticket;
    if (!_isCurrent(ticket)) return;
    if (_record(game.id) != null || _pending.contains(game.id)) return;
    _pending.add(game.id);
    var start = false;
    try {
      final serverId = await _serverId();
      if (!_isCurrent(ticket) || serverId == null) return;
      if (_record(game.id) != null) return;
      final folder = await _folder(game.systemId);
      if (!_isCurrent(ticket) || folder == null) return;
      if (_record(game.id) != null) return;

      final DownloadManifest manifest;
      try {
        manifest = await ref.read(apiClientProvider).downloadManifest(game.id);
      } on Object catch (error) {
        if (!_isCurrent(ticket)) return;
        await _save(
          InstallRecord(
            serverId: serverId,
            gameId: game.id,
            systemId: game.systemId,
            phase: InstallPhase.failed,
            receivedBytes: 0,
            totalBytes: game.sizeBytes,
            error: _message(error),
          ),
          ticket,
        );
        return;
      }
      if (!_isCurrent(ticket) || _cancelled.contains(game.id)) return;

      final listed = [...manifest.files]
        ..sort((a, b) => a.index.compareTo(b.index));
      final files = [
        for (final file in listed)
          InstallFileProgress(
            index: file.index,
            path: file.path,
            receivedBytes: 0,
            sizeBytes: file.sizeBytes,
            complete: false,
          ),
      ];
      await _save(
        InstallRecord(
          serverId: serverId,
          gameId: game.id,
          systemId: game.systemId,
          phase: InstallPhase.queued,
          receivedBytes: 0,
          totalBytes: _size(files),
          files: files,
        ),
        ticket,
      );
      start = _isCurrent(ticket);
    } finally {
      _pending.remove(game.id);
    }
    if (start) _kick(ticket);
  }

  /// Stops [gameId] if it is queued or downloading and keeps the partial file.
  Future<void> pause(String gameId) async {
    await _ready;
    final ticket = _ticket;
    if (!_isCurrent(ticket)) return;
    final record = _record(gameId);
    if (record == null) return;
    if (record.phase != InstallPhase.queued &&
        record.phase != InstallPhase.downloading) {
      return;
    }
    _pauseFlags.add(gameId);
    if (_active == gameId) {
      await _drop(gameId);
      final pending = _downloadDone;
      if (pending != null) await pending;
      return;
    }
    final latest = _record(gameId);
    if (latest != null && latest.phase == InstallPhase.queued) {
      await _save(latest.copyWith(phase: InstallPhase.paused), ticket);
    }
  }

  /// Continues a paused or failed [gameId] from [InstallFileProgress.receivedBytes].
  Future<void> resume(String gameId) async {
    await _ready;
    final ticket = _ticket;
    if (!_isCurrent(ticket)) return;
    if (_active == gameId) {
      final pending = _downloadDone;
      if (pending != null) await pending;
    }
    if (!_isCurrent(ticket)) return;
    _pauseFlags.remove(gameId);
    final record = _record(gameId);
    if (record == null) return;
    if (record.phase != InstallPhase.paused &&
        record.phase != InstallPhase.failed) {
      return;
    }
    await _save(
      record.copyWith(phase: InstallPhase.queued, error: null),
      ticket,
    );
    if (_isCurrent(ticket)) _kick(ticket);
  }

  /// Drops an unfinished [gameId] and deletes partial files.
  Future<void> cancel(String gameId) async {
    await _ready;
    final ticket = _ticket;
    if (!_isCurrent(ticket)) return;
    final record = _record(gameId);
    if (record == null || record.phase == InstallPhase.installed) return;
    _cancelled.add(gameId);
    _pauseFlags.remove(gameId);
    await _drop(gameId);
    if (_active == gameId) {
      final pending = _downloadDone;
      if (pending != null) await pending;
    }
    if (!_isCurrent(ticket)) return;
    final latest = _record(gameId) ?? record;
    await ref.read(installStoreProvider).uninstall(latest);
    if (!_isCurrent(ticket)) return;
    state = [
      for (final item in state)
        if (item.gameId != gameId) item,
    ];
    _cancelled.remove(gameId);
  }

  /// Deletes an installed [gameId] from this device.
  Future<void> uninstallGame(String gameId) async {
    await _ready;
    final ticket = _ticket;
    if (!_isCurrent(ticket)) return;
    final record = _record(gameId);
    if (record == null || record.phase != InstallPhase.installed) return;
    await ref.read(installStoreProvider).uninstall(record);
    if (!_isCurrent(ticket)) return;
    state = [
      for (final item in state)
        if (item.gameId != gameId) item,
    ];
  }

  Future<void> _restore(int ticket) async {
    final serverId = await _serverId();
    if (!_isCurrent(ticket)) return;
    if (serverId == null) {
      state = const [];
      return;
    }
    final records = await ref.read(installStoreProvider).installs(serverId);
    if (!_isCurrent(ticket)) return;
    final next = <InstallRecord>[];
    for (final record in records) {
      if (record.phase == InstallPhase.queued ||
          record.phase == InstallPhase.downloading) {
        final paused = record.copyWith(phase: InstallPhase.paused);
        await ref.read(installStoreProvider).put(paused);
        if (!_isCurrent(ticket)) return;
        next.add(paused);
      } else {
        next.add(record);
      }
    }
    if (!_isCurrent(ticket)) return;
    state = List.unmodifiable(next);
  }

  void _kick(int ticket) {
    if (!_isCurrent(ticket) || _active != null) return;
    final next = _firstQueued();
    if (next == null) return;
    final gameId = next.gameId;
    _active = gameId;
    final done = _download(next, ticket);
    _downloadDone = done.whenComplete(() {
      if (!_isCurrent(ticket)) return;
      if (_active == gameId) _active = null;
      _kick(ticket);
    });
  }

  Future<void> _download(InstallRecord initial, int ticket) async {
    final gameId = initial.gameId;
    try {
      await _runDownload(initial, ticket);
    } on Object catch (error) {
      if (!_isCurrent(ticket) || _cancelled.contains(gameId)) return;
      if (_pauseFlags.contains(gameId)) return;
      await _fail(gameId, _message(error), ticket);
    } finally {
      if (_isCurrent(ticket) &&
          _pauseFlags.contains(gameId) &&
          !_cancelled.contains(gameId)) {
        final latest = _record(gameId);
        if (latest != null &&
            latest.phase != InstallPhase.installed &&
            latest.phase != InstallPhase.paused &&
            latest.phase != InstallPhase.failed) {
          await _save(latest.copyWith(phase: InstallPhase.paused), ticket);
        }
      }
      _pauseFlags.remove(gameId);
    }
  }

  Future<void> _runDownload(InstallRecord initial, int ticket) async {
    final gameId = initial.gameId;
    if (!_isCurrent(ticket) || _cancelled.contains(gameId)) return;
    if (_pauseFlags.contains(gameId)) return;

    final folder = await _folder(initial.systemId);
    if (!_isCurrent(ticket) || _cancelled.contains(gameId)) return;
    if (_pauseFlags.contains(gameId)) return;
    if (folder == null) {
      await _fail(gameId, _noFolder, ticket);
      return;
    }

    var record = initial.copyWith(phase: InstallPhase.downloading, error: null);
    if (!await _save(record, ticket)) return;
    if (_pauseFlags.contains(gameId) || _cancelled.contains(gameId)) return;

    final files = [...record.files]..sort((a, b) => a.index.compareTo(b.index));
    final paths = <int, String>{};
    for (final file in files) {
      if (file.complete) continue;
      final absolute = _installPath(
        folder: folder,
        systemId: record.systemId,
        relativePath: file.path,
      );
      if (absolute == null) {
        await _fail(gameId, _escapedPath, ticket);
        return;
      }
      paths[file.index] = absolute;
    }

    final client = ref.read(apiClientProvider);
    for (var i = 0; i < files.length; i++) {
      if (files[i].complete) continue;
      if (!_isCurrent(ticket) || _isStopped(gameId)) return;
      final absolute = paths[files[i].index];
      if (absolute == null) {
        await _fail(gameId, _escapedPath, ticket);
        return;
      }
      final finished = await _downloadFile(
        record: record,
        ticket: ticket,
        folder: folder,
        files: files,
        index: i,
        absolutePath: absolute,
        client: client,
      );
      if (!finished) return;
      record = _record(gameId) ?? record;
      if (record.phase != InstallPhase.downloading) return;
    }
    if (files.isEmpty || files.every((file) => file.complete)) {
      final current = _record(gameId);
      if (current != null && current.phase == InstallPhase.downloading) {
        await _save(
          current.copyWith(
            phase: InstallPhase.installed,
            receivedBytes: _received(files),
            error: null,
          ),
          ticket,
        );
      }
    }
  }

  /// Returns false when the caller should stop the rest of the game.
  Future<bool> _downloadFile({
    required InstallRecord record,
    required int ticket,
    required String folder,
    required List<InstallFileProgress> files,
    required int index,
    required String absolutePath,
    required RsApiClient client,
  }) async {
    final gameId = record.gameId;
    var received = files[index].receivedBytes;
    final opened = await client.openGameFile(
      gameId,
      files[index].index,
      start: received > 0 ? received : null,
    );
    if (!_isCurrent(ticket) || _isStopped(gameId)) return false;

    final bridge = StreamController<List<int>>();
    final subscription = opened.bytes.listen(
      (List<int> chunk) {
        if (!bridge.isClosed) bridge.add(chunk);
      },
      onError: (Object error, StackTrace stack) {
        if (!bridge.isClosed) bridge.addError(error, stack);
      },
      onDone: () {
        if (!bridge.isClosed) unawaited(bridge.close());
      },
    );
    _streams[gameId] = _LiveDownload(subscription, bridge);
    if (!_isCurrent(ticket) || _isStopped(gameId)) {
      await _drop(gameId);
      return false;
    }

    final writer = ref.read(downloadFileWriterProvider);
    try {
      await for (final chunk in bridge.stream) {
        if (!_isCurrent(ticket) || _isStopped(gameId)) return false;
        if (chunk.isEmpty) continue;
        final wrote = await writer(
          folder: folder,
          path: absolutePath,
          bytes: chunk,
          append: received > 0,
        );
        if (!_isCurrent(ticket) || _cancelled.contains(gameId)) return false;
        if (!wrote) {
          await _fail(gameId, _escapedPath, ticket);
          return false;
        }
        if (_isStopped(gameId)) return false;
        received += chunk.length;
        files[index] = files[index].copyWith(receivedBytes: received);
        final latest = _record(gameId) ?? record;
        final saved = await _save(
          latest.copyWith(
            phase: InstallPhase.downloading,
            receivedBytes: _received(files),
            files: [...files],
            error: null,
          ),
          ticket,
        );
        if (!saved || _isStopped(gameId)) return false;
      }
    } on Object catch (error) {
      if (!_isCurrent(ticket) || _isStopped(gameId)) return false;
      await _fail(gameId, _message(error), ticket);
      return false;
    } finally {
      await subscription.cancel();
      await _drop(gameId);
    }

    if (!_isCurrent(ticket) || _isStopped(gameId)) return false;
    final current = _record(gameId);
    if (current == null || current.phase == InstallPhase.failed) return false;
    files[index] = files[index].copyWith(
      complete: true,
      receivedBytes: files[index].sizeBytes,
    );
    final done = files.every((file) => file.complete);
    await _save(
      current.copyWith(
        phase: done ? InstallPhase.installed : InstallPhase.downloading,
        receivedBytes: _received(files),
        files: [...files],
        error: null,
      ),
      ticket,
    );
    return !done;
  }

  Future<void> _fail(String gameId, String message, int ticket) async {
    final latest = _record(gameId);
    if (latest == null || latest.phase == InstallPhase.installed) return;
    await _save(
      latest.copyWith(phase: InstallPhase.failed, error: message),
      ticket,
    );
  }

  Future<bool> _save(InstallRecord record, int ticket) async {
    if (!_isCurrent(ticket) || _cancelled.contains(record.gameId)) {
      return false;
    }
    await ref.read(installStoreProvider).put(record);
    if (!_isCurrent(ticket) || _cancelled.contains(record.gameId)) {
      return false;
    }
    state = _replaced(state, record);
    return true;
  }

  void _haltStreams() {
    for (final live in _streams.values) {
      unawaited(live.subscription.cancel());
      if (!live.bridge.isClosed) unawaited(live.bridge.close());
    }
    _streams.clear();
  }

  Future<void> _drop(String gameId) async {
    final live = _streams.remove(gameId);
    if (live == null) return;
    await live.subscription.cancel();
    if (!live.bridge.isClosed) await live.bridge.close();
  }

  bool _isCurrent(int ticket) => ticket == _ticket && ref.mounted;

  bool _isStopped(String gameId) =>
      _pauseFlags.contains(gameId) || _cancelled.contains(gameId);

  InstallRecord? _record(String gameId) {
    for (final record in state) {
      if (record.gameId == gameId) return record;
    }
    return null;
  }

  InstallRecord? _firstQueued() {
    for (final record in state) {
      if (record.phase == InstallPhase.queued &&
          !_pauseFlags.contains(record.gameId)) {
        return record;
      }
    }
    return null;
  }

  Future<String?> _serverId() async {
    final id = (await ref.read(credentialStoreProvider).load()).serverId;
    if (id == null || id.isEmpty) return null;
    return id;
  }

  Future<String?> _folder(String systemId) async {
    final destinations = await ref.read(destinationsProvider.future);
    return destinations.folderFor(systemId);
  }
}

class _LiveDownload {
  _LiveDownload(this.subscription, this.bridge);

  final StreamSubscription<List<int>> subscription;
  final StreamController<List<int>> bridge;
}

List<InstallRecord> _replaced(
  List<InstallRecord> current,
  InstallRecord record,
) {
  final next = [
    for (final item in current)
      if (item.gameId != record.gameId) item,
    record,
  ]..sort((a, b) => a.gameId.compareTo(b.gameId));
  return List.unmodifiable(next);
}

int _received(List<InstallFileProgress> files) =>
    files.fold<int>(0, (sum, file) => sum + file.receivedBytes);

int _size(List<InstallFileProgress> files) =>
    files.fold<int>(0, (sum, file) => sum + file.sizeBytes);

String _message(Object error) =>
    error is ApiException ? error.error.message : error.toString();

String? _installPath({
  required String folder,
  required String systemId,
  required String relativePath,
}) {
  try {
    return install_paths.resolveInstallFile(
      folder: folder,
      systemId: systemId,
      relativePath: relativePath,
    );
  } on UnsupportedError {
    return null;
  }
}

const _escapedPath = 'Path escapes the install folder';
const _noFolder = 'No install folder for this system';
