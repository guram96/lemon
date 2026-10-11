import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rs_api_client/rs_api_client.dart';
import 'package:rs_client/src/connection/connection_provider.dart';
import 'package:rs_client/src/install/download_queue.dart';
import 'package:rs_client/src/install/install_models.dart';
import 'package:rs_client/src/install/install_store.dart';
import 'package:rs_client/src/storage/credential_store.dart';
import 'package:rs_core/rs_core.dart';

import '../support/fakes.dart';

const _serverId = 'server-1';

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('rs_queue_');
  });

  tearDown(() async {
    if (root.existsSync()) await root.delete(recursive: true);
  });

  test('enqueue writes bytes and ends installed', () async {
    final payload = [1, 2, 3, 4, 5];
    final game = _game(size: payload.length);
    final harness = await _start(
      root,
      api: _api(manifest: _manifest(game), payloads: {0: payload}),
    );
    addTearDown(harness.dispose);

    await harness.queue.enqueue(game);

    final records = await harness.waitFor(
      (items) =>
          items.length == 1 && items.single.phase == InstallPhase.installed,
    );
    expect(records.single.receivedBytes, payload.length);
    expect(records.single.totalBytes, payload.length);
    expect(records.single.files.single.complete, isTrue);
    expect(records.single.files.single.receivedBytes, payload.length);
    expect(await harness.file('games/chrono.sfc').readAsBytes(), payload);
    expect(harness.api.opens, [(index: 0, start: null)]);
  });

  test('pause then resume continues from receivedBytes', () async {
    final payload = List<int>.generate(10, (index) => index + 1);
    final game = _game(size: payload.length);
    final harness = await _start(
      root,
      api: _api(
        manifest: _manifest(game),
        payloads: {0: payload},
        manual: true,
      ),
    );
    addTearDown(harness.dispose);

    await harness.queue.enqueue(game);
    await harness.api.waitForOpens(1);
    harness.api.controllers.single.add(payload.sublist(0, 4));

    await harness.waitFor((items) => items.single.receivedBytes == 4);
    await harness.queue.pause(game.id);

    final paused = harness.records.single;
    expect(paused.phase, InstallPhase.paused);
    expect(paused.receivedBytes, 4);
    expect(paused.files.single.complete, isFalse);
    expect(await harness.file('games/chrono.sfc').readAsBytes(), [1, 2, 3, 4]);

    harness.api.controllers.first.add(const [9, 9, 9]);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(await harness.file('games/chrono.sfc').readAsBytes(), [1, 2, 3, 4]);

    await harness.queue.resume(game.id);
    await harness.api.waitForOpens(2);
    expect(harness.api.opens[1].start, 4);

    harness.api.controllers.last.add(payload.sublist(4));
    await harness.api.controllers.last.close();

    final installed = await harness.waitFor(
      (items) => items.single.phase == InstallPhase.installed,
    );
    expect(installed.single.receivedBytes, payload.length);
    expect(installed.single.files.single.complete, isTrue);
    expect(await harness.file('games/chrono.sfc').readAsBytes(), payload);
  });

  test('a path with .. is not written', () async {
    final game = _game(path: '../escaped.txt');
    final harness = await _start(
      root,
      api: _api(
        manifest: _manifest(game),
        payloads: const {
          0: [1, 2, 3, 4],
        },
      ),
    );
    addTearDown(harness.dispose);

    await harness.queue.enqueue(game);

    final records = await harness.waitFor(
      (items) => items.length == 1 && items.single.phase == InstallPhase.failed,
    );
    expect(records.single.error, 'Path escapes the install folder');
    expect(harness.api.opens, isEmpty);
    expect(File('${harness.dest.path}/escaped.txt').existsSync(), isFalse);
    expect(File('${harness.dest.path}/snes/escaped.txt').existsSync(), isFalse);
    expect(File('${root.path}/escaped.txt').existsSync(), isFalse);
  });

  test(
    'a second enqueue of the same game does not duplicate the record',
    () async {
      final payload = [7, 8, 9];
      final game = _game(size: payload.length);
      final harness = await _start(
        root,
        api: _api(manifest: _manifest(game), payloads: {0: payload}),
      );
      addTearDown(harness.dispose);

      await Future.wait([
        harness.queue.enqueue(game),
        harness.queue.enqueue(game),
      ]);
      await harness.queue.enqueue(game);

      final records = await harness.waitFor(
        (items) =>
            items.length == 1 && items.single.phase == InstallPhase.installed,
      );
      expect(records.single.gameId, game.id);
      expect(harness.api.manifestCalls, 1);
      expect(harness.api.opens, hasLength(1));
      expect(await openInstallStore(root).installs(_serverId), hasLength(1));
    },
  );

  test('restarting the notifier turns downloading into paused', () async {
    final store = openInstallStore(root);
    await store.writeDestinations(
      InstallDestination(globalFolder: '${root.path}/roms'),
    );
    await store.put(
      InstallRecord(
        serverId: _serverId,
        gameId: 'dl',
        systemId: 'snes',
        phase: InstallPhase.downloading,
        receivedBytes: 4,
        totalBytes: 10,
        files: const [
          InstallFileProgress(
            index: 0,
            path: 'chrono.sfc',
            receivedBytes: 4,
            sizeBytes: 10,
            complete: false,
          ),
        ],
      ),
    );
    await store.put(
      InstallRecord(
        serverId: _serverId,
        gameId: 'wait',
        systemId: 'snes',
        phase: InstallPhase.queued,
        receivedBytes: 0,
        totalBytes: 2,
        files: const [
          InstallFileProgress(
            index: 0,
            path: 'wait.sfc',
            receivedBytes: 0,
            sizeBytes: 2,
            complete: false,
          ),
        ],
      ),
    );
    await store.put(
      InstallRecord(
        serverId: _serverId,
        gameId: 'kept',
        systemId: 'snes',
        phase: InstallPhase.installed,
        receivedBytes: 2,
        totalBytes: 2,
        files: const [
          InstallFileProgress(
            index: 0,
            path: 'kept.sfc',
            receivedBytes: 2,
            sizeBytes: 2,
            complete: true,
          ),
        ],
      ),
    );

    final first = await _start(root, seedDestination: false);
    addTearDown(first.dispose);
    final paused = await first.waitFor(
      (items) => items.any(
        (item) => item.gameId == 'dl' && item.phase == InstallPhase.paused,
      ),
    );
    expect(paused.map((item) => (item.gameId, item.phase)), [
      ('dl', InstallPhase.paused),
      ('kept', InstallPhase.installed),
      ('wait', InstallPhase.paused),
    ]);
    expect(paused.firstWhere((item) => item.gameId == 'dl').receivedBytes, 4);
    expect(first.api.opens, isEmpty);
    expect(first.api.manifestCalls, 0);

    final saved = await openInstallStore(root).installs(_serverId);
    expect(
      saved.firstWhere((item) => item.gameId == 'dl').phase,
      InstallPhase.paused,
    );
    expect(
      saved.firstWhere((item) => item.gameId == 'wait').phase,
      InstallPhase.paused,
    );

    await first.dispose();
    final second = await _start(root, seedDestination: false);
    addTearDown(second.dispose);
    final again = await second.waitFor((items) => items.length == 3);
    expect(again.map((item) => (item.gameId, item.phase)), [
      ('dl', InstallPhase.paused),
      ('kept', InstallPhase.installed),
      ('wait', InstallPhase.paused),
    ]);
    expect(second.api.opens, isEmpty);
  });

  test('enqueue without a destination leaves the queue unchanged', () async {
    final game = _game();
    final harness = await _start(
      root,
      seedDestination: false,
      api: _api(
        manifest: _manifest(game),
        payloads: const {
          0: [1],
        },
      ),
    );
    addTearDown(harness.dispose);

    await harness.queue.enqueue(game);

    expect(harness.records, isEmpty);
    expect(harness.api.manifestCalls, 0);
    expect(await openInstallStore(root).installs(_serverId), isEmpty);
  });
}

