import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:rs_core/rs_core.dart';
import 'package:rs_server/src/db/db.dart';
import 'package:rs_server/src/security/security.dart';
import 'package:test/test.dart';

ScannedGameInput _game(
  String system,
  String rel,
  String title, {
  int size = 100,
  String? sha1,
  String? region,
  List<String> extra = const [],
}) => ScannedGameInput(
  systemId: system,
  primaryRelPath: rel,
  title: title,
  region: region,
  files: [
    GameFileRecord(
      relPath: rel,
      size: size,
      mtime: DateTime.utc(2026, 1, 1),
      crc32: 'deadbeef',
      md5: 'md5',
      sha1: sha1 ?? 'sha1-$rel',
    ),
    for (final e in extra)
      GameFileRecord(relPath: e, size: 10, mtime: DateTime.utc(2026, 1, 1)),
  ],
);

void main() {
  late RsDatabase db;
  setUp(() => db = RsDatabase.inMemory());
  tearDown(() => db.close());

  group('RsDatabase', () {
    test('migrates to the latest version', () {
      expect(db.userVersion, RsDatabase.schemaVersion);
      final tables = db.db
          .select("SELECT name FROM sqlite_master WHERE type = 'table'")
          .map((r) => r['name'])
          .toSet();
      expect(
        tables,
        containsAll([
          'settings',
          'users',
          'devices',
          'sessions',
          'login_attempts',
          'roots',
          'games',
          'game_files',
          'artwork',
        ]),
      );
    });

    test('file database reopens without re-migrating and is bundled', () async {
      final tmp = await Directory.systemTemp.createTemp('rs_db');
      try {
        final path = p.join(tmp.path, 'retrosteam.db');
        var file = RsDatabase.open(path);
        SettingsRepo(file).set('k', 'v');
        file.close();
        file = RsDatabase.open(path);
        expect(file.userVersion, RsDatabase.schemaVersion);
        expect(SettingsRepo(file).get('k'), 'v');
        file.close();
        // Closing checkpoints the WAL: one self-contained file.
        expect(File('$path-wal').existsSync(), isFalse);
      } finally {
        await tmp.delete(recursive: true);
      }
    });

    test('refuses a database from a newer version', () async {
      final tmp = await Directory.systemTemp.createTemp('rs_db');
      try {
        final path = p.join(tmp.path, 'x.db');
        final file = RsDatabase.open(path);
        file.db.userVersion = 99;
        file.close();
        expect(() => RsDatabase.open(path), throwsA(isA<DatabaseException>()));
      } finally {
        await tmp.delete(recursive: true);
      }
    });

    test('transaction rolls back on error', () {
      final settings = SettingsRepo(db);
      expect(
        () => db.transaction(() {
          settings.set('a', '1');
          throw StateError('boom');
        }),
        throwsStateError,
      );
      expect(settings.get('a'), isNull);
    });
  });

  test('SettingsRepo', () {
    final s = SettingsRepo(db);
    expect(s.get('x'), isNull);
    s.set('x', '1');
    s.set('x', '2');
    s.set('y', '3');
    expect(s.get('x'), '2');
    expect(s.all(), {'x': '2', 'y': '3'});
    s.remove('x');
    expect(s.get('x'), isNull);
  });

  group('UserRepo', () {
    test('create, lookup case-insensitively, single admin', () {
      final users = UserRepo(db);
      expect(users.hasAdmin(), isFalse);
      final admin = users.create(
        username: 'Admin',
        role: UserRole.admin,
        passwordHash: 'h',
      );
      expect(users.hasAdmin(), isTrue);
      expect(users.byUsername('admin')!.id, admin.id);
      expect(users.byId(admin.id)!.isAdmin, isTrue);
      expect(
        () => users.create(
          username: 'other',
          role: UserRole.admin,
          passwordHash: 'h',
        ),
        throwsA(isA<ConflictException>()),
      );
      expect(
        () => users.create(
          username: 'ADMIN',
          role: UserRole.user,
          passwordHash: 'h',
        ),
        throwsA(isA<ConflictException>()),
      );
      users.create(username: 'bob', role: UserRole.user, passwordHash: 'h');
      expect(users.all().map((u) => u.username), ['Admin', 'bob']);
      expect(users.count(), 2);
    });

    test('update password and delete (admin is protected)', () {
      final users = UserRepo(db);
      final admin = users.create(
        username: 'a',
        role: UserRole.admin,
        passwordHash: 'h',
      );
      final bob = users.create(
        username: 'bob',
        role: UserRole.user,
        passwordHash: 'h',
      );
      users.updatePasswordHash(bob.id, 'h2');
      expect(users.byId(bob.id)!.passwordHash, 'h2');
      expect(users.delete(admin.id), isFalse);
      expect(users.delete(bob.id), isTrue);
      expect(users.byId(bob.id), isNull);
    });
  });

  group('DeviceRepo and SessionRepo', () {
    late UserRecord user;
    late DeviceRecord device;
    late String deviceToken;
    setUp(() {
      user = UserRepo(db)
          .create(username: 'u', role: UserRole.user, passwordHash: 'h');
      deviceToken = Tokens.generate();
      device = DeviceRepo(db).create(
        name: 'Mac',
        platform: 'macos',
        tokenHash: Tokens.hash(deviceToken),
      );
    });

    test('device lookup by token hash, touch, revoke', () {
      final devices = DeviceRepo(db);
      expect(devices.byTokenHash(Tokens.hash(deviceToken))!.id, device.id);
      expect(devices.byTokenHash(Tokens.hash('wrong')), isNull);
      // The plain token is never stored.
      final raw = db.db.select('SELECT * FROM devices').first;
      expect(raw.values, isNot(contains(deviceToken)));

      final t = DateTime.utc(2026, 5, 5);
      devices.touch(device.id, now: t);
      expect(devices.byId(device.id)!.lastSeenAt, t);

      expect(devices.revoke(device.id), isTrue);
      expect(devices.revoke(device.id), isFalse);
      expect(devices.byTokenHash(Tokens.hash(deviceToken)), isNull);
      expect(devices.byId(device.id)!.revoked, isTrue);
      expect(devices.all(), hasLength(1));
    });

    test('session validate slides expiry; expired sessions are deleted', () {
      final sessions = SessionRepo(db, ttl: const Duration(days: 1));
      final token = Tokens.generate();
      final t0 = DateTime.utc(2026, 1, 1);
      sessions.create(
        userId: user.id,
        deviceId: device.id,
        tokenHash: Tokens.hash(token),
        now: t0,
      );
      final t1 = t0.add(const Duration(hours: 20));
      final s = sessions.validate(Tokens.hash(token), now: t1)!;
      expect(s.userId, user.id);
      expect(s.expiresAt, t1.add(const Duration(days: 1)));
      // Still valid 2 days after creation thanks to sliding.
      expect(
        sessions.validate(
          Tokens.hash(token),
          now: t0.add(const Duration(days: 1, hours: 10)),
        ),
        isNotNull,
      );
      expect(
        sessions.validate(
          Tokens.hash(token),
          now: t0.add(const Duration(days: 10)),
        ),
        isNull,
      );
      expect(sessions.forUser(user.id), isEmpty);
    });

    test('sessions die with their device or user', () {
      final sessions = SessionRepo(db);
      final token = Tokens.generate();
      sessions.create(
        userId: user.id,
        deviceId: device.id,
        tokenHash: Tokens.hash(token),
      );
      DeviceRepo(db).revoke(device.id);
      expect(sessions.validate(Tokens.hash(token)), isNull);

      final d2 = DeviceRepo(db)
          .create(name: 'b', platform: 'web', tokenHash: 'x');
      final t2 = Tokens.generate();
      sessions.create(
        userId: user.id,
        deviceId: d2.id,
        tokenHash: Tokens.hash(t2),
      );
      UserRepo(db).delete(user.id);
      expect(sessions.validate(Tokens.hash(t2)), isNull);
    });

    test('logout and purge', () {
      final sessions = SessionRepo(db, ttl: const Duration(hours: 1));
      final a = Tokens.generate();
      final b = Tokens.generate();
      final t = DateTime.utc(2026, 1, 1);
      sessions.create(
        userId: user.id,
        deviceId: device.id,
        tokenHash: Tokens.hash(a),
        now: t,
      );
      sessions.create(
        userId: user.id,
        deviceId: device.id,
        tokenHash: Tokens.hash(b),
        now: t,
      );
      sessions.deleteByTokenHash(Tokens.hash(a));
      expect(sessions.forUser(user.id), hasLength(1));
      expect(sessions.purgeExpired(now: t.add(const Duration(hours: 2))), 1);
      expect(sessions.forUser(user.id), isEmpty);
    });
  });

  test('LoginAttemptRepo persists rate limiter state', () {
    var now = DateTime.utc(2026, 1, 1);
    final repo = LoginAttemptRepo(db);
    var limiter = LoginRateLimiter(store: repo, clock: () => now);
    for (var i = 0; i < 5; i++) {
      limiter.recordFailure('admin', address: '1.2.3.4');
    }
    // A "restart": new limiter, same database.
    limiter = LoginRateLimiter(store: LoginAttemptRepo(db), clock: () => now);
    expect(limiter.check('admin').allowed, isFalse);
    now = now.add(const Duration(minutes: 6));
    expect(limiter.check('admin').allowed, isTrue);
    limiter.recordSuccess('admin');
    expect(repo.get(LoginRateLimiter.userKey('admin')), isNull);
    expect(repo.get(LoginRateLimiter.addressKey('1.2.3.4')), isNotNull);
    repo.purge(now.add(const Duration(days: 1)));
    expect(repo.get(LoginRateLimiter.addressKey('1.2.3.4')), isNull);
  });

  group('RootRepo', () {
    test('upsert, list, status, rename, delete cascades games', () {
      final roots = RootRepo(db);
      roots.upsert(
        id: 'r1',
        label: 'HDD',
        lastPath: '/Volumes/HDD/roms',
        status: LibraryRootStatus.online,
      );
      roots.upsert(
        id: 'r1',
        label: 'HDD2',
        lastPath: '/Volumes/HDD 1/roms',
        status: LibraryRootStatus.readOnly,
      );
      final r = roots.byId('r1')!;
      expect(r.label, 'HDD2');
      expect(r.lastPath, '/Volumes/HDD 1/roms');
      expect(r.status, LibraryRootStatus.readOnly);
      roots.updateStatus('r1', LibraryRootStatus.offline);
      expect(roots.byId('r1')!.status, LibraryRootStatus.offline);
      roots.updateStatus('r1', LibraryRootStatus.online, lastPath: '/mnt/roms');
      expect(roots.byId('r1')!.lastPath, '/mnt/roms');
      roots.rename('r1', 'Games');
      expect(roots.all().single.label, 'Games');

      GameRepo(db).upsertScanned('r1', [_game('snes', 'snes/a.sfc', 'A')]);
      expect(GameRepo(db).count(), 1);
      expect(roots.delete('r1'), isTrue);
      expect(GameRepo(db).count(), 0);
    });
  });

  group('GameRepo', () {
    late GameRepo games;
    setUp(() {
      RootRepo(db)
        ..upsert(
          id: 'r1',
          label: 'A',
          lastPath: '/a',
          status: LibraryRootStatus.online,
        )
        ..upsert(
          id: 'r2',
          label: 'B',
          lastPath: '/b',
          status: LibraryRootStatus.online,
        );
      games = GameRepo(db);
    });

    test('first scan adds everything', () {
      final diff = games.upsertScanned('r1', [
        _game('snes', 'snes/Mario.sfc', 'Super Mario World', region: 'USA'),
        _game(
          'psx',
          'psx/FF7.cue',
          'Final Fantasy VII',
          extra: ['psx/FF7 (Track 1).bin', 'psx/FF7 (Track 2).bin'],
        ),
      ]);
      expect(diff.added, hasLength(2));
      expect(diff.updated, isEmpty);
      expect(diff.removed, isEmpty);
      final ff7 = games.byId(diff.added[1])!;
      expect(ff7.files.map((f) => f.relPath), [
        'psx/FF7.cue',
        'psx/FF7 (Track 1).bin',
        'psx/FF7 (Track 2).bin',
      ]);
      expect(ff7.sizeBytes, 120);
      expect(ff7.rootId, 'r1');
      expect(ff7.primaryRelPath, 'psx/FF7.cue');
      final mario = games.byId(diff.added[0])!;
      expect(mario.region, 'USA');
      expect(mario.files.single.sha1, 'sha1-snes/Mario.sfc');
    });

    test('rescan diff: unchanged, updated, added, removed; ids are stable', () {
      final t0 = DateTime.utc(2026, 1, 1);
      final first = games.upsertScanned('r1', [
        _game('snes', 'snes/a.sfc', 'A'),
        _game('snes', 'snes/b.sfc', 'B'),
        _game('snes', 'snes/c.sfc', 'C'),
      ], now: t0);
      final ids = first.added;
      final diff = games.upsertScanned('r1', [
        _game('snes', 'snes/a.sfc', 'A'), // unchanged
        _game('snes', 'snes/b.sfc', 'B', size: 999, sha1: 'new'), // updated
        _game('snes', 'snes/d.sfc', 'D'), // added
      ], now: t0.add(const Duration(days: 1)));
      expect(diff.updated, [ids[1]]);
      expect(diff.removed, [ids[2]]);
      expect(diff.added, hasLength(1));
      expect(games.byId(ids[0])!.updatedAt, t0);
      final b = games.byId(ids[1])!;
      expect(b.files.single.size, 999);
      expect(b.addedAt, t0);
      expect(b.updatedAt, t0.add(const Duration(days: 1)));
      expect(games.byId(ids[2]), isNull);

      final noop = games.upsertScanned('r1', [
        _game('snes', 'snes/a.sfc', 'A'),
        _game('snes', 'snes/b.sfc', 'B', size: 999, sha1: 'new'),
        _game('snes', 'snes/d.sfc', 'D'),
      ]);
      expect(noop.isEmpty, isTrue);
    });

    test(
      'scans are per root and partial scans only remove scanned systems',
      () {
        games.upsertScanned('r1', [
          _game('snes', 'snes/a.sfc', 'A'),
          _game('nes', 'nes/n.nes', 'N'),
        ]);
        games.upsertScanned('r2', [_game('snes', 'snes/a.sfc', 'A')]);
        expect(games.count(), 3);
        expect(games.count(rootId: 'r2'), 1);

        final partial = games.upsertScanned('r1', [], systems: {'snes'});
        expect(partial.removed, hasLength(1));
        expect(games.list(systemId: 'nes').total, 1);
        expect(games.count(rootId: 'r2'), 1);
      },
    );

    test('scraped metadata survives a rescan', () {
      final id = games
          .upsertScanned('r1', [_game('snes', 'snes/a.sfc', 'A')])
          .added
          .single;
      games.updateMetadata(
        id,
        description: 'desc',
        developer: 'Nintendo',
        releaseYear: 1990,
      );
      games.upsertScanned('r1', [_game('snes', 'snes/a.sfc', 'A', size: 5)]);
      final g = games.byId(id)!;
      expect(g.description, 'desc');
      expect(g.developer, 'Nintendo');
      expect(g.releaseYear, 1990);
      expect(g.publisher, isNull);
    });

    test('rejects absolute or traversing ROM paths', () {
      for (final bad in [
        '/Volumes/HDD/snes/a.sfc',
        '../a.sfc',
        r'snes\a.sfc',
        r'C:\roms\a.sfc',
        'snes/./a.sfc',
      ]) {
        expect(
          () => games.upsertScanned('r1', [_game('snes', bad, 'A')]),
          throwsArgumentError,
          reason: bad,
        );
      }
      expect(games.count(), 0);
    });

    test('list: filter, search, sort, paging', () {
      final t = DateTime.utc(2026, 1, 1);
      games.upsertScanned('r1', [
        _game('snes', 'snes/zelda.sfc', 'zelda'),
      ], now: t);
      games.upsertScanned('r2', [
        _game('snes', 'snes/mario.sfc', 'Super Mario World'),
        _game('nes', 'nes/mario.nes', 'Super Mario Bros.'),
        _game('psx', 'psx/x.cue', '100% Orange_Juice'),
      ], now: t.add(const Duration(days: 1)));

      var r = games.list();
      expect(r.total, 4);
      expect(r.games.map((g) => g.title), [
        '100% Orange_Juice',
        'Super Mario Bros.',
        'Super Mario World',
        'zelda',
      ]);
      expect(r.games.first.files, isNotEmpty);

      r = games.list(systemId: 'snes');
      expect(r.games.map((g) => g.title), ['Super Mario World', 'zelda']);

      r = games.list(query: 'MARIO');
      expect(r.total, 2);
      r = games.list(query: 'mario', systemId: 'nes');
      expect(r.games.single.systemId, 'nes');

      // LIKE wildcards in the query are literal.
      expect(games.list(query: '%').total, 1);
      expect(games.list(query: '_').total, 1);
      expect(games.list(query: "'; DROP TABLE games; --").total, 0);
      expect(games.count(), 4);

      r = games.list(sort: GameOrder.recent);
      expect(r.games.last.title, 'zelda');

      r = games.list(offset: 1, limit: 2);
      expect(r.total, 4);
      expect(r.games.map((g) => g.title), [
        'Super Mario Bros.',
        'Super Mario World',
      ]);
      expect(games.list(offset: 3).games.single.title, 'zelda');
    });

    test('systemCounts only lists systems with games', () {
      games.upsertScanned('r1', [
        _game('snes', 'snes/a.sfc', 'A'),
        _game('snes', 'snes/b.sfc', 'B'),
        _game('nes', 'nes/n.nes', 'N'),
      ]);
      expect(
        {for (final c in games.systemCounts()) c.systemId: c.gameCount},
        {'nes': 1, 'snes': 2},
      );
    });

    test('fileIndex for rescans', () {
      games.upsertScanned('r1', [
        _game('psx', 'psx/a.cue', 'A', extra: ['psx/a.bin']),
      ]);
      final index = games.fileIndex('r1');
      expect(index.keys, unorderedEquals(['psx/a.cue', 'psx/a.bin']));
      expect(index['psx/a.cue']!.size, 100);
      expect(games.fileIndex('r2'), isEmpty);
    });

    test('delete', () {
      final id = games
          .upsertScanned('r1', [_game('snes', 'snes/a.sfc', 'A')])
          .added
          .single;
      expect(games.delete(id), isTrue);
      expect(games.delete(id), isFalse);
      expect(db.db.select('SELECT * FROM game_files'), isEmpty);
    });

    test('large batch stays fast and pages load files in chunks', () {
      final input = [
        for (var i = 0; i < 2000; i++) _game('snes', 'snes/g$i.sfc', 'Game $i'),
      ];
      final sw = Stopwatch()..start();
      expect(games.upsertScanned('r1', input).added, hasLength(2000));
      expect(games.list().games, hasLength(2000));
      expect(games.list().games.every((g) => g.files.length == 1), isTrue);
      expect(sw.elapsed, lessThan(const Duration(seconds: 10)));
    });
  });
}
