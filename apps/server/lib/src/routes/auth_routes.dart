import 'package:rs_core/rs_core.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../http/api_failure.dart';
import '../http/json.dart';
import '../http/middleware.dart';
import '../security/security.dart';
import '../server_context.dart';
import '../services/mappers.dart';

/// Login, logout and the current user.
void mountAuthRoutes(Router router, ServerContext ctx) {
  final device = const Pipeline().addMiddleware(requireDevice(ctx));
  final session = const Pipeline().addMiddleware(requireSession(ctx));

  router.post(
    ApiRoutes.authLogin,
    device.addHandler((request) async {
      final server = ctx.requireServer();
      final body = await readJson(request, LoginRequest.fromJson);
      final username = body.username.trim();
      final address = remoteAddress(request);
      if (username.isEmpty || body.password.isEmpty) {
        throw const ApiFailure(
          401,
          ApiErrorCodes.invalidCredentials,
          'Wrong username or password.',
        );
      }

      final gate = server.limiter.check(username, address: address);
      if (!gate.allowed) {
        final wait = gate.retryAfter ?? const Duration(minutes: 1);
        final seconds = (wait.inMilliseconds / 1000).ceil().clamp(1, 86400);
        throw ApiFailure(
          429,
          ApiErrorCodes.rateLimited,
          'Too many failed logins. Try again in $seconds seconds.',
          headers: {'retry-after': '$seconds'},
        );
      }

      final user = server.users.byUsername(username);
      final bool valid;
      if (user == null) {
        // Same work as a real check, so timing doesn't reveal usernames.
        await ctx.hasher.verify(body.password, await ctx.dummyPasswordHash);
        valid = false;
      } else {
        valid = await ctx.hasher.verify(body.password, user.passwordHash);
      }
      if (user == null || !valid) {
        server.limiter.recordFailure(username, address: address);
        throw const ApiFailure(
          401,
          ApiErrorCodes.invalidCredentials,
          'Wrong username or password.',
        );
      }
      server.limiter.recordSuccess(username, address: address);
      if (ctx.hasher.needsRehash(user.passwordHash)) {
        server.users.updatePasswordHash(
          user.id,
          await ctx.hasher.hash(body.password),
        );
      }

      final token = Tokens.generate();
      server.sessions.create(
        userId: user.id,
        deviceId: request.auth.device.id,
        tokenHash: Tokens.hash(token),
      );
      return jsonOk(
        AuthResult(sessionToken: token, user: Mappers.user(user)).toJson(),
      );
    }),
  );

  router.post(
    ApiRoutes.authLogout,
    session.addHandler((request) async {
      final auth = request.auth;
      ctx.requireServer().sessions.deleteByTokenHash(auth.sessionTokenHash!);
      await ctx.events.disconnectSession(auth.session!.id);
      return Response(204);
    }),
  );

  router.get(
    ApiRoutes.authMe,
    session.addHandler(
      (request) => jsonOk(Mappers.user(request.auth.user!).toJson()),
    ),
  );
}
