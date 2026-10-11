import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:rs_server/src/fs/fs.dart';
import 'package:test/test.dart';

void main() {
  late Directory tmp;
  late String home;
  late String volumes;
  late DirectoryBrowser browser;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('rs_browse');
    home = p.join(tmp.path, 'home');
    volumes = p.join(tmp.path, 'Volumes');
    for (final d in [
      p.join(home, 'Desktop'),
      p.join(home, 'Documents'),
      p.join(home, 'beta'),
      p.join(home, 'Alpha'),
      p.join(home, '.hidden'),
      p.join(volumes, 'HDD'),
      p.join(volumes, 'SSD'),
      p.join(volumes, '.Trashes'),
    ]) {
      await Directory(d).create(recursive: true);
    }
    await File(p.join(home, 'file.txt')).writeAsString('x');
    browser = DirectoryBrowser(
      homeDir: home,
      os: HostOs.macos,
      volumeParents: [volumes],
    );
  });
  tearDown(() async {
    if (!Platform.isWindows) {
      await Process.run('chmod', ['-R', 'u+rwx', tmp.path]);
    }
    await tmp.delete(recursive: true);
  });

  test('null path lists home: folders only, sorted, no hidden', () async {
    final r = await browser.browse(null);
    expect(r.path, home);
    expect(r.parent, tmp.path);
    expect(r.entries.map((e) => e.name), [
      'Alpha',
      'beta',
      'Desktop',
      'Documents',
    ]);
    expect(r.entries.every((e) => e.isDirectory && e.readable), isTrue);
    expect(r.entries.first.path, p.join(home, 'Alpha'));
  });

  test('showHidden includes dot folders', () async {
    final r = await browser.browse(home, showHidden: true);
    expect(r.entries.map((e) => e.name), contains('.hidden'));
  });

  test('shortcuts: home folders then volumes', () async {
    final r = await browser.browse(home);
    expect(r.shortcuts.map((s) => s.name), [
      'Home',
      'Desktop',
      'Documents',
      'HDD',
      'SSD',
    ]);
    expect(r.shortcuts[3].path, p.join(volumes, 'HDD'));
  });

  test('volume symlinked to the filesystem root is skipped', () async {
    await Link(p.join(volumes, 'Macintosh HD')).create('/');
    final shortcuts = await browser.shortcuts();
    expect(shortcuts.map((s) => s.name), isNot(contains('Macintosh HD')));
  }, testOn: '!windows');

  test('filesystem root has no parent', () async {
    final r = await browser.browse(p.rootPrefix(tmp.path));
    expect(r.parent, isNull);
  });

  test('missing path and file path throw FsAccessException', () async {
    await expectLater(
      browser.browse(p.join(home, 'nope')),
      throwsA(
        isA<FsAccessException>().having(
          (e) => e.kind,
          'kind',
          FsErrorKind.notFound,
        ),
      ),
    );
    await expectLater(
      browser.browse(p.join(home, 'file.txt')),
      throwsA(
        isA<FsAccessException>().having(
          (e) => e.kind,
          'kind',
          FsErrorKind.notADirectory,
        ),
      ),
    );
  });

  test('relative paths are rejected', () async {
    await expectLater(
      browser.browse('home/x'),
      throwsA(isA<PathGuardException>()),
    );
  });

  test('unreadable folders are marked and browsing them is denied', () async {
    final locked = p.join(home, 'Locked');
    await Directory(locked).create();
    await Process.run('chmod', ['000', locked]);
    final r = await browser.browse(home);
    final entry = r.entries.singleWhere((e) => e.name == 'Locked');
    expect(entry.readable, isFalse);
    await expectLater(
      browser.browse(locked),
      throwsA(
        isA<FsAccessException>().having(
          (e) => e.kind,
          'kind',
          FsErrorKind.permissionDenied,
        ),
      ),
    );
  }, testOn: '!windows');

  test('linux volume parents include /media/<user> and /mnt', () {
    final b = DirectoryBrowser(homeDir: home, os: HostOs.linux);
    expect(b.volumeParents, containsAll(['/media', '/mnt']));
  });

  test('windows drive shortcuts', () async {
    final b = DirectoryBrowser(
      homeDir: home,
      os: HostOs.windows,
      driveLetters: ['C'],
    );
    final s = await b.shortcuts();
    expect(s.map((e) => e.name), contains('Home'));
  });
}
