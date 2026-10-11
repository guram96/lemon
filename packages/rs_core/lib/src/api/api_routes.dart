/// HTTP routes of the server API, shared by server and client.
abstract final class ApiRoutes {
  static const version = 1;
  static const base = '/api/v$version';

  /// `GET` → [ServerInfo]. Public, used for discovery and health checks.
  static const serverInfo = '$base/server';

  /// WebSocket endpoint for push events (scan progress, library changes).
  static const events = '$base/events';
}
