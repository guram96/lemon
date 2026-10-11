import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:rs_core/rs_core.dart';
import 'package:rs_server/rs_server.dart';
import 'package:rs_server/src/db/db.dart';
import 'package:rs_server/src/services/root_service.dart';
import 'package:rs_server/src/storage/storage.dart';
import 'package:test/test.dart';

void main() {
  late Directory temp;
  late RsDatabase db;
  late EventHub hub;
  late List<ServerEvent> events;
  late StreamSubscription<ServerEvent> sub;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('rs_scansvc_');
    db = RsDatabase.inMemory();
    hub = EventHub();
    events = [];
    sub = hub.stream.listen(events.add);
  });
  tearDown(() async {
    await sub.cancel();
    await hub.close();
    db.close();
    await temp.delete(recursive: true);
  });

  Future<String> addRoot(String name, {int snesGames = 0}) async {
    final dir = Directory(p.join(temp.path, name))..createSync();
    for (var i = 0; i < snesGames; i++) {
      File(p.join(dir.path, 'snes', 'Game $i.sfc'))
        ..parent.createSync(recursive: true)
        ..writeAsStringSync('rom $i');
    }
    final reg = await const LibraryRoots().register(dir.path);
    RootRepo(db).upsert(
      id: reg.id,
      label: reg.label,
      lastPath: reg.path,
      status: reg.status,
    );
    return reg.id;
  }

  ScanService service({int batchSize = 25}) => ScanService(
    roots: RootService(RootRepo(db), hub, searchDirs: const []),
    games: GameRepo(db),
    events: hub,
    scanner: const Scanner(
      options: ScannerOptions(hashWorkers: 2, progressInterval: Duration.zero),
    ),
    batchSize: batchSize,
  );

  test('persists games in batches while scanning', () async {
    await addRoot('roms', snesGames: 60);
    final scans = service();
    expect(scans.start(), isTrue);
    await scans.done;

    final changes = events.whereType<LibraryChangedEvent>().toList();
    expect(changes.expand((e) => e.addedIds), hasLength(60));
    expect(changes.length, greaterThanOrEqualTo(3));
    expect(changes.every((e) => e.addedIds.length <= 25), isTrue);
    expect(scans.status.phase, ScanPhase.done);
    expect(scans.status.added, 60);
    expect(scans.status.processed, 60);
    expect(scans.status.total, 60);
    expect(GameRepo(db).count(), 60);
  });

  test('the last status is always published, throttled', () async {
    await addRoot('roms', snesGames: 5);
    final scans = service();
    scans.start();
    await scans.done;
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final progress = events.whereType<ScanProgressEvent>().toList();
    expect(progress.last.status, scans.status);
    expect(progress.last.status.phase, ScanPhase.done);
  });

  test('rescans detect removals and never touch offline roots', () async {
    final online = await addRoot('online', snesGames: 2);
    final offline = await addRoot('offline', snesGames: 3);
    await service().start2();
    expect(GameRepo(db).count(), 5);

    // Unplug one drive, delete a game from the other.
    Directory(p.join(temp.path, 'offline'))
        .renameSync(p.join(temp.path, 'gone'));
    File(p.join(temp.path, 'online', 'snes', 'Game 0.sfc')).deleteSync();
    events.clear();

    final scans = service();
    await scans.start2();
    expect(GameRepo(db).count(rootId: online), 1);
    expect(GameRepo(db).count(rootId: offline), 3);
    expect(RootRepo(db).byId(offline)!.status, LibraryRootStatus.offline);
    expect(scans.status.removed, 1);
    expect(
      events.whereType<RootStatusChangedEvent>().single.root.status,
      LibraryRootStatus.offline,
    );
  });
}

extension on ScanService {
  Future<void> start2() {
    expect(start(), isTrue);
    return done;
  }
}
