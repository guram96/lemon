import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rs_api_client/rs_api_client.dart';
import 'package:rs_core/rs_core.dart';
import 'package:test/test.dart';

const _user = User(id: 'u1', username: 'admin', role: UserRole.admin);

final _game = Game(
  id: 'g 1',
  systemId: 'snes',
  title: 'Chrono Trigger',
  rootId: 'r1',
  addedAt: DateTime.utc(2026, 3, 4),
  files: const [GameFile(path: 'ct.sfc', sizeBytes: 4)],
);

void main() {
  final base = Uri.parse('http://server:47320');

  RsApiClient clientWith(
    MockClientHandler handler, {
    String? device,
    String? session,
  }) => RsApiClient(
    baseUri: base,
    httpClient: MockClient(handler),
    deviceToken: device,
    sessionToken: session,
  );

  http.Response json(Object? body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json'},
  );

  Object? bodyOf(http.Request request) => jsonDecode(request.body);

  test('getServerInfo decodes the response', () async {
    const info = ServerInfo(
      serverId: 's1',
      name: 'Desk',
      version: '0.1.0',
      apiVersion: 1,
      setupState: ServerSetupState.ready,
      platform: 'linux',
    );
    final client = clientWith((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, ApiRoutes.serverInfo);
      return json(info.toJson());
    });
    expect(await client.getServerInfo(), info);
  });

  group('auth headers', () {
    test('are omitted when no tokens are set', () async {
      late http.Request seen;
      final client = clientWith((request) async {
        seen = request;
        return json(_user.toJson());
      });
      await client.me();
      expect(seen.headers.containsKey(ApiHeaders.device), isFalse);
      expect(seen.headers.containsKey(ApiHeaders.authorization), isFalse);
    });

    test('are sent when set, and follow token updates', () async {
      final seen = <http.Request>[];
      final client = clientWith((request) async {
        seen.add(request);
        return json(_user.toJson());
      }, device: 'dev');
      await client.me();
      client
        ..sessionToken = 'sess'
        ..deviceToken = 'dev2';
      await client.me();

      expect(seen[0].headers[ApiHeaders.device], 'dev');
      expect(seen[0].headers.containsKey(ApiHeaders.authorization), isFalse);
      expect(seen[1].headers[ApiHeaders.device], 'dev2');
      expect(seen[1].headers[ApiHeaders.authorization], 'Bearer sess');
    });
  });

  group('setup', () {
    test('browse posts a BrowseRequest', () async {
      const result = BrowseResult(path: '/', entries: [], shortcuts: []);
      final client = clientWith((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, ApiRoutes.setupBrowse);
        expect(request.headers['content-type'], startsWith('application/json'));
        expect(bodyOf(request), const BrowseRequest(path: '/x').toJson());
        return json(result.toJson());
      });
      expect(await client.browse('/x'), result);
    });

    test('checkPath posts a PathCheckRequest', () async {
      const result = PathCheckResult(
        path: '/data',
        kind: PathKind.dataDir,
        exists: false,
        readable: false,
        writable: true,
      );
      final client = clientWith((request) async {
        expect(request.url.path, ApiRoutes.setupCheckPath);
        expect(bodyOf(request), {'path': '/data', 'kind': 'dataDir'});
        return json(result.toJson());
      });
      final got = await client.checkPath('/data', PathKind.dataDir);
      expect(got, result);
      expect(got.ok, isTrue);
    });

    test('setup posts a SetupRequest and decodes a 201 AuthResult', () async {
      const request = SetupRequest(
        adminUsername: 'admin',
        adminPassword: 'password',
        dataDir: '/data',
        libraryRoots: ['/roms'],
        deviceName: 'Desk',
      );
      const result = AuthResult(
        sessionToken: 's',
        user: _user,
        deviceId: 'd1',
        deviceToken: 'dt',
      );
      final client = clientWith((r) async {
        expect(r.url.path, ApiRoutes.setup);
        expect(bodyOf(r), request.toJson());
        return json(result.toJson(), 201);
      });
      expect(await client.setup(request), result);
    });

    test('setup maps 409 already_configured', () async {
      final client = clientWith(
        (_) async => json(
          const ApiError(
            code: ApiErrorCodes.alreadyConfigured,
            message: 'done',
          ).toJson(),
          409,
        ),
      );
      await expectLater(
        client.setup(
          const SetupRequest(
            adminUsername: 'a',
            adminPassword: 'password',
            dataDir: '/d',
            libraryRoots: ['/r'],
            deviceName: 'x',
          ),
        ),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 409)
              .having(
                (e) => e.error.code,
                'code',
                ApiErrorCodes.alreadyConfigured,
              ),
        ),
      );
    });
  });

  group('devices and auth', () {
    test('joinLocal', () async {
      const request = DeviceJoinRequest(deviceName: 'Desk', platform: 'macos');
      const result = DeviceJoinResult(deviceId: 'd1', deviceToken: 't');
      final client = clientWith((r) async {
        expect(r.method, 'POST');
        expect(r.url.path, ApiRoutes.devicesLocal);
        expect(bodyOf(r), request.toJson());
        return json(result.toJson());
      });
      expect(await client.joinLocal(request), result);
    });

    test('login posts credentials', () async {
      const result = AuthResult(sessionToken: 's', user: _user);
      final client = clientWith((r) async {
        expect(r.url.path, ApiRoutes.authLogin);
        expect(bodyOf(r), {'username': 'admin', 'password': 'pw'});
        return json(result.toJson());
      }, device: 'dev');
      expect(await client.login('admin', 'pw'), result);
    });

    test('login maps 401 invalid_credentials', () async {
      final client = clientWith(
        (_) async => json(
          const ApiError(
            code: ApiErrorCodes.invalidCredentials,
            message: 'no',
          ).toJson(),
          401,
        ),
      );
      await expectLater(
        client.login('a', 'b'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 401)
              .having(
                (e) => e.error.code,
                'code',
                ApiErrorCodes.invalidCredentials,
              ),
        ),
      );
    });

    test('logout accepts 204 with no body', () async {
      final client = clientWith((r) async {
        expect(r.method, 'POST');
        expect(r.url.path, ApiRoutes.authLogout);
        expect(r.body, isEmpty);
        return http.Response('', 204);
      }, session: 's');
      await client.logout();
    });

    test('me decodes a User', () async {
      final client = clientWith((r) async {
        expect(r.url.path, ApiRoutes.authMe);
        return json(_user.toJson());
      });
      expect(await client.me(), _user);
    });
  });

  group('library', () {
    test('systems decodes a list', () async {
      const systems = [
        SystemSummary(systemId: 'snes', name: 'SNES', gameCount: 2),
        SystemSummary(systemId: 'psx', name: 'PlayStation', gameCount: 1),
      ];
      final client = clientWith((r) async {
        expect(r.url.path, ApiRoutes.librarySystems);
        return json([for (final s in systems) s.toJson()]);
      });
      expect(await client.systems(), systems);
    });

    test('games sends query parameters', () async {
      final page = GamePage(games: [_game], total: 1);
      final seen = <Uri>[];
      final client = clientWith((r) async {
        seen.add(r.url);
        return json(page.toJson());
      });
      expect(await client.games(), page);
      await client.games(
        system: 'snes',
        query: 'chrono',
        sort: GameSort.recent,
      );
      await client.games(query: '');

      expect(seen[0].path, ApiRoutes.libraryGames);
      expect(seen[0].queryParameters, {'sort': 'title'});
      expect(seen[1].queryParameters, {
        'system': 'snes',
        'q': 'chrono',
        'sort': 'recent',
      });
      expect(seen[2].queryParameters, {'sort': 'title'});
    });

    test('game fetches by id', () async {
      final client = clientWith((r) async {
        expect(r.url.path, '${ApiRoutes.libraryGames}/g%201');
        return json(_game.toJson());
      });
      expect(await client.game('g 1'), _game);
    });

    test('roots decodes a list', () async {
      const roots = [
        LibraryRoot(id: 'r1', label: 'HDD', status: LibraryRootStatus.online),
      ];
      final client = clientWith((r) async {
        expect(r.url.path, ApiRoutes.libraryRoots);
        return json([for (final root in roots) root.toJson()]);
      });
      expect(await client.roots(), roots);
    });

    test('scraper settings round-trip', () async {
      const update = ScraperSettingsUpdate(
        screenScraper: ScreenScraperLogin(
          devId: 'dev',
          devPassword: 'secret',
          username: 'user',
          password: 'secret',
        ),
        steamGridDbApiKey: 'grid',
      );
      const status = ScraperStatus(screenScraper: true, steamGridDb: true);
      final client = clientWith((r) async {
        expect(r.method, 'PUT');
        expect(r.url.path, ApiRoutes.scraperSettings);
        expect(bodyOf(r), update.toJson());
        return json(status.toJson());
      });
      expect(await client.updateScrapers(update), status);
    });

    test('startScan posts and accepts 202', () async {
      final client = clientWith((r) async {
        expect(r.method, 'POST');
        expect(r.url.path, ApiRoutes.libraryScan);
        return http.Response('', 202);
      });
      await client.startScan();
    });

    test('startScan maps 409 conflict', () async {
      final client = clientWith(
        (_) async => json(
          const ApiError(
            code: ApiErrorCodes.conflict,
            message: 'busy',
          ).toJson(),
          409,
        ),
      );
      await expectLater(
        client.startScan(),
        throwsA(
          isA<ApiException>().having(
            (e) => e.error.code,
            'code',
            ApiErrorCodes.conflict,
          ),
        ),
      );
    });

    test('scanStatus decodes a ScanStatus', () async {
      final status = ScanStatus(
        phase: ScanPhase.done,
        processed: 5,
        total: 5,
        finishedAt: DateTime.utc(2026),
      );
      final client = clientWith((r) async {
        expect(r.method, 'GET');
        expect(r.url.path, ApiRoutes.libraryScanStatus);
        return json(status.toJson());
      });
      expect(await client.scanStatus(), status);
    });

    test('artworkUri', () {
      final client = clientWith((_) async => http.Response('', 500));
      expect(
        client.artworkUri('a1').toString(),
        'http://server:47320/api/v1/artwork/a1',
      );
      expect(
        client.artworkUri('a1', width: 300).toString(),
        'http://server:47320/api/v1/artwork/a1?w=300',
      );
    });
  });

  group('download', () {
    const manifest = DownloadManifest(
      gameId: 'g 1',
      systemId: 'snes',
      files: [
        DownloadFile(index: 0, path: 'ct.sfc', sizeBytes: 10, sha1: 'abc'),
      ],
    );

    Future<List<int>> collect(DownloadStream stream) =>
        stream.bytes.fold<List<int>>(<int>[], (all, chunk) {
          all.addAll(chunk);
          return all;
        });

    test('downloadManifest decodes the catalog files', () async {
      final client = clientWith((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, ApiRoutes.gameDownload('g 1'));
        return json(manifest.toJson());
      });
      expect(await client.downloadManifest('g 1'), manifest);
    });

    test('openGameFile returns a 200 body with no Range header', () async {
      final client = clientWith((request) async {
        expect(request.url.path, ApiRoutes.gameDownloadFile('g 1', 0));
        expect(request.headers.containsKey('range'), isFalse);
        return http.Response.bytes(
          [1, 2, 3],
          200,
          headers: {'content-length': '3'},
        );
      });
      final stream = await client.openGameFile('g 1', 0);
      expect(stream.statusCode, 200);
      expect(stream.totalBytes, 3);
      expect(stream.start, 0);
      expect(await collect(stream), [1, 2, 3]);
    });

    test('openGameFile sends Range and returns a 206 stream', () async {
      final client = clientWith((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, ApiRoutes.gameDownloadFile('g 1', 0));
        expect(request.headers['range'], 'bytes=4-');
        return http.Response.bytes(
          [4, 5, 6],
          206,
          headers: {
            'content-type': 'application/octet-stream',
            'content-length': '3',
            'content-range': 'bytes 4-6/10',
            'accept-ranges': 'bytes',
          },
        );
      });
      final stream = await client.openGameFile('g 1', 0, start: 4);
      expect(stream.statusCode, 206);
      expect(stream.totalBytes, 10);
      expect(stream.start, 4);
      expect(await collect(stream), [4, 5, 6]);
    });

    test('openGameFile maps a non-206 error to ApiException', () async {
      final client = clientWith(
        (_) async => json(
          const ApiError(
            code: ApiErrorCodes.conflict,
            message: 'offline',
          ).toJson(),
          409,
        ),
      );
      await expectLater(
        client.openGameFile('g 1', 0, start: 4),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 409)
              .having((e) => e.error.code, 'code', ApiErrorCodes.conflict)
              .having((e) => e.error.message, 'message', 'offline'),
        ),
      );
    });
  });

  group('errors', () {
    test(
      'non-2xx responses throw ApiException with the server error',
      () async {
        final client = clientWith(
          (_) async => json(
            const ApiError(code: 'not_found', message: 'nope').toJson(),
            404,
          ),
        );
        await expectLater(
          client.getServerInfo(),
          throwsA(
            isA<ApiException>()
                .having((e) => e.statusCode, 'statusCode', 404)
                .having((e) => e.error.code, 'code', 'not_found'),
          ),
        );
      },
    );

    test('non-JSON error bodies become a generic ApiException', () async {
      final client = clientWith((_) async => http.Response('<html>', 502));
      await expectLater(
        client.me(),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 502)
              .having((e) => e.error.code, 'code', ApiErrorCodes.internal),
        ),
      );
    });

    test('connection failures are reported as unreachable', () async {
      final client = clientWith((_) => throw http.ClientException('refused'));
      await expectLater(
        client.getServerInfo(),
        throwsA(
          isA<ApiException>()
              .having((e) => e.isUnreachable, 'unreachable', isTrue)
              .having((e) => e.error.code, 'code', ApiErrorCodes.unreachable),
        ),
      );
    });
  });

  group('events', () {
    late HttpServer server;
    late StreamController<(Uri, WebSocket)> connections;

    setUp(() async {
      connections = StreamController();
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        final uri = request.uri;
        connections.add((uri, await WebSocketTransformer.upgrade(request)));
      });
    });

    tearDown(() async {
      await server.close(force: true);
      unawaited(connections.close());
    });

    RsApiClient eventsClient() => RsApiClient(
      baseUri: Uri.parse('http://127.0.0.1:${server.port}'),
      deviceToken: 'dev',
      sessionToken: 'sess',
      reconnectInitialDelay: const Duration(milliseconds: 10),
      reconnectMaxDelay: const Duration(milliseconds: 50),
    );

    test('eventsUri uses ws scheme and token query parameters', () {
      final client = RsApiClient(
        baseUri: Uri.parse('https://host:1'),
        deviceToken: 'd',
        sessionToken: 's',
      );
      expect(
        client.eventsUri().toString(),
        'wss://host:1/api/v1/events?device=d&session=s',
      );
    });

    test('decodes events, skips junk, and reconnects', () async {
      final client = eventsClient();
      final incoming = StreamQueue(connections.stream);
      // StreamQueue listens right away, which opens the connection.
      final received = StreamQueue(client.events());
      final first = received.next;

      var (uri, socket) = await incoming.next;
      expect(uri.path, ApiRoutes.events);
      expect(uri.queryParameters, {'device': 'dev', 'session': 'sess'});

      const changed = ServerEvent.libraryChanged(addedIds: ['g1']);
      socket
        ..add('not json')
        ..add(jsonEncode({'type': 'from_the_future'}))
        ..add(jsonEncode(changed.toJson()));
      expect(await first, changed);

      // Server drops the connection: the client reconnects with new tokens.
      client.sessionToken = 'sess2';
      await socket.close();
      (uri, socket) = await incoming.next;
      expect(uri.queryParameters['session'], 'sess2');

      const rootEvent = ServerEvent.rootStatusChanged(
        root: LibraryRoot(
          id: 'r1',
          label: 'HDD',
          status: LibraryRootStatus.offline,
        ),
      );
      socket.add(jsonEncode(rootEvent.toJson()));
      expect(await received.next, isA<RootStatusChangedEvent>());

      await received.cancel();
    });

    test('stops with a 401 ApiException on close code 4401', () async {
      final client = eventsClient();
      final incoming = StreamQueue(connections.stream);
      var connected = 0;
      final received = StreamQueue(
        client.events(onConnected: () => connected++),
      );
      final first = received.next;

      final (_, socket) = await incoming.next;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(connected, 1);
      await socket.close(RsApiClient.unauthorizedCloseCode, 'unauthorized');

      await expectLater(
        first,
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 401)
              .having((e) => e.error.code, 'code', ApiErrorCodes.unauthorized),
        ),
      );
      expect(await received.hasNext, isFalse);
      // No reconnect attempt.
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(
        await incoming.hasNext.timeout(
          const Duration(milliseconds: 50),
          onTimeout: () => false,
        ),
        isFalse,
      );
    });

    test('retries when the server is not reachable yet', () async {
      final port = server.port;
      await server.close(force: true);
      final client = RsApiClient(
        baseUri: Uri.parse('http://127.0.0.1:$port'),
        reconnectInitialDelay: const Duration(milliseconds: 10),
        reconnectMaxDelay: const Duration(milliseconds: 20),
      );
      final received = StreamIterator(client.events());
      final next = received.moveNext();

      await Future<void>.delayed(const Duration(milliseconds: 100));
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
      server.listen((request) async {
        final socket = await WebSocketTransformer.upgrade(request);
        socket.add(
          jsonEncode(
            const ServerEvent.scanProgress(status: ScanStatus.idle).toJson(),
          ),
        );
      });

      expect(await next.timeout(const Duration(seconds: 5)), isTrue);
      expect(received.current, isA<ScanProgressEvent>());
      await received.cancel();
    });
  });
}
