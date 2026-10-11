@TestOn('!windows')
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:rs_server/src/fs/fs.dart';
import 'package:rs_server/src/storage/storage.dart';
import 'package:test/test.dart';

Future<void> _touch(String path) async {
  await File(path).parent.create(recursive: true);
  await File(path).writeAsString('x');
}

void main() {
  late Directory tmp;
  const probe = PathProbe(freeSpace: _fakeFree);
  setUp(() async => tmp = await Directory.systemTemp.createTemp('rs_probe'));
  tearDown(() async {
    await Process.run('chmod', ['-R', 'u+rwx', tmp.path]);
    await tmp.delete(recursive: true);
  });

  group('library root', () {
    test('detects ES system folders and counts accepted files', () async {
      final root = p.join(tmp.path, 'roms');
      await _touch(p.join(root, 'snes', 'Mario.sfc'));
      await _touch(p.join(root, 'snes', 'Zelda.smc'));
      await _touch(p.join(root, 'snes', 'readme.txt'));
      await _touch(p.join(root, 'snes', '.hidden.sfc'));
      await _touch(p.join(root, 'snes', 'media', 'box.sfc'));
      await _touch(p.join(root, 'snes', 'Sub Game', 'game.sfc'));
      await _touch(p.join(root, 'psx', 'FF7.cue'));
      await _touch(p.join(root, 'psx', 'FF7.bin'));
      await _touch(p.join(root, 'notasystem', 'x.sfc'));
      await Directory(p.join(root, 'gba')).create();

      final r = await probe.check(root, ProbeKind.libraryRoot);
      expect(r.exists, isTrue);
      expect(r.readable, isTrue);
      expect(r.writable, isTrue);
      expect(r.permissionDenied, isFalse);
      expect(r.ok, isTrue);
      expect(r.freeBytes, 42);
      final counts = {
        for (final d in r.detectedSystems) d.systemId: d.fileCount,
      };
      // `.bin` tracks aren't psx ROM extensions on their own; `.cue` is.
      expect(counts, {'gba': 0, 'psx': 1, 'snes': 3});
      expect(r.warnings, isEmpty);
    });

    test('matches system folders case-insensitively', () async {
      final root = p.join(tmp.path, 'roms');
      await _touch(p.join(root, 'SNES', 'Mario.sfc'));
      final r = await probe.check(root, ProbeKind.libraryRoot);
      expect(r.detectedSystems.single.systemId, 'snes');
    });

    test('warns when no systems are found', () async {
      final r = await probe.check(tmp.path, ProbeKind.libraryRoot);
      expect(r.ok, isTrue);
      expect(r.warnings, contains(PathWarning.noSystemsDetected));
    });

    test('missing folder is not ok', () async {
      final r = await probe.check(
        p.join(tmp.path, 'nope'),
        ProbeKind.libraryRoot,
      );
      expect(r.exists, isFalse);
      expect(r.ok, isFalse);
      expect(r.warnings, [PathWarning.notFound]);
    });

    test('a file is not ok', () async {
      final f = p.join(tmp.path, 'file.txt');
      await _touch(f);
      final r = await probe.check(f, ProbeKind.libraryRoot);
      expect(r.ok, isFalse);
      expect(r.warnings, [PathWarning.notADirectory]);
    });

    test('read-only folder is ok for a library but flagged', () async {
      final root = p.join(tmp.path, 'roms');
      await _touch(p.join(root, 'snes', 'Mario.sfc'));
      await Process.run('chmod', ['555', root]);
      final r = await probe.check(root, ProbeKind.libraryRoot);
      expect(r.readable, isTrue);
      expect(r.writable, isFalse);
      expect(r.ok, isTrue);
      expect(r.warnings, contains(PathWarning.notWritable));
      // Nothing left behind by the write test.
      expect(Directory(root).listSync().map((e) => p.basename(e.path)), [
        'snes',
      ]);
    });

    test('unlistable folder reports permission denied', () async {
      final root = p.join(tmp.path, 'locked');
      await Directory(root).create();
      await Process.run('chmod', ['000', root]);
      final r = await probe.check(root, ProbeKind.libraryRoot);
      expect(r.readable, isFalse);
      expect(r.permissionDenied, isTrue);
      expect(r.ok, isFalse);
      expect(r.warnings, contains(PathWarning.permissionDenied));
    });

    test('reports an existing library marker', () async {
      final root = p.join(tmp.path, 'roms');
      await Directory(root).create();
      final reg = await const LibraryRoots().register(root);
      final r = await probe.check(root, ProbeKind.libraryRoot);
      expect(r.existingMarkerId, reg.id);
      expect(r.existingMarkerKind, MarkerKind.library);
    });

    test('a data folder is not ok as a library', () async {
      final data = await DataDir.openOrCreate(p.join(tmp.path, 'data'));
      final r = await probe.check(data.path, ProbeKind.libraryRoot);
      expect(r.ok, isFalse);
      expect(r.warnings, contains(PathWarning.markerKindMismatch));
    });
  });

  group('data dir', () {
    test('a missing folder under a writable parent is creatable', () async {
      final r = await probe.check(
        p.join(tmp.path, 'a', 'b', 'data'),
        ProbeKind.dataDir,
      );
      expect(r.exists, isFalse);
      expect(r.creatable, isTrue);
      expect(r.writable, isTrue);
      expect(r.ok, isTrue);
      expect(r.warnings, [PathWarning.willBeCreated]);
      expect(Directory(p.join(tmp.path, 'a')).existsSync(), isFalse);
    });

    test('a missing folder under a read-only parent is not ok', () async {
      final parent = p.join(tmp.path, 'ro');
      await Directory(parent).create();
      await Process.run('chmod', ['555', parent]);
      final r = await probe.check(p.join(parent, 'data'), ProbeKind.dataDir);
      expect(r.ok, isFalse);
      expect(r.creatable, isFalse);
    });

    test('empty writable folder is ok', () async {
      final r = await probe.check(tmp.path, ProbeKind.dataDir);
      expect(r.ok, isTrue);
      expect(r.warnings, isEmpty);
      expect(r.detectedSystems, isEmpty);
    });

    test('non-empty folder warns, existing data dir is adoptable', () async {
      await _touch(p.join(tmp.path, 'stuff.txt'));
      var r = await probe.check(tmp.path, ProbeKind.dataDir);
      expect(r.ok, isTrue);
      expect(r.warnings, [PathWarning.notEmpty]);

      final data = await DataDir.openOrCreate(p.join(tmp.path, 'data'));
      r = await probe.check(data.path, ProbeKind.dataDir);
      expect(r.existingMarkerId, data.id);
      expect(r.existingMarkerKind, MarkerKind.data);
      expect(r.warnings, isEmpty);
    });

    test('read-only folder is not ok', () async {
      await Process.run('chmod', ['555', tmp.path]);
      final r = await probe.check(tmp.path, ProbeKind.dataDir);
      expect(r.ok, isFalse);
      expect(r.warnings, contains(PathWarning.notWritable));
    });

    test('a library root is not ok as a data folder', () async {
      await const LibraryRoots().register(tmp.path);
      final r = await probe.check(tmp.path, ProbeKind.dataDir);
      expect(r.ok, isFalse);
      expect(r.warnings, contains(PathWarning.markerKindMismatch));
    });
  });

  test('rejects malformed input paths', () {
    expect(
      () => probe.check('relative/path', ProbeKind.dataDir),
      throwsA(isA<PathGuardException>()),
    );
  });

  test('normalizes the path', () async {
    final r = await probe.check('${tmp.path}/x/../', ProbeKind.dataDir);
    expect(r.path, p.normalize(tmp.path));
  });

  test('queryFreeBytes returns a real number on this machine', () async {
    final free = await queryFreeBytes(tmp.path);
    expect(free, isNotNull);
    expect(free, greaterThan(0));
  });

  test('parseDfAvailable handles spaces in names and mount points', () {
    expect(
      parseDfAvailable(
        '/dev/disk3s1  976490576 123 456789 25% /Volumes/My Drive',
      ),
      456789 * 1024,
    );
    expect(
      parseDfAvailable('map auto_home 0 0 0 100% /System/Volumes/Data/home'),
      0,
    );
    expect(parseDfAvailable('garbage'), isNull);
  });

  group('classifyFsError', () {
    test('maps POSIX codes', () {
      FileSystemException e(int code, String msg) =>
          FileSystemException('x', '/p', OSError(msg, code));
      expect(
        classifyFsError(e(1, 'Operation not permitted')),
        FsErrorKind.permissionDenied,
      );
      expect(
        classifyFsError(e(13, 'Permission denied')),
        FsErrorKind.permissionDenied,
      );
      expect(
        classifyFsError(e(30, 'Read-only file system')),
        FsErrorKind.readOnlyFilesystem,
      );
      expect(classifyFsError(e(2, 'No such file')), FsErrorKind.notFound);
      expect(
        classifyFsError(e(20, 'Not a directory')),
        FsErrorKind.notADirectory,
      );
      expect(
        classifyFsError(e(999, 'Read-only file system')),
        FsErrorKind.readOnlyFilesystem,
      );
      expect(classifyFsError(StateError('x')), FsErrorKind.other);
    });
  });
}

Future<int?> _fakeFree(String path) async => 42;
