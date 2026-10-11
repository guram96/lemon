// End-to-end API flow over real HTTP and WebSocket. Tests run in order and
// share one server: unconfigured → setup → library → auth → restart.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:rs_core/rs_core.dart';
import 'package:rs_server/rs_server.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:test/test.dart';

import 'api_test_harness.dart';

void main() {
  late TestServer s;
  late AuthResult admin;
  late String pendingDeviceToken;
  final events = <ServerEvent>[];
  StreamSubscription<ServerEvent>? eventSub;

  setUpAll(() async {
    s = await TestServer.start();
    s.buildLibrary();
    eventSub = s.ctx.events.stream.listen(events.add);
  });
  tearDownAll(() async {
    await eventSub?.cancel();
    await s.close();
  });

  String device() => admin.deviceToken!;
  String session() => admin.sessionToken;

  SetupRequest setupRequest({
    String password = 'correct horse',
    List<String>? roots,
    String? dataDir,
  }) => SetupRequest(
    adminUsername: 'admin',
    adminPassword: password,
    dataDir: dataDir ?? s.dataDir,
    libraryRoots: roots ?? [s.romsDir],
    deviceName: 'Test Mac',
  );

  group('unconfigured', () {
    test('server info reports unconfigured', () async {
      final r = await s.get(ApiRoutes.serverInfo);
      expect(r.statusCode, 200);
      final info = ServerInfo.fromJson(decodeObject(r));
      expect(info.setupState, ServerSetupState.unconfigured);
      expect(info.platform, Platform.operatingSystem);
      expect(r.headers['access-control-allow-origin'], '*');
    });

    test('library routes answer 409 setup_required', () async {
      final r = await s.get(ApiRoutes.libraryGames);
      expect(r.statusCode, 409);
      expect(decodeError(r).code, ApiErrorCodes.setupRequired);
    });

    test('events socket is closed with 4401', () async {
      final ws = await s.connectEvents(device: 'x' * 43, session: 'y' * 43);
      await ws.drain<void>();
      expect(ws.closeCode, wsUnauthorized);
    });

    test('local device join works before setup', () async {
      final r = await s.post(
        ApiRoutes.devicesLocal,
        body: const DeviceJoinRequest(
          deviceName: 'Other client',
          platform: 'macos',
        ).toJson(),
      );
      expect(r.statusCode, 200);
      final joined = DeviceJoinResult.fromJson(decodeObject(r));
      expect(joined.deviceToken, hasLength(43));
      pendingDeviceToken = joined.deviceToken;
    });

    test('setup tools work from loopback', () async {
      final browse = await s.post(
        ApiRoutes.setupBrowse,
        body: BrowseRequest(path: s.temp.path).toJson(),
      );
      expect(browse.statusCode, 200);
      final listing = BrowseResult.fromJson(decodeObject(browse));
      expect(listing.entries.map((e) => e.name), contains('roms'));

      final check = await s.post(
        ApiRoutes.setupCheckPath,
        body: PathCheckRequest(
          path: s.romsDir,
          kind: PathKind.libraryRoot,
        ).toJson(),
      );
      expect(check.statusCode, 200);
      final result = PathCheckResult.fromJson(decodeObject(check));
      expect(result.ok, isTrue);
      expect(
        result.detectedSystems.map((d) => d.systemId),
        containsAll(['snes', 'psx', 'nes']),
      );
    });

    test('setup validates its input', () async {
      Future<ApiError> fails(Object? body, int status) async {
        final r = await s.post(ApiRoutes.setup, body: body);
        expect(r.statusCode, status, reason: r.body);
        return decodeError(r);
      }

      expect(
        (await fails(setupRequest(password: 'short').toJson(), 400)).code,
        ApiErrorCodes.badRequest,
      );
      expect(
        (await fails(setupRequest(roots: []).toJson(), 400)).code,
        ApiErrorCodes.badRequest,
      );
      expect(
        (await fails(
          setupRequest(roots: [p.join(s.temp.path, 'missing')]).toJson(),
          400,
        )).code,
        ApiErrorCodes.pathInvalid,
      );
      expect(
        (await fails(
          setupRequest(roots: ['relative/path']).toJson(),
          400,
        )).code,
        ApiErrorCodes.pathInvalid,
      );
      expect(
        (await fails({'adminUsername': 'admin'}, 400)).code,
        ApiErrorCodes.badRequest,
      );
      // Nothing was written: still unconfigured.
      expect(s.ctx.isConfigured, isFalse);
      expect(File(p.join(s.dataDir, 'retrosteam.db')).existsSync(), isFalse);
    });

    test('setup from a browser page on another origin is refused', () async {
      final r = await s.post(
        ApiRoutes.setup,
        body: setupRequest().toJson(),
        extraHeaders: {'origin': 'http://evil.example'},
      );
      expect(r.statusCode, 403);
      expect(decodeError(r).code, ApiErrorCodes.loopbackOnly);
    });

    test('setup from a non-loopback peer is refused', () async {
      // An in-process request has no loopback connection info.
      final response = await buildApp(s.ctx)(
        Request(
          'POST',
          s.baseUri.resolve(ApiRoutes.setup),
          body: jsonEncode(setupRequest().toJson()),
        ),
      );
      expect(response.statusCode, 403);
      final error = ApiError.fromJson(
        jsonDecode(await response.readAsString()) as Map<String, Object?>,
      );
      expect(error.code, ApiErrorCodes.loopbackOnly);
    });
  });

  group('setup', () {
    test('creates admin, device and session, then scans', () async {
      final r = await s.post(ApiRoutes.setup, body: setupRequest().toJson());
      expect(r.statusCode, 201, reason: r.body);
      admin = AuthResult.fromJson(decodeObject(r));
      expect(admin.user.role, UserRole.admin);
      expect(admin.user.username, 'admin');
      expect(admin.deviceId, isNotNull);
      expect(admin.deviceToken, hasLength(43));

      final info = ServerInfo.fromJson(
        decodeObject(await s.get(ApiRoutes.serverInfo)),
      );
      expect(info.setupState, ServerSetupState.ready);

      final saved = jsonDecode(
        File(p.join(s.temp.path, 'config', 'server.json')).readAsStringSync(),
      ) as Map<String, Object?>;
      expect(saved['dataDir'], p.normalize(s.dataDir));

      await s.ctx.server!.scans.done;
      await _waitFor(
        () => events.whereType<ScanProgressEvent>().any(
          (e) => e.status.phase == ScanPhase.done,
        ),
      );
      final progress = events.whereType<ScanProgressEvent>().toList();
      expect(progress.first.status.phase, ScanPhase.discovering);
      expect(progress.last.status.phase, ScanPhase.done);
      expect(progress.last.status.added, 4);
      expect(progress.last.status.startedAt, isNotNull);
      expect(progress.last.status.finishedAt, isNotNull);
      final added = events
          .whereType<LibraryChangedEvent>()
          .expand((e) => e.addedIds)
          .toSet();
      expect(added, hasLength(4));
    });

    test('setup is rejected once configured', () async {
      final r = await s.post(ApiRoutes.setup, body: setupRequest().toJson());
      expect(r.statusCode, 409);
      expect(decodeError(r).code, ApiErrorCodes.alreadyConfigured);
    });

    test('the setup result logs the admin in', () async {
      final r = await s.get(
        ApiRoutes.authMe,
        device: device(),
        session: session(),
      );
      expect(r.statusCode, 200);
      expect(User.fromJson(decodeObject(r)), admin.user);
    });

    test('a device joined before setup is kept', () async {
      final r = await s.post(
        ApiRoutes.authLogin,
        device: pendingDeviceToken,
        body: const LoginRequest(
          username: 'Admin',
          password: 'correct horse',
        ).toJson(),
      );
      expect(r.statusCode, 200, reason: r.body);
    });

    test('setup tools now need the admin', () async {
      final anon = await s.post(
        ApiRoutes.setupBrowse,
        body: const BrowseRequest().toJson(),
      );
      expect(anon.statusCode, 401);
      final r = await s.post(
        ApiRoutes.setupBrowse,
        device: device(),
        session: session(),
        body: BrowseRequest(path: s.temp.path).toJson(),
      );
      expect(r.statusCode, 200);
    });
  });

  group('library', () {
    test('systems lists systems with games', () async {
      final r = await s.get(
        ApiRoutes.librarySystems,
        device: device(),
        session: session(),
      );
      expect(r.statusCode, 200);
      final systems = decodeList(r)
          .map((j) => SystemSummary.fromJson(j! as Map<String, Object?>))
          .toList();
      expect(
        {for (final x in systems) x.systemId: x.gameCount},
        {'nes': 1, 'psx': 1, 'snes': 2},
      );
      expect(
        systems.firstWhere((x) => x.systemId == 'snes').name,
        GameSystems.byId('snes')!.name,
      );
    });

    Future<GamePage> games([Map<String, String>? query]) async {
      final r = await s.get(
        ApiRoutes.libraryGames,
        device: device(),
        session: session(),
        query: query,
      );
      expect(r.statusCode, 200, reason: r.body);
      return GamePage.fromJson(decodeObject(r));
    }

    test('games lists, filters and sorts', () async {
      final all = await games();
      expect(all.total, 4);
      expect(all.games.map((g) => g.title).toList(), [
        'Crash',
        'Metroid',
        'Super Mario World',
        'Zelda',
      ]);
      expect((await games({ApiQueryParams.system: 'snes'})).total, 2);
      expect((await games({ApiQueryParams.query: 'mario'})).total, 1);
      expect((await games({ApiQueryParams.sort: GameSort.recent})).total, 4);
      final paged = await games({'limit': '1', 'offset': '1'});
      expect(paged.total, 4);
      expect(paged.games.single.title, 'Metroid');

      final crash = all.games.firstWhere((g) => g.systemId == 'psx');
      expect(crash.files.map((f) => f.path), [
        'Crash (USA).cue',
        'Crash (USA).bin',
      ]);
      expect(crash.files.first.sha1, isNotNull);
      expect(crash.rootId, isNotEmpty);

      final bad = await s.get(
        ApiRoutes.libraryGames,
        device: device(),
        session: session(),
        query: {ApiQueryParams.sort: 'nope'},
      );
      expect(bad.statusCode, 400);
    });

    test('game by id', () async {
      final first = (await games()).games.first;
      final r = await s.get(
        ApiRoutes.libraryGame(first.id),
        device: device(),
        session: session(),
      );
      expect(r.statusCode, 200);
      expect(Game.fromJson(decodeObject(r)), first);

      final missing = await s.get(
        ApiRoutes.libraryGame('nope'),
        device: device(),
        session: session(),
      );
      expect(missing.statusCode, 404);
      expect(decodeError(missing).code, ApiErrorCodes.notFound);
    });

    test('roots and scan status', () async {
      final roots = await s.get(
        ApiRoutes.libraryRoots,
        device: device(),
        session: session(),
      );
      expect(roots.statusCode, 200);
      final root = LibraryRoot.fromJson(
        decodeList(roots).single! as Map<String, Object?>,
      );
      expect(root.status, LibraryRootStatus.online);
      expect(root.label, 'roms');

      final status = await s.get(
        ApiRoutes.libraryScanStatus,
        device: device(),
        session: session(),
      );
      final scan = ScanStatus.fromJson(decodeObject(status));
      expect(scan.phase, ScanPhase.done);
      expect(scan.added, 4);
    });

    test('a rescan streams changes over the WebSocket', () async {
      final ws = await s.connectEvents(device: device(), session: session());
      final received = <ServerEvent>[];
      final times = <DateTime>[];
      final doneScan = Completer<void>();
      ws.listen((m) {
        final e = ServerEvent.fromJson(
          jsonDecode(m as String) as Map<String, Object?>,
        );
        received.add(e);
        if (e is ScanProgressEvent) {
          times.add(DateTime.now());
          if (e.status.phase == ScanPhase.done && !doneScan.isCompleted) {
            doneScan.complete();
          }
        }
      });

      s.writeRom('snes/Earthbound (USA).sfc', 'earthbound');
      File(p.join(s.romsDir, 'nes', 'Metroid (USA).nes')).deleteSync();

      final r = await s.post(
        ApiRoutes.libraryScan,
        device: device(),
        session: session(),
      );
      expect(r.statusCode, 202);
      await doneScan.future.timeout(const Duration(seconds: 20));

      final changes = received.whereType<LibraryChangedEvent>();
      expect(changes.expand((e) => e.addedIds), hasLength(1));
      expect(changes.expand((e) => e.removedIds), hasLength(1));
      final last = received.whereType<ScanProgressEvent>().last.status;
      expect(last.added, 1);
      expect(last.removed, 1);
      // Throttled to at most 4 per second (allowing timer jitter).
      for (var i = 1; i < times.length; i++) {
        expect(
          times[i].difference(times[i - 1]),
          greaterThan(const Duration(milliseconds: 200)),
        );
      }
      await ws.close();
    });

    test('only one scan runs at a time', () async {
      final scans = s.ctx.server!.scans;
      expect(scans.start(), isTrue);
      expect(scans.start(), isFalse);
      final r = await s.post(
        ApiRoutes.libraryScan,
        device: device(),
        session: session(),
      );
      // Usually 409; the tiny scan may already have finished.
      expect(r.statusCode, anyOf(409, 202));
      if (r.statusCode == 409) {
        expect(decodeError(r).code, ApiErrorCodes.conflict);
      }
      await scans.done;
      await s.ctx.server!.scans.done;
    });

    test('events socket rejects bad tokens with 4401', () async {
      final ws = await s.connectEvents(device: device(), session: 'z' * 43);
      await ws.drain<void>();
      expect(ws.closeCode, wsUnauthorized);
    });

    test('artwork is not available yet', () async {
      final r = await s.get(
        ApiRoutes.artwork('x'),
        device: device(),
        session: session(),
      );
      expect(r.statusCode, 404);
    });
  });

  group('auth', () {
    Future<http.Response> login(
      String username,
      String password, {
      String? deviceToken,
    }) => s.post(
      ApiRoutes.authLogin,
      device: deviceToken ?? device(),
      body: LoginRequest(username: username, password: password).toJson(),
    );

    test('login needs a joined device', () async {
      final r = await s.post(
        ApiRoutes.authLogin,
        body: const LoginRequest(
          username: 'admin',
          password: 'correct horse',
        ).toJson(),
      );
      expect(r.statusCode, 401);
      expect(decodeError(r).code, ApiErrorCodes.unauthorized);
    });

    test('wrong password → 401 invalid_credentials', () async {
      final r = await login('admin', 'wrong password');
      expect(r.statusCode, 401);
      expect(decodeError(r).code, ApiErrorCodes.invalidCredentials);
    });

    test('login, me, logout', () async {
      final r = await login('admin', 'correct horse');
      expect(r.statusCode, 200);
      final auth = AuthResult.fromJson(decodeObject(r));
      expect(auth.deviceToken, isNull);
      final me = await s.get(
        ApiRoutes.authMe,
        device: device(),
        session: auth.sessionToken,
      );
      expect(me.statusCode, 200);

      final out = await s.post(
        ApiRoutes.authLogout,
        device: device(),
        session: auth.sessionToken,
      );
      expect(out.statusCode, 204);
      final after = await s.get(
        ApiRoutes.authMe,
        device: device(),
        session: auth.sessionToken,
      );
      expect(after.statusCode, 401);
      // The setup session is unaffected.
      final still = await s.get(
        ApiRoutes.authMe,
        device: device(),
        session: session(),
      );
      expect(still.statusCode, 200);
    });

    test('a session only works on its own device', () async {
      final r = await s.get(
        ApiRoutes.authMe,
        device: pendingDeviceToken,
        session: session(),
      );
      expect(r.statusCode, 401);
    });

    test('repeated failures are rate limited', () async {
      for (var i = 0; i < 5; i++) {
        final r = await login('ghost', 'whatever-$i');
        expect(r.statusCode, 401);
      }
      final r = await login('ghost', 'whatever');
      expect(r.statusCode, 429);
      expect(decodeError(r).code, ApiErrorCodes.rateLimited);
      expect(int.parse(r.headers['retry-after']!), greaterThan(0));
    });

    test('regular users are kept out of admin routes', () async {
      final server = s.ctx.server!;
      server.users.create(
        username: 'kid',
        role: UserRole.user,
        passwordHash: await s.ctx.hasher.hash('kid password'),
      );
      final r = await login('kid', 'kid password');
      expect(r.statusCode, 200);
      final kid = AuthResult.fromJson(decodeObject(r)).sessionToken;

      final games = await s.get(
        ApiRoutes.libraryGames,
        device: device(),
        session: kid,
      );
      expect(games.statusCode, 200);
      for (final res in [
        await s.get(ApiRoutes.libraryRoots, device: device(), session: kid),
        await s.post(ApiRoutes.libraryScan, device: device(), session: kid),
        await s.post(
          ApiRoutes.setupBrowse,
          device: device(),
          session: kid,
          body: const BrowseRequest().toJson(),
        ),
      ]) {
        expect(res.statusCode, 403);
        expect(decodeError(res).code, ApiErrorCodes.forbidden);
      }
    });

    test('CORS preflight', () async {
      final request = await HttpClient().openUrl(
        'OPTIONS',
        s.baseUri.resolve(ApiRoutes.authLogin),
      );
      final response = await request.close();
      await response.drain<void>();
      expect(response.statusCode, 204);
      expect(
        response.headers.value('access-control-allow-headers'),
        contains(ApiHeaders.device),
      );
    });
  });

  group('restart', () {
    test('a configured server reopens its data and marks lost roots '
        'offline', () async {
      // Stop the running server.
      final configFile = s.ctx.configFile!;
      await s.ctx.events.close();
      await s.http_.close(force: true);
      await s.ctx.close();

      // The ROM drive "disappears".
      final moved = Directory(p.join(s.temp.path, 'unplugged'));
      Directory(s.romsDir).renameSync(moved.path);

      final ctx = ServerContext(
        config: await BootstrapConfig.loadOrCreate(configFile),
        name: 'test-host',
        configFile: configFile,
        hasher: const PasswordHasher(params: Argon2Params.insecureFastForTests),
        rootSearchDirs: const [],
      );
      await ctx.start();
      final httpServer = await shelf_io.serve(
        buildApp(ctx),
        InternetAddress.loopbackIPv4,
        0,
      );
      final base = Uri.parse('http://127.0.0.1:${httpServer.port}');
      final headers = {
        ApiHeaders.device: device(),
        ApiHeaders.authorization: '${ApiHeaders.bearerPrefix}${session()}',
      };
      try {
        final client = HttpClient();
        Future<(int, Object?)> get(String path) async {
          final req = await client.getUrl(base.resolve(path));
          headers.forEach(req.headers.set);
          final res = await req.close();
          final body = await utf8.decodeStream(res);
          return (res.statusCode, body.isEmpty ? null : jsonDecode(body));
        }

        final (status, roots) = await get(ApiRoutes.libraryRoots);
        expect(status, 200);
        expect(
          LibraryRoot.fromJson(
            (roots! as List<Object?>).single! as Map<String, Object?>,
          ).status,
          LibraryRootStatus.offline,
        );

        // A scan skips the offline root and removes nothing.
        expect(ctx.server!.scans.start(), isTrue);
        await ctx.server!.scans.done;
        final (_, page) = await get(ApiRoutes.libraryGames);
        expect(GamePage.fromJson(page! as Map<String, Object?>).total, 4);
        client.close();
      } finally {
        await ctx.events.close();
        await httpServer.close(force: true);
        await ctx.close();
      }
    });
  });
}

Future<void> _waitFor(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      throw TimeoutException('Condition not met within $timeout');
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}
