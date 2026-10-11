import 'package:rs_core/rs_core.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';

import '../http/middleware.dart';
import '../server_context.dart';
import '../services/event_hub.dart';

/// `GET /events`: WebSocket of [ServerEvent]s.
///
/// Browsers can't send headers on a WebSocket, so the device and session
/// tokens come as query parameters. Bad credentials are reported by closing
/// the socket right after the upgrade with code 4401 ([wsUnauthorized]).
void mountEventRoutes(Router router, ServerContext ctx) {
  router.get(ApiRoutes.events, (Request request) {
    final q = request.url.queryParameters;
    final server = ctx.server;
    final device = server == null
        ? null
        : deviceForToken(server, q[ApiQueryParams.device]);
    final session = server == null || device == null
        ? null
        : sessionForToken(server, device, q[ApiQueryParams.session]);

    return webSocketHandler((channel, _) {
      if (device == null || session == null || server == null) {
        channel.sink.close(wsUnauthorized, 'unauthorized');
        return;
      }
      final scans = server.scans;
      ctx.events.attach(
        channel,
        deviceId: device.id,
        sessionId: session.$1.id,
        // A client connecting mid-scan gets the progress right away.
        initial: [
          if (scans.isRunning) ServerEvent.scanProgress(status: scans.status),
        ],
      );
    }, pingInterval: const Duration(seconds: 30))(request);
  });
}
