import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:rs_core/rs_core.dart';
import 'package:rs_server/src/fs/fs.dart';
import 'package:rs_server/src/storage/storage.dart';
import 'package:test/test.dart';

void main() {
  late Directory tmp;
  setUp(() async => tmp = await Directory.systemTemp.createTemp('rs_storage'));
  tearDown(() async {
    if (!Platform.isWindows) {
      await Process.run('chmod', ['-R', 'u+rwx', tmp.path]);
    }
    await tmp.delete(recursive: true);
  });

  group('MarkerStore', () {
    test('write then read round-trips', () async {
      final marker = RootMarker(
        id: 'abc',
        kind: MarkerKind.library,
        label: 'HDD',
        createdAt: DateTime.utc(2026, 1, 2, 3, 4, 5),
      );
      await MarkerStore.write(tmp.path, marker);
      expect(
        File(p.join(tmp.path, '.retrosteam', 'root.json')).existsSync(),
        isTrue,
      );
      expect(await MarkerStore.read(tmp.path), marker);
      // No temp file left behind.
      expect(Directory(p.join(tmp.path, '.retrosteam')).listSync().length, 1);
    });

    test('missing or corrupt marker reads as null', () async {
      expect(await MarkerStore.read(tmp.path), isNull);
      await Directory(p.join(tmp.path, '.retrosteam')).create();
      await File(MarkerStore.markerPath(tmp.path)).writeAsString('{not json');
      expect(await MarkerStore.read(tmp.path), isNull);
      await File(MarkerStore.markerPath(tmp.path)).writeAsString('[1]');
      expect(await MarkerStore.read(tmp.path), isNull);
      await File(MarkerStore.markerPath(tmp.path))
          .writeAsString('{"id":"x","kind":"bogus","createdAt":"2026-01-01"}');
      expect(await MarkerStore.read(tmp.path), isNull);
    });
  });

  group('DataDir', () {
    test('creates layout and marker', () async {
      final path = p.join(tmp.path, 'nested', 'data');
      final dir = await DataDir.openOrCreate(path);
      expect(dir.adopted, isFalse);
      expect(dir.path, p.normalize(path));
      expect(dir.dbPath, p.join(path, 'retrosteam.db'));
      for (final d in [dir.artworkDir, dir.cacheDir, dir.tmpDir]) {
        expect(Directory(d).existsSync(), isTrue, reason: d);
      }
      final marker = await MarkerStore.read(path);
      expect(marker!.kind, MarkerKind.data);
      expect(marker.id, dir.id);
      expect(dir.hasDatabase, isFalse);
    });

    test('adopts an existing data dir with the same id', () async {
      final path = p.join(tmp.path, 'data');
      final first = await DataDir.openOrCreate(path);
      await Directory(first.artworkDir).delete();
      final second = await DataDir.openOrCreate(path);
      expect(second.adopted, isTrue);
      expect(second.id, first.id);
      expect(Directory(second.artworkDir).existsSync(), isTrue);
    });

    test('open requires a marker and checks the expected id', () async {
      await expectLater(
        DataDir.open(tmp.path),
        throwsA(isA<StorageException>()),
      );
      final dir = await DataDir.openOrCreate(tmp.path);
      expect((await DataDir.open(tmp.path, expectedId: dir.id)).id, dir.id);
      await expectLater(
        DataDir.open(tmp.path, expectedId: 'other'),
        throwsA(isA<StorageException>()),
      );
    });

    test('refuses a library root', () async {
      await const LibraryRoots().register(tmp.path);
      await expectLater(
        DataDir.openOrCreate(tmp.path),
        throwsA(isA<StorageException>()),
      );
    });

    test('clearTmp empties tmp', () async {
      final dir = await DataDir.openOrCreate(tmp.path);
      await File(p.join(dir.tmpDir, 'partial.upload')).writeAsString('x');
      await dir.clearTmp();
      expect(Directory(dir.tmpDir).listSync(), isEmpty);
    });
  });

  group('LibraryRoots', () {
    const roots = LibraryRoots();

    test('register writes a marker; registering again adopts it', () async {
      final path = p.join(tmp.path, 'roms');
      await Directory(path).create();
      final reg = await roots.register(path);
      expect(reg.status, LibraryRootStatus.online);
      expect(reg.markerWritten, isTrue);
      expect(reg.adopted, isFalse);
      expect(reg.label, 'roms');
      expect((await MarkerStore.read(path))!.id, reg.id);

      final again = await roots.register(path, label: 'My ROMs');
      expect(again.id, reg.id);
      expect(again.adopted, isTrue);
      expect(again.label, 'My ROMs');
    });

    test('register on a read-only folder: no marker, readOnly', () async {
      final path = p.join(tmp.path, 'ro');
      await Directory(path).create();
      await Process.run('chmod', ['555', path]);
      final reg = await roots.register(path);
      expect(reg.status, LibraryRootStatus.readOnly);
      expect(reg.markerWritten, isFalse);
      expect(reg.id, isNotEmpty);
      expect(await MarkerStore.read(path), isNull);
      expect(Directory(path).listSync(), isEmpty);

      // Identified again by id + last path.
      final loc = await roots.locate(reg.id, path);
      expect(loc.status, LibraryRootStatus.readOnly);
      expect(loc.path, path);

      // Becomes writable (e.g. re-mounted read-write): marker is written.
      await Process.run('chmod', ['755', path]);
      final loc2 = await roots.locate(reg.id, path, label: 'RO');
      expect(loc2.status, LibraryRootStatus.online);
      expect((await MarkerStore.read(path))!.id, reg.id);
    }, testOn: '!windows');

    test('register rejects missing paths, files and data dirs', () async {
      await expectLater(
        roots.register(p.join(tmp.path, 'missing')),
        throwsA(
          isA<FsAccessException>().having(
            (e) => e.kind,
            'kind',
            FsErrorKind.notFound,
          ),
        ),
      );
      final file = File(p.join(tmp.path, 'f'))..writeAsStringSync('x');
      await expectLater(
        roots.register(file.path),
        throwsA(isA<FsAccessException>()),
      );
      final data = await DataDir.openOrCreate(p.join(tmp.path, 'data'));
      await expectLater(
        roots.register(data.path),
        throwsA(isA<StorageException>()),
      );
    });

    test('locate: online at last path', () async {
      final path = p.join(tmp.path, 'roms');
      await Directory(path).create();
      final reg = await roots.register(path);
      final loc = await roots.locate(reg.id, path);
      expect(loc.status, LibraryRootStatus.online);
      expect(loc.path, path);
    });

    test('locate: unplugged drive is offline', () async {
      final path = p.join(tmp.path, 'roms');
      await Directory(path).create();
      final reg = await roots.register(path);
      await Directory(path).delete(recursive: true);
      final loc = await roots.locate(reg.id, path);
      expect(loc.status, LibraryRootStatus.offline);
      expect(loc.path, isNull);
    });

    test('locate: another drive at the same path is offline', () async {
      final path = p.join(tmp.path, 'roms');
      await Directory(path).create();
      final reg = await roots.register(path);
      await Directory(path).delete(recursive: true);
      await Directory(path).create();
      final other = await roots.register(path);
      expect(other.id, isNot(reg.id));
      expect(
        (await roots.locate(reg.id, path)).status,
        LibraryRootStatus.offline,
      );
    });

    test('locate: finds a drive mounted under a new path by id', () async {
      final volumes = p.join(tmp.path, 'Volumes');
      final oldPath = p.join(volumes, 'HDD');
      await Directory(oldPath).create(recursive: true);
      final reg = await roots.register(oldPath);
      final newPath = p.join(volumes, 'HDD 1');
      await Directory(oldPath).rename(newPath);
      final loc = await roots.locate(reg.id, oldPath, searchDirs: [volumes]);
      expect(loc.status, LibraryRootStatus.online);
      expect(loc.path, newPath);
    });

    test('defaultLabel', () {
      expect(LibraryRoots.defaultLabel('/Volumes/HDD/roms'), 'roms');
      expect(LibraryRoots.defaultLabel('/'), '/');
    }, testOn: '!windows');
  });
}
