import 'dart:io';

import 'package:logging/logging.dart';
import 'package:rs_core/rs_core.dart';
import 'package:shelf/shelf.dart';

import '../db/auth_repos.dart';
import '../security/tokens.dart';
import '../server_context.dart';
import '../services/configured_server.dart';
import 'api_failure.dart';
import 'json.dart';

final _log = Logger('http');

// --- Generic ------------------------------------------------------------------

const _corsHeaders = {
  'access-control-allow-origin': '*',
  'access-control-allow-methods': 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
  'access-control-allow-headers':
      'Authorization, Content-Type, ${ApiHeaders.device}',
  'access-control-expose-headers': 'Retry-After',
  'access-control-max-age': '600',
};

/// CORS for the web client. Credentials are explicit headers (no cookies),
/// so a wildcard origin is safe; loopback-only routes check `Origin`
/// themselves (see [requireLocal]).
Middleware cors() =>
    (inner) => (request) async {
      if (request.method == 'OPTIONS') {
        return Response(204, headers: _corsHeaders);
      }
      final response = await inner(request);
      return response.change(headers: _corsHeaders);
    };

Middleware requestLogger() =>
    (inner) => (request) async {
      final watch = Stopwatch()..start();
      final response = await inner(request);
      _log.fine(
        '${request.method} /${request.url.path} → ${response.statusCode} '
        '(${watch.elapsedMilliseconds} ms)',
      );
      return response;
    };

/// Turns exceptions into JSON [ApiError]s: [ApiFailure] and known storage /
/// filesystem errors keep their status, anything else becomes a bare 500.
Middleware errorHandler() =>
    (inner) => (request) async {
      try {
        return await inner(request);
      } on HijackException {
        rethrow;
      } on Object catch (e, st) {
        final failure = apiFailureFor(e);
        if (failure != null) {
          if (e is! ApiFailure) _log.fine('/${request.url.path}: $e');
          return failure.toResponse();
        }
        _log.severe('Unhandled error on /${request.url.path}', e, st);
        return jsonError(500, ApiErrorCodes.internal, 'Internal server error');
      }
    };

// --- Loopback -----------------------------------------------------------------

/// Whether the TCP peer is this machine (127.0.0.0/8, ::1 or IPv4-mapped
/// loopback). Requests without connection info (in-process) are not local.
bool isLoopbackRequest(Request request) {
  final info = request.context['shelf.io.connection_info'];
  if (info is! HttpConnectionInfo) return false;
  final address = info.remoteAddress;
  if (address.isLoopback) return true;
  return address.address.toLowerCase().startsWith('::ffff:127.');
}

/// A browser `Origin` that is not this machine means a web page is trying to
/// use the loopback-only routes (CSRF / DNS rebinding): refuse it. Native
/// clients send no `Origin`.
bool hasLocalOrigin(Request request) {
  final origin = request.headers['origin'];
  if (origin == null || origin.isEmpty) return true;
  final host = Uri.tryParse(origin)?.host.toLowerCase();
  return host == 'localhost' || host == '127.0.0.1' || host == '::1';
}

/// Loopback peer and no foreign browser origin.
bool isLocalRequest(Request request) =>
    isLoopbackRequest(request) && hasLocalOrigin(request);

/// Allows only requests from this machine (`403 loopback_only`).
Middleware requireLocal() =>
    (inner) => (request) {
      if (!isLocalRequest(request)) throw const ApiFailure.loopbackOnly();
      return inner(request);
    };

/// The client address, for login rate limiting.
String? remoteAddress(Request request) {
  final info = request.context['shelf.io.connection_info'];
  return info is HttpConnectionInfo ? info.remoteAddress.address : null;
}

// --- Auth ---------------------------------------------------------------------

const _authKey = 'rs.auth';

/// Who is calling: always a joined device, plus a logged-in user on session
/// routes.
class RequestAuth {
  const RequestAuth({
    required this.device,
    this.user,
    this.session,
    this.sessionTokenHash,
  });

