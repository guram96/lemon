import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rs_api_client/rs_api_client.dart';
import 'package:rs_core/rs_core.dart';
import 'package:test/test.dart';

void main() {
  final base = Uri.parse('http://server:47320');

  RsApiClient clientWith(MockClientHandler handler) =>
      RsApiClient(baseUri: base, httpClient: MockClient(handler));

  test('getServerInfo decodes the response', () async {
    const info = ServerInfo(
      serverId: 's1',
      name: 'Desk',
      version: '0.1.0',
      apiVersion: 1,
      setupState: ServerSetupState.ready,
    );
    final client = clientWith((request) async {
      expect(request.url.path, ApiRoutes.serverInfo);
      return http.Response(jsonEncode(info.toJson()), 200);
    });
    expect(await client.getServerInfo(), info);
  });

  test('non-2xx responses throw ApiException with the server error', () async {
    final client = clientWith(
      (_) async => http.Response(
        jsonEncode(const ApiError(code: 'not_found', message: 'nope').toJson()),
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
  });

  test('connection failures are reported as unreachable', () async {
    final client = clientWith((_) => throw http.ClientException('refused'));
    await expectLater(
      client.getServerInfo(),
      throwsA(
        isA<ApiException>().having(
          (e) => e.isUnreachable,
          'unreachable',
          isTrue,
        ),
      ),
    );
  });
}
