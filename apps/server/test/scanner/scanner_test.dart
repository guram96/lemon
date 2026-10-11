import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:rs_core/rs_core.dart';
import 'package:rs_server/src/scanner/scanner.dart';
import 'package:test/test.dart';

const _fast = ScannerOptions(hashWorkers: 2, progressInterval: Duration.zero);

void main() {
  late Directory root;

  File write(String rel, String content) {
    final f = File(p.joinAll([root.path, ...rel.split('/')]));
    f.parent.createSync(recursive: true);
    f.writeAsStringSync(content);
    return f;
  }

  setUp(() async {
    root = await Directory.systemTemp.createTemp('rs_scan_');
  });
  tearDown(() async {
    // Restore permissions changed by tests so cleanup works.
    if (!Platform.isWindows) {
      await Process.run('chmod', ['-R', 'u+rwx', root.path]);
    }
    await root.delete(recursive: true);
  });

  Future<ScanResult> scan({
    ScanIndex? previous,
    ScannerOptions options = _fast,
    List<ScanProgress>? progress,
    List<ScannedGame>? games,
  }) {
    final job = const Scanner(options: _fast)
        .scan(rootId: 'root-1', rootPath: root.path, previous: previous);
    if (progress != null) job.progress.listen(progress.add);
    if (games != null) job.games.listen(games.add);
    return job.result;
  }

  void buildLibrary() {
    write('snes/Super Mario World (USA) [!].sfc', 'smw');
    write('snes/Zelda (U).SMC', 'zelda');
    write('snes/notes.txt', 'ignore me');
    write('snes/.hidden.sfc', 'hidden');
    write('snes/._AppleDouble.sfc', 'resource fork');
    write('snes/media/covers/x.sfc', 'not a rom');
    write('snes/images/y.sfc', 'not a rom');
    write('snes/Hacks/Kaizo (Hack).sfc', 'kaizo');
    write('.retrosteam/root.json', '{}');
    write('notasystem/game.sfc', 'nope');
    write('psx/Crash (USA).cue', 'FILE "Crash (USA).bin" BINARY\n');
    write('psx/Crash (USA).bin', 'crash-data');
    write('psx/FF7/FF7.m3u', 'FF7 (Disc 1).chd\nFF7 (Disc 2).chd\n');
    write('psx/FF7/FF7 (Disc 1).chd', 'd1');
    write('psx/FF7/FF7 (Disc 2).chd', 'd2');
    write('psx/MGS (USA) (Disc 1).chd', 'm1');
    write('psx/MGS (USA) (Disc 2).chd', 'm2');
    write('ps3/Demons Souls (USA).ps3/PS3_DISC.SFB', 'sfb');
    write('ps3/Demons Souls (USA).ps3/PS3_GAME/USRDIR/EBOOT.BIN', 'eboot');
  }

  test('scans a fixture library end to end', () async {
    buildLibrary();
    final progress = <ScanProgress>[];
    final streamed = <ScannedGame>[];
    final result = await scan(progress: progress, games: streamed);

    expect(result.rootId, 'root-1');
    expect(result.systemIds, {'snes', 'psx', 'ps3'});
    expect(result.games.map((g) => g.primaryRelPath), [
      'ps3/Demons Souls (USA).ps3',
      'psx/Crash (USA).cue',
      'psx/FF7/FF7.m3u',
      'psx/MGS (USA) (Disc 1).chd',
      'snes/Hacks/Kaizo (Hack).sfc',
      'snes/Super Mario World (USA) [!].sfc',
      'snes/Zelda (U).SMC',
    ]);
    final byPath = {for (final g in result.games) g.primaryRelPath: g};
    final smw = byPath['snes/Super Mario World (USA) [!].sfc']!;
    expect(smw.title, 'Super Mario World');
    expect(smw.region, 'USA');
    expect(smw.systemId, 'snes');
    expect(
      smw.key,
      const GameKey('root-1', 'snes', 'snes/Super Mario World (USA) [!].sfc'),
    );
    final f = smw.files.single;
    expect(f.size, 3);
    expect(f.md5, md5.convert(utf8.encode('smw')).toString());
    expect(f.sha1, sha1.convert(utf8.encode('smw')).toString());
    expect(f.crc32, hasLength(8));
    expect(f.partialHash, isFalse);

    expect(byPath['psx/Crash (USA).cue']!.files, hasLength(2));
    expect(byPath['psx/FF7/FF7.m3u']!.discCount, 2);
    expect(byPath['psx/FF7/FF7.m3u']!.files, hasLength(3));
    expect(byPath['psx/MGS (USA) (Disc 1).chd']!.discCount, 2);
    final ps3 = byPath['ps3/Demons Souls (USA).ps3']!;
    expect(ps3.isDirectory, isTrue);
    expect(ps3.files.map((f) => f.relPath), [
      'ps3/Demons Souls (USA).ps3/PS3_DISC.SFB',
      'ps3/Demons Souls (USA).ps3/PS3_GAME/USRDIR/EBOOT.BIN',
    ]);
    // Every rel path uses '/' and is relative.
    for (final g in result.games) {
      for (final f in g.files) {
        expect(f.relPath, isNot(contains(r'\')));
        expect(p.isAbsolute(f.relPath), isFalse);
      }
    }
    expect(result.filesHashed, 12);
    expect(result.filesReused, 0);
    expect(result.warnings, isEmpty);

    expect(
      streamed.map((g) => g.key).toSet(),
      result.games.map((g) => g.key).toSet(),
    );
    expect(progress.first.phase, ScannerPhase.discovering);
    expect(progress.any((e) => e.phase == ScannerPhase.hashing), isTrue);
    expect(progress.last.phase, ScannerPhase.done);
    expect(progress.last.processed, 12);
    expect(progress.last.total, 12);
    expect(progress.last.fraction, 1);
    expect(progress.where((e) => e.currentFile != null), isNotEmpty);
  });

  test('progress is throttled', () async {
    for (var i = 0; i < 50; i++) {
      write('nes/game $i.nes', 'rom $i');
    }
    final job = const Scanner(
      options: ScannerOptions(progressInterval: Duration(hours: 1)),
    ).scan(rootId: 'r', rootPath: root.path);
    final events = <ScanProgress>[];
    job.progress.listen(events.add);
    final result = await job.result;
    expect(result.games, hasLength(50));
    // Only phase changes + final event.
    expect(events.map((e) => e.phase), [
      ScannerPhase.discovering,
      ScannerPhase.hashing,
      ScannerPhase.done,
    ]);
  });

  test('system folders match case-insensitively', () async {
    write('SNES/Game.sfc', 'x');
    final result = await scan();
    expect(result.games.single.systemId, 'snes');
    expect(result.games.single.primaryRelPath, 'SNES/Game.sfc');
  });

  test('incremental rescan reuses hashes when size and mtime match', () async {
    buildLibrary();
    final first = await scan();
    final index = ScanIndex([for (final g in first.games) ...g.files]);

    final second = await scan(previous: index);
    expect(second.filesHashed, 0);
    expect(second.filesReused, 12);

    // Change one file (different size) and touch another with a new mtime.
    write('snes/Zelda (U).SMC', 'zelda v2');
    final smw = File(
      p.join(root.path, 'snes', 'Super Mario World (USA) [!].sfc'),
    );
    smw.setLastModifiedSync(DateTime.now().add(const Duration(days: 1)));
    final third = await scan(previous: index);
    expect(third.filesHashed, 2);
    expect(third.filesReused, 10);
    final zelda = third.games.firstWhere((g) => g.title == 'Zelda');
    expect(
      zelda.files.single.md5,
      md5.convert(utf8.encode('zelda v2')).toString(),
    );
  });

  test('reused hashes come from the index, not from disk', () async {
    final f = write('gb/Tetris (World).gb', 'tetris');
    final stat = f.statSync();
    final index = ScanIndex([
      ScannedFile(
        relPath: 'GB/tetris (world).GB', // case-only difference still hits
        size: stat.size,
        modified: stat.modified.toUtc(),
        crc32: 'deadbeef',
        md5: 'm',
        sha1: 's',
      ),
    ]);
    final result = await scan(previous: index);
    expect(result.games.single.files.single.crc32, 'deadbeef');
    expect(result.filesReused, 1);
  });

  test('partial hashing above the threshold', () async {
    write('psx/Big.iso', 'x' * 4096);
    write('psx/Small.iso', 'y' * 100);
    final job = const Scanner(
      options: ScannerOptions(
        partialHashThreshold: 1024,
        partialHashChunk: 256,
      ),
    ).scan(rootId: 'r', rootPath: root.path);
    final result = await job.result;
    final byTitle = {for (final g in result.games) g.title: g.files.single};
    expect(byTitle['Big']!.partialHash, isTrue);
    expect(byTitle['Small']!.partialHash, isFalse);
  });

  test('cancel before start', () async {
    buildLibrary();
    final job = const Scanner(options: _fast)
        .scan(rootId: 'r', rootPath: root.path);
    final events = <ScanProgress>[];
    job.progress.listen(events.add);
    job.cancel();
    await expectLater(job.result, throwsA(isA<ScanCancelledException>()));
    expect(events.last.phase, ScannerPhase.cancelled);
    expect(job.isCancelled, isTrue);
  });

  test('cancel during hashing', () async {
    for (var i = 0; i < 300; i++) {
      write('gba/Game $i.gba', 'data $i' * 100);
    }
    final job = const Scanner(
      options: ScannerOptions(hashWorkers: 1, progressInterval: Duration.zero),
    ).scan(rootId: 'r', rootPath: root.path);
    final events = <ScanProgress>[];
    job.progress.listen((e) {
      events.add(e);
      if (e.phase == ScannerPhase.hashing && e.processed >= 3) job.cancel();
    });
    final games = <ScannedGame>[];
    job.games.listen(games.add);
    await expectLater(job.result, throwsA(isA<ScanCancelledException>()));
    expect(events.last.phase, ScannerPhase.cancelled);
    expect(games.length, lessThan(300));
  });

  test('missing root fails with ScanException', () async {
    final job = const Scanner().scan(
      rootId: 'r',
      rootPath: p.join(root.path, 'does-not-exist'),
    );
    final events = <ScanProgress>[];
    job.progress.listen(events.add);
    await expectLater(job.result, throwsA(isA<ScanException>()));
    expect(events.last.phase, ScannerPhase.failed);
  });

  test('symlinks are skipped with a warning', () async {
    final target = write('outside.sfc', 'x');
    Directory(p.join(root.path, 'snes')).createSync();
    Link(p.join(root.path, 'snes', 'link.sfc')).createSync(target.path);
    final result = await scan();
    expect(result.games, isEmpty);
    expect(result.warnings.single.kind, ScanWarningKind.skippedLink);
    expect(result.warnings.single.relPath, 'snes/link.sfc');
  }, testOn: '!windows');

  test('unreadable files and folders become warnings', () async {
    write('snes/ok.sfc', 'ok');
    final locked = write('snes/locked.sfc', 'locked');
    write('snes/private/inner.sfc', 'inner');
    await Process.run('chmod', ['000', locked.path]);
    await Process.run('chmod', ['000', p.join(root.path, 'snes', 'private')]);
    // Running as root ignores permissions; skip in that case.
    if (File(locked.path).existsSync()) {
      try {
        File(locked.path).readAsBytesSync();
        markTestSkipped('permissions are not enforced for this user');
        return;
      } on FileSystemException {
        // expected
      }
    }

    final result = await scan();
    final byPath = {for (final g in result.games) g.primaryRelPath: g};
    expect(byPath.keys, containsAll(['snes/ok.sfc', 'snes/locked.sfc']));
    expect(byPath['snes/ok.sfc']!.files.single.hasHashes, isTrue);
    expect(byPath['snes/locked.sfc']!.files.single.hasHashes, isFalse);
    final kinds = result.warnings.map((w) => w.kind).toSet();
    expect(kinds, {
      ScanWarningKind.unreadableFile,
      ScanWarningKind.unreadableDirectory,
    });
    expect(
      result.warnings.map((w) => w.relPath),
      containsAll(['snes/locked.sfc', 'snes/private']),
    );
    expect(result.filesHashed, 1);
  }, testOn: '!windows');

  test('only requested systems are scanned', () async {
    buildLibrary();
    final job = const Scanner(options: _fast).scan(
      rootId: 'r',
      rootPath: root.path,
      systems: [GameSystems.byId('snes')!],
    );
    final result = await job.result;
    expect(result.systemIds, {'snes'});
    expect(result.games.every((g) => g.systemId == 'snes'), isTrue);
  });
}