Game _game({
  String id = 'chrono',
  String path = 'games/chrono.sfc',
  int size = 4,
}) => Game(
  id: id,
  systemId: 'snes',
  title: 'Chrono Trigger',
  rootId: 'root-1',
  files: [GameFile(path: path, sizeBytes: size)],
  addedAt: DateTime.utc(2020),
);

DownloadManifest _manifest(Game game) => DownloadManifest(
  gameId: game.id,
  systemId: game.systemId,
  files: [
    for (var i = 0; i < game.files.length; i++)
      DownloadFile(
        index: i,
        path: game.files[i].path,
        sizeBytes: game.files[i].sizeBytes,
      ),
  ],
);

_QueueApi _api({
  required DownloadManifest manifest,
  Map<int, List<int>> payloads = const {},
  bool manual = false,
}) => _QueueApi(manifest: manifest, payloads: payloads, manual: manual);

class _QueueApi extends FakeApiClient {
  _QueueApi({
    required this.manifest,
    required this.payloads,
    required this.manual,
  });

  final DownloadManifest manifest;
  final Map<int, List<int>> payloads;
  final bool manual;
  final opens = <({int index, int? start})>[];
  final controllers = <StreamController<List<int>>>[];
  var manifestCalls = 0;
  var _opened = 0;
  final _openWaiters = <Completer<int>>[];

