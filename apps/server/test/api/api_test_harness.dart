import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:rs_core/rs_core.dart';
import 'package:rs_server/rs_server.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

/// A real server on a loopback port, with temp config, data and ROM folders.
class TestServer {
  TestServer._(this.temp, this.ctx, this.http_, this.baseUri);

  static Future<TestServer> start() async {
    final temp = await Directory.systemTemp.createTemp('rs_api_');
    final ctx = ServerContext(
      config: BootstrapConfig(serverId: 'srv-test'),
      name: 'test-host',
      configFile: File(p.join(temp.path, 'config', 'server.json')),
      hasher: const PasswordHasher(params: Argon2Params.insecureFastForTests),
      scanner: const Scanner(
        options: ScannerOptions(
          hashWorkers: 1,
          progressInterval: Duration.zero,
        ),
      ),
      rootSearchDirs: const [],
    );
    final server = await shelf_io.serve(
      buildApp(ctx),
      InternetAddress.loopbackIPv4,
      0,
    );
    return TestServer._(
      temp,
      ctx,
      server,
      Uri.parse('http://127.0.0.1:${server.port}'),
    );
  }

  final Directory temp;
  final ServerContext ctx;
  final HttpServer http_;
  final Uri baseUri;
  final client = http.Client();

  String get dataDir => p.join(temp.path, 'data');
  String get romsDir => p.join(temp.path, 'roms');

  /// Writes a ROM (or any file) below [romsDir].
  File writeRom(String rel, String content) {
    final f = File(p.joinAll([romsDir, ...rel.split('/')]));
    f.parent.createSync(recursive: true);
    f.writeAsStringSync(content);
    return f;
  }

  void buildLibrary() {
    writeRom('snes/Super Mario World (USA).sfc', 'smw');
    writeRom('snes/Zelda (USA).smc', 'zelda');
    writeRom('psx/Crash (USA).cue', 'FILE "Crash (USA).bin" BINARY\n');
    writeRom('psx/Crash (USA).bin', 'crash-data');
    writeRom('nes/Metroid (USA).nes', 'metroid');
  }

  Map<String, String> headers({
    String? device,
    String? session,
    bool json = false,
  }) => {
    ApiHeaders.device: ?device,
    if (session != null)
      ApiHeaders.authorization: '${ApiHeaders.bearerPrefix}$session',
    if (json) 'content-type': 'application/json',
  };

  Future<http.Response> get(
    String path, {
    String? device,
    String? session,
    Map<String, String>? query,
  }) => client.get(
    baseUri.resolve(path).replace(queryParameters: query),
    headers: headers(device: device, session: session),
  );

  Future<http.Response> post(
    String path, {
    Object? body,
    String? device,
    String? session,
    Map<String, String>? extraHeaders,
  }) => client.post(
    baseUri.resolve(path),
    headers: {
      ...headers(device: device, session: session, json: true),
      ...?extraHeaders,
    },
    body: body == null ? null : jsonEncode(body),
  );

  Future<http.Response> put(
    String path, {
    Object? body,
    String? device,
    String? session,
  }) => client.put(
    baseUri.resolve(path),
    headers: headers(device: device, session: session, json: true),
    body: body == null ? null : jsonEncode(body),
  );

  Future<WebSocket> connectEvents({String? device, String? session}) {
    final uri = baseUri
        .resolve(ApiRoutes.events)
        .replace(
          scheme: 'ws',
          queryParameters: {
            ApiQueryParams.device: ?device,
            ApiQueryParams.session: ?session,
          },
        );
    return WebSocket.connect(uri.toString());
  }

  Future<void> close() async {
    client.close();
    await ctx.events.close();
    await http_.close(force: true);
    await ctx.close();
    await temp.delete(recursive: true);
  }
}

Map<String, Object?> decodeObject(http.Response r) =>
    jsonDecode(r.body) as Map<String, Object?>;

List<Object?> decodeList(http.Response r) =>
    jsonDecode(r.body) as List<Object?>;

ApiError decodeError(http.Response r) => ApiError.fromJson(decodeObject(r));