  final DeviceRecord device;
  final UserRecord? user;
  final SessionRecord? session;
  final String? sessionTokenHash;

  bool get isAdmin => user?.isAdmin ?? false;
}

extension RequestAuthX on Request {
  /// Set by [requireDevice] / [requireSession]. Throws if neither ran.
  RequestAuth get auth =>
      context[_authKey] as RequestAuth? ??
      (throw StateError('No auth middleware on this route'));

  /// Like [auth], but `null` when no auth middleware ran.
  RequestAuth? get authOrNull => context[_authKey] as RequestAuth?;
}

/// How often a device's `last_seen_at` is written at most.
const _touchInterval = Duration(minutes: 1);

/// The joined device for [token], or `null`.
DeviceRecord? deviceForToken(ConfiguredServer server, String? token) {
  if (token == null || !Tokens.isWellFormed(token)) return null;
  final device = server.devices.byTokenHash(Tokens.hash(token));
  if (device == null) return null;
  final seen = device.lastSeenAt;
  if (seen == null || DateTime.now().difference(seen) > _touchInterval) {
    server.devices.touch(device.id);
  }
  return device;
}

/// The session for [token] on [device] with its user, or `null`.
(SessionRecord, UserRecord, String)? sessionForToken(
  ConfiguredServer server,
  DeviceRecord device,
  String? token,
) {
  if (token == null || !Tokens.isWellFormed(token)) return null;
  final hash = Tokens.hash(token);
  final session = server.sessions.validate(hash);
  // A session is bound to the device it was created on.
  if (session == null || session.deviceId != device.id) return null;
  final user = server.users.byId(session.userId);
  if (user == null) return null;
  return (session, user, hash);
}

String? _bearer(Request request) {
  final header = request.headers[ApiHeaders.authorization];
  if (header == null) return null;
  const prefix = ApiHeaders.bearerPrefix;
  if (header.length <= prefix.length ||
      header.substring(0, prefix.length).toLowerCase() !=
          prefix.toLowerCase()) {
    return null;
  }
  return header.substring(prefix.length).trim();
}

RequestAuth _deviceAuth(ServerContext ctx, Request request) {
  final server = ctx.requireServer();
  final device = deviceForToken(server, request.headers[ApiHeaders.device]);
  if (device == null) {
    throw const ApiFailure.unauthorized(
      'This device is not paired with the server.',
    );
  }
  return RequestAuth(device: device);
}

RequestAuth _sessionAuth(ServerContext ctx, Request request) {
  final device = _deviceAuth(ctx, request).device;
  final found = sessionForToken(ctx.requireServer(), device, _bearer(request));
  if (found == null) {
    throw const ApiFailure.unauthorized(
      'Not logged in, or the session expired.',
    );
  }
  final (session, user, hash) = found;
  return RequestAuth(
    device: device,
    user: user,
    session: session,
    sessionTokenHash: hash,
  );
}

/// Requires a valid `X-RS-Device` token (`401 unauthorized`).
Middleware requireDevice(ServerContext ctx) =>
    (inner) =>
        (request) => inner(
          request.change(context: {_authKey: _deviceAuth(ctx, request)}),
        );

/// Requires a device and a session (`401 unauthorized`); with [admin], also
/// the admin role (`403 forbidden`).
Middleware requireSession(ServerContext ctx, {bool admin = false}) =>
    (inner) => (request) {
      final auth = _sessionAuth(ctx, request);
      if (admin && !auth.isAdmin) {
        throw const ApiFailure.forbidden('Only the admin can do this.');
      }
      return inner(request.change(context: {_authKey: auth}));
    };

/// Setup tools (browse, check path): allowed from this machine while the
/// server is unconfigured, and for the admin afterwards.
Middleware requireSetupToolAccess(ServerContext ctx) =>
    (inner) => (request) {
      if (ctx.server == null) {
        if (!isLocalRequest(request)) throw const ApiFailure.loopbackOnly();
        return inner(request);
      }
      return requireSession(ctx, admin: true)(inner)(request);
    };