  Future<void> waitForOpens(int count) async {
    while (_opened < count) {
      final waiter = Completer<int>();
      _openWaiters.add(waiter);
      if (_opened >= count) {
        waiter.complete(_opened);
        return;
      }
      await waiter.future;
    }
  }

  void _noteOpen() {
    _opened++;
    final waiting = [..._openWaiters];
    _openWaiters.clear();
    for (final waiter in waiting) {
      if (!waiter.isCompleted) waiter.complete(_opened);
    }
  }

  @override
  Future<DownloadManifest> downloadManifest(String gameId) async {
    manifestCalls++;
    if (manifest.gameId != gameId) {
      throw apiError(404, ApiErrorCodes.notFound);
    }
    return manifest;
  }

  @override
  Future<DownloadStream> openGameFile(
    String gameId,
    int index, {
    int? start,
  }) async {
    opens.add((index: index, start: start));
    _noteOpen();
    final all = payloads[index];
    if (all == null) throw StateError('no payload for file $index');
    final offset = start ?? 0;
    final slice = offset >= all.length ? const <int>[] : all.sublist(offset);
    if (!manual) {
      return DownloadStream(
        statusCode: start == null ? 200 : 206,
        totalBytes: all.length,
        start: offset,
        bytes: Stream<List<int>>.value(slice),
      );
    }
    final controller = StreamController<List<int>>();
    controllers.add(controller);
    return DownloadStream(
      statusCode: start == null ? 200 : 206,
      totalBytes: all.length,
      start: offset,
      bytes: controller.stream,
    );
  }
}

class _Harness {
  _Harness(this.container, this.api, this.dest);

  final ProviderContainer container;
  final _QueueApi api;
  final Directory dest;
  var _disposed = false;

  DownloadQueueNotifier get queue =>
      container.read(downloadQueueProvider.notifier);

  List<InstallRecord> get records => container.read(downloadQueueProvider);

  File file(String relative) => File('${dest.path}/snes/$relative');

  Future<List<InstallRecord>> waitFor(
    bool Function(List<InstallRecord>) match,
  ) async {
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (DateTime.now().isBefore(deadline)) {
      final current = records;
      if (match(current)) return current;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    fail('timed out with $records');
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    container.dispose();
    for (final controller in api.controllers) {
      if (!controller.isClosed) await controller.close();
    }
    if (!api.eventsController.isClosed) await api.eventsController.close();
  }
}

Future<_Harness> _start(
  Directory root, {
  _QueueApi? api,
  bool seedDestination = true,
}) async {
  final dest = Directory('${root.path}/roms');
  if (seedDestination) {
    await openInstallStore(root)
        .writeDestinations(InstallDestination(globalFolder: dest.path));
  }
  final client =
      api ??
      _QueueApi(
        manifest: const DownloadManifest(
          gameId: 'none',
          systemId: 'snes',
          files: [],
        ),
        payloads: const {},
        manual: false,
      );
  final container = ProviderContainer(
    overrides: [
      apiClientProvider.overrideWithValue(client),
      credentialStoreProvider.overrideWithValue(
        InMemoryCredentialStore(const StoredCredentials(serverId: _serverId)),
      ),
      installDirectoryProvider.overrideWithValue(root),
    ],
  );
  return _Harness(container, client, dest);
}
