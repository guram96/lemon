import 'package:rs_core/rs_core.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';

import '../fs/fs.dart';
import '../http/api_failure.dart';
import '../http/json.dart';
import '../http/middleware.dart';
import '../security/security.dart';
import '../server_context.dart';
import '../services/mappers.dart';
import '../services/setup_service.dart';

/// Setup tools, first-run setup and same-machine device join.
void mountSetupRoutes(
  Router router,
  ServerContext ctx, {
  DirectoryBrowser? browser,
  PathProbe probe = const PathProbe(),
}) {
  final setupTools = const Pipeline().addMiddleware(
    requireSetupToolAccess(ctx),
  );
  final local = const Pipeline().addMiddleware(requireLocal());
  final dirs = browser ?? DirectoryBrowser();

  router.post(
    ApiRoutes.setupBrowse,
    setupTools.addHandler((request) async {
      final body = await readJson(request, BrowseRequest.fromJson);
      final path = body.path;
      final listing = await dirs.browse(
        path == null || path.trim().isEmpty ? null : path,
      );
      return jsonOk(Mappers.browse(listing).toJson());
    }),
  );

  router.post(
    ApiRoutes.setupCheckPath,
    setupTools.addHandler((request) async {
      final body = await readJson(request, PathCheckRequest.fromJson);
      final result = await probe.check(body.path, Mappers.probeKind(body.kind));
      return jsonOk(Mappers.pathCheck(result, body.kind).toJson());
    }),
  );

  router.post(
    ApiRoutes.setup,
    local.addHandler((request) async {
      if (ctx.isConfigured) throw const ApiFailure.alreadyConfigured();
      if (ctx.setupInProgress) {
        throw const ApiFailure.conflict('Setup is already running.');
      }
      final body = await readJson(request, SetupRequest.fromJson);
      ctx.setupInProgress = true;
      try {
        final caller = request.headers[ApiHeaders.device];
        final result = await SetupService(ctx, probe: probe).run(
          body,
          callerDeviceTokenHash: caller == null ? null : Tokens.hash(caller),
        );
        return jsonResponse(201, result.toJson());
      } finally {
        ctx.setupInProgress = false;
      }
    }),
  );

  router.post(
    ApiRoutes.devicesLocal,
    local.addHandler((request) async {
      final body = await readJson(request, DeviceJoinRequest.fromJson);
      final (name, platform) = validateDeviceInfo(
        body.deviceName,
        body.platform,
      );
      final token = Tokens.generate();
      final hash = Tokens.hash(token);
      final server = ctx.server;
      final String deviceId;
      if (server != null) {
        deviceId = server.devices
            .create(name: name, platform: platform, tokenHash: hash)
            .id;
      } else {
        // Before setup there is no database: remember the device and store
        // it when setup completes.
        if (ctx.pendingDevices.length >= ServerContext.maxPendingDevices) {
          ctx.pendingDevices.removeAt(0);
        }
        deviceId = const Uuid().v4();
        ctx.pendingDevices.add(
          PendingDevice(
            id: deviceId,
            name: name,
            platform: platform,
            tokenHash: hash,
          ),
        );
      }
      return jsonOk(
        DeviceJoinResult(deviceId: deviceId, deviceToken: token).toJson(),
      );
    }),
  );
}
