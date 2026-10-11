import 'package:http/http.dart' as http;
import 'package:rs_core/rs_core.dart';
import 'package:test/test.dart';

import '../api/api_test_harness.dart';

/// 36 ASCII bytes, so a middle slice and a start past EOF are obvious.
const _payload = 'abcdefghijklmnopqrstuvwxyz0123456789';

void main() {
  late TestServer server;
  late String deviceToken;
  late String sessionToken;
  late Game game;

  setUpAll(() async {
    server = await TestServer.start();
    server.writeRom('snes/Range (USA).sfc', _payload);
    final setup = await server.post(
      ApiRoutes.setup,
      body: SetupRequest(
        adminUsername: 'admin',
        adminPassword: 'correct horse',
        dataDir: server.dataDir,
        libraryRoots: [server.romsDir],
        deviceName: 'Download test',
      ).toJson(),
    );
    expect(setup.statusCode, 201, reason: setup.body);
    final auth = AuthResult.fromJson(decodeObject(setup));
    deviceToken = auth.deviceToken!;
    sessionToken = auth.sessionToken;
    await server.ctx.server!.scans.done;

    final listed = await server.get(
      ApiRoutes.libraryGames,
      device: deviceToken,
      session: sessionToken,
    );
    expect(listed.statusCode, 200, reason: listed.body);
    game = GamePage.fromJson(decodeObject(listed)).games.single;
    expect(game.systemId, 'snes');
    expect(game.files.single.path, 'Range (USA).sfc');
    expect(game.files.single.sizeBytes, _payload.length);
  });

  tearDownAll(() async {
    await server.close();
  });

  Future<http.Response> fetch(String path, {String? range}) =>
      server.client.get(
        server.baseUri.resolve(path),
        headers: {
          ...server.headers(device: deviceToken, session: sessionToken),
          'range': ?range,
        },
      );

  test('game by id is unchanged', () async {
    final response = await server.get(
      ApiRoutes.libraryGame(game.id),
      device: deviceToken,
      session: sessionToken,
    );
    expect(response.statusCode, 200, reason: response.body);
    expect(Game.fromJson(decodeObject(response)).id, game.id);
  });

  test('manifest lists catalog files by index', () async {
    final response = await fetch(ApiRoutes.gameDownload(game.id));
    expect(response.statusCode, 200, reason: response.body);
    expect(
      DownloadManifest.fromJson(decodeObject(response)),
      DownloadManifest(
        gameId: game.id,
        systemId: 'snes',
        files: [
          DownloadFile(
            index: 0,
            path: 'Range (USA).sfc',
            sizeBytes: _payload.length,
            sha1: game.files.single.sha1,
          ),
        ],
      ),
    );
  });

  test('download requires a session', () async {
    final response = await server.get(ApiRoutes.gameDownload(game.id));
    expect(response.statusCode, 401);
    expect(decodeError(response).code, ApiErrorCodes.unauthorized);
  });

  test('full body', () async {
    final response = await fetch(ApiRoutes.gameDownloadFile(game.id, 0));
    expect(response.statusCode, 200);
    expect(response.bodyBytes, _payload.codeUnits);
    expect(response.headers['accept-ranges'], 'bytes');
    expect(response.headers['content-type'], 'application/octet-stream');
    expect(response.headers['content-length'], '${_payload.length}');
    expect(response.headers.containsKey('content-range'), isFalse);
  });

  test('middle range matches that slice', () async {
    final response = await fetch(
      ApiRoutes.gameDownloadFile(game.id, 0),
      range: 'bytes=4-9',
    );
    expect(response.statusCode, 206);
    expect(response.bodyBytes, _payload.codeUnits.sublist(4, 10));
    expect(response.headers['content-range'], 'bytes 4-9/${_payload.length}');
    expect(response.headers['content-length'], '6');
    expect(response.headers['accept-ranges'], 'bytes');
  });

  test('open-ended range runs through the last byte', () async {
    final response = await fetch(
      ApiRoutes.gameDownloadFile(game.id, 0),
      range: 'bytes=30-',
    );
    expect(response.statusCode, 206);
    expect(response.bodyBytes, _payload.codeUnits.sublist(30));
    expect(
      response.headers['content-range'],
      'bytes 30-${_payload.length - 1}/${_payload.length}',
    );
  });

  test('an end past EOF is clamped to the last byte', () async {
    final response = await fetch(
      ApiRoutes.gameDownloadFile(game.id, 0),
      range: 'bytes=30-999',
    );
    expect(response.statusCode, 206);
    expect(response.bodyBytes, _payload.codeUnits.sublist(30));
    expect(
      response.headers['content-range'],
      'bytes 30-${_payload.length - 1}/${_payload.length}',
    );
  });

  test('a range past EOF is 416', () async {
    final response = await fetch(
      ApiRoutes.gameDownloadFile(game.id, 0),
      range: 'bytes=100-120',
    );
    expect(response.statusCode, 416);
    expect(response.headers['content-range'], 'bytes */${_payload.length}');
    expect(response.headers['accept-ranges'], 'bytes');
    expect(decodeError(response).code, ApiErrorCodes.badRequest);
  });

  test('multiple ranges are 416', () async {
    final response = await fetch(
      ApiRoutes.gameDownloadFile(game.id, 0),
      range: 'bytes=0-1,2-3',
    );
    expect(response.statusCode, 416);
    expect(response.headers['content-range'], 'bytes */${_payload.length}');
  });

  test('unknown index is 404', () async {
    final response = await fetch(ApiRoutes.gameDownloadFile(game.id, 3));
    expect(response.statusCode, 404);
    expect(decodeError(response).code, ApiErrorCodes.notFound);
  });

  test('unknown game is 404', () async {
    final response = await fetch(ApiRoutes.gameDownload('missing'));
    expect(response.statusCode, 404);
    expect(decodeError(response).code, ApiErrorCodes.notFound);
  });

  test('an offline root is 409', () async {
    server.ctx.server!.rootRepo.updateStatus(
      game.rootId,
      LibraryRootStatus.offline,
    );
    final manifest = await fetch(ApiRoutes.gameDownload(game.id));
    expect(manifest.statusCode, 409);
    expect(decodeError(manifest).code, ApiErrorCodes.conflict);

    final file = await fetch(ApiRoutes.gameDownloadFile(game.id, 0));
    expect(file.statusCode, 409);
    expect(decodeError(file).code, ApiErrorCodes.conflict);
  });
}
