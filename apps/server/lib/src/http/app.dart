import 'package:logging/logging.dart';
import 'package:rs_core/rs_core.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../routes/server_info_routes.dart';
import '../server_context.dart';
import 'json.dart';

final _log = Logger('http');

/// Builds the full request handler: middleware + all API routes.
Handler buildApp(ServerContext ctx) {
  final router = Router(notFoundHandler: _notFound);
  mountServerInfoRoutes(router, ctx);

  return const Pipeline()
      .addMiddleware(_requestLogger())
      .addMiddleware(_errorHandler())
      .addHandler(router.call);
}

Response _notFound(Request request) => jsonError(
  404,
  ApiErrorCodes.notFound,
  'No route for ${request.method} /${request.url.path}',
);

Middleware _requestLogger() =>
    (inner) => (request) async {
      final watch = Stopwatch()..start();
      final response = await inner(request);
      _log.fine(
        '${request.method} /${request.url.path} → ${response.statusCode} '
        '(${watch.elapsedMilliseconds} ms)',
      );
      return response;
    };

/// Turns uncaught exceptions into a JSON [ApiError] instead of a bare 500.
Middleware _errorHandler() =>
    (inner) => (request) async {
      try {
        return await inner(request);
      } on HijackException {
        rethrow;
      } catch (e, st) {
        _log.severe('Unhandled error on /${request.url.path}', e, st);
        return jsonError(500, ApiErrorCodes.internal, 'Internal server error');
      }
    };
