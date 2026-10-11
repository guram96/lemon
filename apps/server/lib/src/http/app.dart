import 'package:rs_core/rs_core.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../fs/fs.dart';
import '../routes/auth_routes.dart';
import '../routes/events_routes.dart';
import '../routes/library_routes.dart';
import '../routes/server_info_routes.dart';
import '../routes/settings_routes.dart';
import '../routes/setup_routes.dart';
import '../server_context.dart';
import 'json.dart';
import 'middleware.dart';

/// Builds the full request handler: middleware + all API routes.
///
/// [browser] and [probe] are injectable for tests.
Handler buildApp(
  ServerContext ctx, {
  DirectoryBrowser? browser,
  PathProbe probe = const PathProbe(),
}) {
  final router = Router(notFoundHandler: _notFound);
  mountServerInfoRoutes(router, ctx);
  mountSetupRoutes(router, ctx, browser: browser, probe: probe);
  mountAuthRoutes(router, ctx);
  mountLibraryRoutes(router, ctx);
  mountSettingsRoutes(router, ctx);
  mountEventRoutes(router, ctx);

  return const Pipeline()
      .addMiddleware(cors())
      .addMiddleware(requestLogger())
      .addMiddleware(errorHandler())
      .addHandler(router.call);
}

Response _notFound(Request request) => jsonError(
  404,
  ApiErrorCodes.notFound,
  'No route for ${request.method} /${request.url.path}',
);
