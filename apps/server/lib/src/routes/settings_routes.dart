import 'package:rs_core/rs_core.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../http/api_failure.dart';
import '../http/json.dart';
import '../http/middleware.dart';
import '../server_context.dart';
import '../services/scraper_settings.dart';

/// Admin settings. Scraper responses never include secrets.
void mountSettingsRoutes(Router router, ServerContext ctx) {
  final admin = const Pipeline().addMiddleware(
    requireSession(ctx, admin: true),
  );

  router.get(
    ApiRoutes.scraperSettings,
    admin.addHandler((request) {
      final status = ScraperCredentials.read(ctx.requireServer().settings)
          .status;
      return jsonOk(status.toJson());
    }),
  );

  router.put(
    ApiRoutes.scraperSettings,
    admin.addHandler((request) async {
      final update = await readJson(request, ScraperSettingsUpdate.fromJson);
      final settings = ctx.requireServer().settings;
      try {
        ScraperCredentials.apply(settings, update);
      } on ScraperSettingsException catch (e) {
        throw ApiFailure.badRequest(e.message);
      }
      return jsonOk(ScraperCredentials.read(settings).status.toJson());
    }),
  );
}
