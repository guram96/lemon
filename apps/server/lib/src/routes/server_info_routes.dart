import 'package:rs_core/rs_core.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../http/json.dart';
import '../server_context.dart';
import '../version.dart';

void mountServerInfoRoutes(Router router, ServerContext ctx) {
  router.get(ApiRoutes.serverInfo, (Request _) {
    final info = ServerInfo(
      serverId: ctx.config.serverId,
      name: ctx.name,
      version: serverVersion,
      apiVersion: ApiRoutes.version,
      setupState: ctx.config.isConfigured
          ? ServerSetupState.ready
          : ServerSetupState.unconfigured,
    );
    return jsonOk(info.toJson());
  });
}
