import 'package:http/http.dart' as http;
import 'package:rs_core/rs_core.dart';

/// Wraps an [http.Client] and calls [onUnauthorized] whenever a request that
/// carried a session (`Authorization` header) is answered with `401`, so the
/// app drops the dead session no matter which screen made the call.
class UnauthorizedInterceptor extends http.BaseClient {
  UnauthorizedInterceptor(this._inner, {required this.onUnauthorized});

  final http.Client _inner;
  final void Function() onUnauthorized;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await _inner.send(request);
    final hadSession = request.headers.keys.any(
      (k) => k.toLowerCase() == ApiHeaders.authorization.toLowerCase(),
    );
    if (response.statusCode == 401 && hadSession) onUnauthorized();
    return response;
  }

  @override
  void close() => _inner.close();
}
