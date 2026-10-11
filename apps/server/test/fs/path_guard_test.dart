import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:rs_server/src/fs/fs.dart';
import 'package:test/test.dart';

Matcher _rejects(PathRejection reason) => throwsA(
  isA<PathGuardException>().having((e) => e.reason, 'reason', reason),
);

void main() {
  group('normalizeRelative', () {
    test('canonicalizes separators and dot segments', () {
      expect(PathGuard.normalizeRelative('snes/game.sfc'), 'snes/game.sfc');
      expect(
        PathGuard.normalizeRelative(r'snes\sub\game.sfc'),
        'snes/sub/game.sfc',
      );
      expect(PathGuard.normalizeRelative('snes//./game.sfc/'), 'snes/game.sfc');
      expect(
        PathGuard.normalizeRelative('psx/Final Fantasy VII (Disc 1).cue'),
        'psx/Final Fantasy VII (Disc 1).cue',
      );
      expect(PathGuard.normalizeRelative('snes/ポケモン.sfc'), 'snes/ポケモン.sfc');
    });

    final attacks = <String, PathRejection>{
      '': PathRejection.empty,
      '.': PathRejection.empty,
      './/': PathRejection.empty,
      '..': PathRejection.parentTraversal,
      '../etc/passwd': PathRejection.parentTraversal,
      'snes/../../etc/passwd': PathRejection.parentTraversal,
      r'snes\..\..\secret': PathRejection.parentTraversal,
      'snes/..': PathRejection.parentTraversal,
      '/etc/passwd': PathRejection.absolute,
      r'\Windows\System32': PathRejection.absolute,
      r'\\server\share\file': PathRejection.absolute,
      'C:/Windows': PathRejection.driveLetter,
      r'c:\Windows': PathRejection.driveLetter,
      'C:file': PathRejection.driveLetter,
      'snes/game\u0000.sfc': PathRejection.nullByte,
      'snes/ga\nme.sfc': PathRejection.controlCharacter,
      'snes/CON': PathRejection.reservedName,
      'snes/con.txt': PathRejection.reservedName,
      'nul/game.sfc': PathRejection.reservedName,
      'snes/LPT1.sfc': PathRejection.reservedName,
      'snes/COM9': PathRejection.reservedName,
      'snes/aux .tar.gz': PathRejection.reservedName,
      'snes/game.sfc:stream': PathRejection.invalidCharacter,
      'snes/what?.sfc': PathRejection.invalidCharacter,
      'snes/a<b>.sfc': PathRejection.invalidCharacter,
      'snes/game.': PathRejection.trailingDotOrSpace,
      'snes/game ': PathRejection.trailingDotOrSpace,
      '...': PathRejection.trailingDotOrSpace,
    };
    attacks.forEach((input, reason) {
      test(
        'rejects ${input.replaceAll('\u0000', r'\0').replaceAll('\n', r'\n')}'
        ' as ${reason.name}',
        () {
          expect(() => PathGuard.normalizeRelative(input), _rejects(reason));
        },
      );
    });

    test('rejects over-long segments and paths', () {
      expect(
        () => PathGuard.normalizeRelative('snes/${'a' * 256}'),
        _rejects(PathRejection.segmentTooLong),
      );
      expect(
        () => PathGuard.normalizeRelative(List.filled(2000, 'ab').join('/')),
        _rejects(PathRejection.pathTooLong),
      );
    });

    test('allows names that only look reserved', () {
      expect(
        PathGuard.normalizeRelative('snes/console.sfc'),
        'snes/console.sfc',
      );
      expect(PathGuard.normalizeRelative('snes/COM10.sfc'), 'snes/COM10.sfc');
      expect(PathGuard.normalizeRelative('snes/..game.sfc'), 'snes/..game.sfc');
      expect(PathGuard.normalizeRelative('.hidden/x'), '.hidden/x');
    });
  });

  group('resolve', () {
    late Directory tmp;
    late PathGuard guard;
    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('rs_guard');
      guard = PathGuard(rootId: 'r1', rootPath: p.join(tmp.path, 'root'));
      await Directory(p.join(tmp.path, 'root', 'snes')).create(recursive: true);
      await File(p.join(tmp.path, 'secret.txt')).writeAsString('secret');
    });
    tearDown(() => tmp.delete(recursive: true));

    test('joins inside the root', () {
      expect(
        guard.resolve('snes/game.sfc'),
        p.join(tmp.path, 'root', 'snes', 'game.sfc'),
      );
    });

    test('rejects traversal', () {
      expect(
        () => guard.resolve('../secret.txt'),
        throwsA(isA<PathGuardException>()),
      );
      expect(
        () => guard.resolve('snes/../../secret.txt'),
        throwsA(isA<PathGuardException>()),
      );
      expect(
        () => guard.resolve(p.join(tmp.path, 'secret.txt')),
        throwsA(isA<PathGuardException>()),
      );
    });

    test('resolveSafe accepts missing files inside the root', () async {
      expect(
        await guard.resolveSafe('snes/new/game.sfc'),
        p.join(tmp.path, 'root', 'snes', 'new', 'game.sfc'),
      );
    });

    test(
      'resolveSafe rejects a symlinked file that escapes the root',
      () async {
        await Link(p.join(tmp.path, 'root', 'snes', 'evil.sfc'))
            .create(p.join(tmp.path, 'secret.txt'));
        await expectLater(
          guard.resolveSafe('snes/evil.sfc'),
          throwsA(
            isA<PathGuardException>().having(
              (e) => e.reason,
              'reason',
              PathRejection.symlinkEscape,
            ),
          ),
        );
      },
      testOn: '!windows',
    );

    test('resolveSafe rejects writes through a symlinked folder', () async {
      final outside = await Directory(p.join(tmp.path, 'outside')).create();
      await Link(p.join(tmp.path, 'root', 'psx')).create(outside.path);
      await expectLater(
        guard.resolveSafe('psx/new.cue'),
        throwsA(isA<PathGuardException>()),
      );
    }, testOn: '!windows');

    test('resolveSafe allows symlinks that stay inside the root', () async {
      await File(p.join(tmp.path, 'root', 'snes', 'real.sfc'))
          .writeAsString('x');
      await Link(p.join(tmp.path, 'root', 'snes', 'alias.sfc'))
          .create(p.join(tmp.path, 'root', 'snes', 'real.sfc'));
      expect(await guard.resolveSafe('snes/alias.sfc'), endsWith('alias.sfc'));
    }, testOn: '!windows');

    test('works when the root itself is behind a symlink', () async {
      final link = Link(p.join(tmp.path, 'rootlink'));
      await link.create(p.join(tmp.path, 'root'));
      final g = PathGuard(rootId: 'r', rootPath: link.path);
      expect(
        await g.resolveSafe('snes/x.sfc'),
        p.join(link.path, 'snes', 'x.sfc'),
      );
    }, testOn: '!windows');

    test('relativize round-trips and rejects outside paths', () {
      final abs = guard.resolve(r'snes\sub\game.sfc');
      expect(guard.relativize(abs), 'snes/sub/game.sfc');
      expect(
        () => guard.relativize(p.join(tmp.path, 'secret.txt')),
        throwsA(isA<PathGuardException>()),
      );
      expect(
        () => guard.relativize(guard.rootPath),
        throwsA(isA<PathGuardException>()),
      );
    });
  });

  group('normalizeAbsolute', () {
    test('normalizes and expands ~', () {
      expect(
        PathGuard.normalizeAbsolute('/a/b/../c/', homeDir: '/home/u'),
        p.normalize('/a/c'),
      );
      expect(
        PathGuard.normalizeAbsolute('~/roms', homeDir: '/home/u'),
        p.join('/home/u', 'roms'),
      );
      expect(PathGuard.normalizeAbsolute('~', homeDir: '/home/u'), '/home/u');
    }, testOn: '!windows');

    test('rejects relative, empty and NUL', () {
      expect(
        () => PathGuard.normalizeAbsolute('roms'),
        throwsA(isA<PathGuardException>()),
      );
      expect(
        () => PathGuard.normalizeAbsolute('  '),
        throwsA(isA<PathGuardException>()),
      );
      expect(
        () => PathGuard.normalizeAbsolute('/a\u0000b'),
        throwsA(isA<PathGuardException>()),
      );
    });
  });
}
