import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:rs_core/rs_core.dart';

import 'api_exception.dart';

/// Client for one server, addressed by [baseUri] (for example
/// `http://192.168.1.10:47320`).
class RsApiClient {
  RsApiClient({required this.baseUri, http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  final Uri baseUri;
  final http.Client _http;

  Future<ServerInfo> getServerInfo() async =>
      ServerInfo.fromJson(await _getJson(ApiRoutes.serverInfo));

  void close() => _http.close();

  Future<Map<String, Object?>> _getJson(String path) async {
    final http.Response response;
    try {
      response = await _http.get(baseUri.resolve(path));
    } on http.ClientException catch (e) {
      // Also covers socket errors: package:http wraps them on every platform.
      throw ApiException(
        statusCode: null,
        error: ApiError(code: 'unreachable', message: e.message),
      );
    }
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        statusCode: response.statusCode,
        error: body is Map<String, Object?>
            ? ApiError.fromJson(body)
            : ApiError(
                code: ApiErrorCodes.internal,
                message: 'HTTP ${response.statusCode}',
              ),
      );
    }
    return body! as Map<String, Object?>;
  }
}
