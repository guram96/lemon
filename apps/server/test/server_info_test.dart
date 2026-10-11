import 'dart:convert';

import 'package:rs_core/rs_core.dart';
import 'package:rs_server/rs_server.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  Handler appWith({String? dataDir}) => buildApp(
    ServerContext(
      config: BootstrapConfig(serverId: 'srv-1', dataDir: dataDir),
      name: 'test-host',
    ),
  );

  Future<Response> get(Handler app, String path) =>
      Future.value(app(Request('GET', Uri.parse('http://localhost$path'))));

  test('reports unconfigured before first-run setup', () async {
    final response = await get(appWith(), ApiRoutes.serverInfo);
    expect(response.statusCode, 200);
    final info = ServerInfo.fromJson(
      jsonDecode(await response.readAsString()) as Map<String, Object?>,
    );
    expect(info.serverId, 'srv-1');
    expect(info.apiVersion, ApiRoutes.version);
    expect(info.setupState, ServerSetupState.unconfigured);
  });

  test('reports ready once a data directory is set', () async {
    final response = await get(appWith(dataDir: '/data'), ApiRoutes.serverInfo);
    final json =
        jsonDecode(await response.readAsString()) as Map<String, Object?>;
    expect(json['setupState'], 'ready');
  });

  test('unknown routes return a JSON ApiError', () async {
    final response = await get(appWith(), '/api/v1/nope');
    expect(response.statusCode, 404);
    final error = ApiError.fromJson(
      jsonDecode(await response.readAsString()) as Map<String, Object?>,
    );
    expect(error.code, ApiErrorCodes.notFound);
  });
}
