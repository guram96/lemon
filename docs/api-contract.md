# API contract — Milestone 1

Owner: product owner. This is the spec that `rs_core` (DTOs + routes) and
`rs_api_client` implement, and that server and client code against. Change it
only through the product owner (note proposed changes in your task report).

All routes live under `ApiRoutes.base` (`/api/v1`). JSON everywhere. Errors are
`ApiError {code, message}` with the HTTP status noted below.

## Auth model

Two credentials, sent as headers:

| Header | Value | Meaning |
|---|---|---|
| `X-RS-Device` | device token | This device joined the server |
| `Authorization` | `Bearer <session token>` | A user is logged in on this device |

- Every route except `GET /server`, `POST /setup*` and `POST /devices/local`
  requires a valid device token. Every route except those and `POST /auth/login`
  also requires a session.
- Admin-only routes return `403 forbidden` for regular users.
- Tokens: 32 random bytes, base64url. The server stores only SHA-256 hashes.
- WebSocket `/events` can't send headers from browsers: it takes
  `?device=<token>&session=<token>` query parameters instead.
- New `ApiErrorCodes`: `setupRequired` (`setup_required`), `alreadyConfigured`
  (`already_configured`), `loopbackOnly` (`loopback_only`),
  `invalidCredentials` (`invalid_credentials`), `rateLimited` (`rate_limited`),
  `pathInvalid` (`path_invalid`), `conflict` (`conflict`).

`rs_core` constants: `ApiHeaders.device = 'X-RS-Device'`,
`ApiHeaders.authorization = 'Authorization'`.

## Routes

| Method & path (`ApiRoutes.*`) | Auth | Request → Response |
|---|---|---|
| `GET /server` (`serverInfo`) | public | → `ServerInfo` (exists) |
| `POST /setup/browse` (`setupBrowse`) | loopback + unconfigured, **or** admin | `BrowseRequest` → `BrowseResult` |
| `POST /setup/check-path` (`setupCheckPath`) | loopback + unconfigured, **or** admin | `PathCheckRequest` → `PathCheckResult` |
| `POST /setup` (`setup`) | loopback + unconfigured | `SetupRequest` → `AuthResult` (`201`). `409 already_configured` if set up, `403 loopback_only` if remote |
| `POST /devices/local` (`devicesLocal`) | loopback | `DeviceJoinRequest` → `DeviceJoinResult`. Same-machine auto-join |
| `POST /auth/login` (`authLogin`) | device | `LoginRequest` → `AuthResult`. `401 invalid_credentials`, `429 rate_limited` |
| `POST /auth/logout` (`authLogout`) | session | → `204` |
| `GET /auth/me` (`authMe`) | session | → `User` |
| `GET /library/systems` (`librarySystems`) | session | → `List<SystemSummary>` (only systems with ≥1 game) |
| `GET /library/games` (`libraryGames`) | session | query `system?`, `q?`, `sort=title|recent` → `GamePage` |
| `GET /library/games/{id}` (`libraryGame(id)`) | session | → `Game` |
| `GET /library/roots` (`libraryRoots`) | admin | → `List<LibraryRoot>` |
| `POST /library/scan` (`libraryScan`) | admin | → `202`, scan runs in background; `409 conflict` if one is running |
| `GET /library/scan` (`libraryScanStatus`) | session | → `ScanStatus` |
| `GET /artwork/{id}` (`artwork(id)`) | session | query `w?` → image bytes (M2) |
| `GET /events` (`events`) | device+session via query | WebSocket, server → client JSON `ServerEvent` |

`AuthResult` from `POST /setup` lets the client log the admin in in the
background right after setup, with no second login.

## DTOs (`rs_core`, freezed + json_serializable)

```dart
// ServerInfo gains: String platform   // 'macos' | 'windows' | 'linux' — the setup UI
//                                        uses it to show OS-specific permission help


// setup
BrowseRequest { String? path }            // null → roots: home dir, mounted volumes / drives
BrowseResult  { String path; String? parent; List<BrowseEntry> entries; List<BrowseEntry> shortcuts }
BrowseEntry   { String name; String path; bool isDirectory; bool readable }
// shortcuts: Home, Desktop, Documents, mounted volumes (/Volumes/*, drive letters, /media, /mnt)

enum PathKind { dataDir, libraryRoot }
PathCheckRequest { String path; PathKind kind }
PathCheckResult {
  String path;            // normalized absolute
  bool exists; bool readable; bool writable;
  bool permissionDenied;  // OS refused access (macOS TCC, ACLs) → show how to grant
  String? existingMarkerId;  // .retrosteam/root.json found (adopt existing root/data dir)
  List<DetectedSystem> detectedSystems;  // libraryRoot only
  int? freeBytes;
  List<String> warnings;  // e.g. "read-only filesystem", "not empty"
  bool get ok;            // dataDir: exists-or-creatable && writable; libraryRoot: readable
}
DetectedSystem { String systemId; int fileCount }

SetupRequest {
  String adminUsername; String adminPassword;   // password ≥ 8 chars
  String dataDir; List<String> libraryRoots;    // ≥1 root
  String deviceName;                            // the setup device auto-joins
}

// devices + auth
DeviceJoinRequest { String deviceName; String platform }   // platform: macos, windows, linux, android, ios, web
DeviceJoinResult  { String deviceId; String deviceToken }
LoginRequest { String username; String password }
AuthResult   { String sessionToken; User user; String? deviceId; String? deviceToken }
             // deviceId/deviceToken set only by POST /setup

// library
SystemSummary { String systemId; String name; int gameCount }
GamePage { List<Game> games; int total }
// Game gains: DateTime addedAt  (for "recently added" shelf)

// scanning
enum ScanPhase { idle, discovering, hashing, saving, done, failed }
ScanStatus {
  ScanPhase phase;
  int processed; int total;      // files
  String? currentSystemId; String? currentFile;
  int added; int updated; int removed;
  DateTime? startedAt; DateTime? finishedAt;
  String? error;
}

// push events: sealed freezed union, JSON discriminator "type"
ServerEvent =
  | scanProgress(ScanStatus status)          // type: "scan_progress", throttled ≤ 4/s
  | libraryChanged(List<String> addedIds, List<String> updatedIds, List<String> removedIds)  // type: "library_changed"
  | rootStatusChanged(LibraryRoot root)       // type: "root_status_changed"
```

## `RsApiClient` (rs_api_client)

```dart
RsApiClient({required Uri baseUri, http.Client? httpClient, String? deviceToken, String? sessionToken})
// setters: deviceToken, sessionToken (mutable so the app can update after login)
getServerInfo()
browse(String? path) → BrowseResult
checkPath(String path, PathKind kind) → PathCheckResult
setup(SetupRequest) → AuthResult
joinLocal(DeviceJoinRequest) → DeviceJoinResult
login(String username, String password) → AuthResult
logout(); me() → User
systems() → List<SystemSummary>
games({String? system, String? query, String sort = 'title'}) → GamePage
game(String id) → Game
roots() → List<LibraryRoot>
startScan(); scanStatus() → ScanStatus
Uri artworkUri(String artworkId, {int? width})   // for Image.network; token passed as header in M2
Stream<ServerEvent> events()   // web_socket_channel (web-safe), reconnects with backoff
```
