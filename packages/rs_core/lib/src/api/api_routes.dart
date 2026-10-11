/// HTTP routes of the server API, shared by server and client.
///
/// See `docs/api-contract.md` for auth requirements and payloads.
abstract final class ApiRoutes {
  static const version = 1;
  static const base = '/api/v$version';

  /// `GET` → [ServerInfo]. Public, used for discovery and health checks.
  static const serverInfo = '$base/server';

  /// `POST` [BrowseRequest] → [BrowseResult]. Folder picker for setup and
  /// settings.
  static const setupBrowse = '$base/setup/browse';

  /// `POST` [PathCheckRequest] → [PathCheckResult].
  static const setupCheckPath = '$base/setup/check-path';

  /// `POST` [SetupRequest] → [AuthResult] (`201`). Loopback and unconfigured
  /// only.
  static const setup = '$base/setup';

  /// `POST` [DeviceJoinRequest] → [DeviceJoinResult]. Same-machine auto-join,
  /// loopback only.
  static const devicesLocal = '$base/devices/local';

  /// `POST` [LoginRequest] → [AuthResult].
  static const authLogin = '$base/auth/login';

  /// `POST` → `204`.
  static const authLogout = '$base/auth/logout';

  /// `GET` → [User].
  static const authMe = '$base/auth/me';

  /// `GET` → `List<SystemSummary>`.
  static const librarySystems = '$base/library/systems';

  /// `GET` with query `system?`, `q?`, `sort` → [GamePage].
  static const libraryGames = '$base/library/games';

  /// `GET` → [Game].
  static String libraryGame(String id) =>
      '$libraryGames/${Uri.encodeComponent(id)}';

  /// `GET` → [DownloadManifest]. Any logged-in user.
  static String gameDownload(String id) => '${libraryGame(id)}/download';

  /// `GET` raw bytes of catalog file [index]. Honors one `Range` header.
  static String gameDownloadFile(String id, int index) =>
      '${gameDownload(id)}/$index';

  /// `GET` → `List<LibraryRoot>`. Admin only.
  static const libraryRoots = '$base/library/roots';

  /// `POST` → `202` starts a scan (admin). `GET` → [ScanStatus].
  static const libraryScan = '$base/library/scan';

  /// `GET` → [ScanStatus]. Same path as [libraryScan].
  static const libraryScanStatus = libraryScan;

  /// `GET` → [ScraperStatus]. `PUT` [ScraperSettingsUpdate] → [ScraperStatus].
  /// Admin only. Secrets are never returned.
  static const scraperSettings = '$base/settings/scrapers';

  /// Prefix of [artwork].
  static const artworkBase = '$base/artwork';

  /// `GET` with query `w?` → image bytes.
  static String artwork(String id) => '$artworkBase/${Uri.encodeComponent(id)}';

  /// WebSocket endpoint for push events ([ServerEvent]). Takes `device` and
  /// `session` query parameters, see [ApiQueryParams].
  static const events = '$base/events';
}

/// Header names used for authentication.
abstract final class ApiHeaders {
  /// Device token: this device joined the server.
  static const device = 'X-RS-Device';

  /// `Bearer <session token>`: a user is logged in on this device.
  static const authorization = 'Authorization';

  static const bearerPrefix = 'Bearer ';
}

/// Query parameter names used by the API.
abstract final class ApiQueryParams {
  /// Device token on the `/events` WebSocket.
  static const device = 'device';

  /// Session token on the `/events` WebSocket.
  static const session = 'session';

  /// System filter on [ApiRoutes.libraryGames].
  static const system = 'system';

  /// Search text on [ApiRoutes.libraryGames].
  static const query = 'q';

  /// Sort order on [ApiRoutes.libraryGames], see [GameSort].
  static const sort = 'sort';

  /// Requested width on [ApiRoutes.artwork].
  static const width = 'w';
}

/// Values of the `sort` query parameter on [ApiRoutes.libraryGames].
abstract final class GameSort {
  static const title = 'title';
  static const recent = 'recent';
}
