# Retro Steam — task board

Product owner: Claude (orchestrator). Agents follow `docs/agent-rules.md`.
API spec: `docs/api-contract.md`.

## What we're building

**Steam for your retro ROM collection, on your own network.**

```
 ┌────────────── desktop machine ──────────────┐         ┌──── any device ────┐
 │  ROM folders (ES layout)   data dir (SQLite, │  LAN    │  Retro Steam client │
 │  /Volumes/HDD/roms/snes/   artwork, caches)  │ ◄─────► │  Big Picture UI     │
 │            ▲                     ▲           │ HTTP+WS │  browse · download  │
 │            └──── rs_server ──────┘           │         │  launch emulator    │
 │   scan · hash · scrape · serve · admin API   │         └─────────────────────┘
 └──────────────────────────────────────────────┘
```

- **Server** (`rs_server`, pure Dart, one binary): scans ES-named ROM folders,
  identifies games by hash, scrapes metadata and Steam-style artwork, serves the
  catalog, artwork and resumable downloads, pushes live events over WebSocket.
- **Client** (`rs_client`, Flutter, every platform): a one-to-one Steam Big
  Picture experience — controller-first, swappable look. Joins a server, logs
  in, browses, downloads games into the emulator's folders and launches them.
- **Contract** (`rs_core` + `rs_api_client`): the only thing the two share.

### The first-run experience (shipped in M1)

```
start client on the server machine
  → finds server on localhost (unconfigured)
  → Welcome            "Welcome to Retro Steam"            [Get started]
  → 1 Admin account    username · password · confirm
  → 2 Data folder      browse server disk · check write access · permission help
  → 3 Game library     add ROM folders · detected systems + counts · read-only / permission warnings
  → 4 Review           summary                              [Finish setup]
  → Setting up…        server creates DB, markers, admin; device joins; admin logged in (background)
  → Congratulations    "You're all set"                    [Go to library]
  → Home (Big Picture) shelves of game cards fill in live
                        toast: "Scanning library… 312 / 1 204"  →  "42 games added"
```

## Milestones

| | Milestone | Outcome |
|---|---|---|
| **M1** ✅ | First run → Home | Setup wizard, background login, scan with live progress, Big Picture home/library/game page with generated art |
| **M2** ✅ | Art & metadata | ScreenScraper + SteamGridDB scraping, artwork pipeline & serving, real hero/logo/capsules, file watching |
| **M3** ✅ | Downloads | Install destinations, download queue (pause/resume, range requests), installed state, uninstall, Downloads page |
| **M4** ✅ | Play | Emulator detection (RetroArch + cores, standalone), launch options per game/system, managed emulator manifest |
| M5 | Multi-device | A second device on the LAN pairs and logs in. The admin can revoke it and can create a regular user |
| M6 | Admin library | Add one game, edit its title and metadata, delete it, and save scraper credentials. Overrides, moving the data folder, and reopening setup are later tasks in this milestone |
| M7 | Polish | Search, a saved theme, a gamepad on the existing button map, an on-screen keyboard, and an accessibility pass |
| M8 | One app | The macOS app drops the sandbox, then a disk image starts the bundled server and opens the library. Login item, Windows, and Linux are separate tasks |

Status legend: ⬜ todo · 🟦 in progress · ✅ done · ⛔ blocked

---

## M1 — First run → Home

Dependency graph (waves run in parallel inside, sequential across):

```
Wave 1:  T1 contract ─┐   T2 UI kit ─┐   T3 server storage ─┐   T4 scanner ─┐
Wave 2:               ├── T5 server API (needs T1,T3,T4) ───────────────────┘
                      └── T6 client shell (needs T1,T2)
Wave 3:                   T7 onboarding UI (needs T2,T6)   T8 home & library UI (needs T2,T6)
Wave 4:                   T9 integration + E2E on macOS (product owner)
```

### T1 — Contract: rs_core DTOs + rs_api_client ✅
**Owns:** `packages/rs_core/`, `packages/rs_api_client/`
- Implement everything in `docs/api-contract.md`: routes, headers, error codes,
  DTOs (freezed/json_serializable, run build_runner), `ServerInfo.platform`,
  `Game.addedAt`, sealed `ServerEvent` with `type` discriminator.
- `RsApiClient`: all methods, device/session headers, `events()` stream over
  `web_socket_channel` with reconnect + backoff. Stays web-safe (no `dart:io`).
- Tests: JSON round-trips for every DTO (incl. each `ServerEvent` variant),
  `RsApiClient` against `MockClient` (headers sent, errors → `ApiException`).
- Also fix the server compile if `ServerInfo` gains a required field: the only
  allowed edit outside your packages is `apps/server/lib/src/routes/server_info_routes.dart`
  (fill `platform` from `Platform.operatingSystem`).

### T2 — Big Picture UI kit: rs_ui + rs_ui_steam ✅
**Owns:** `packages/rs_ui/`, `packages/rs_ui_steam/`, `packages/rs_theme/` (token additions only)
Abstract component in `rs_ui` + Steam implementation + widget test for each
(see "Adding a component" in CLAUDE.md). Faithful to Steam Big Picture (2023+ / Deck UI):
dark blue-grey gradients, bright focus highlight, subtle scale-up + glow on focused
capsules, Motiva-Sans-like typography (use a bundled/Google-free fallback, no network fonts).
- `RsScaffold` — page frame: optional top bar, body, bottom button-hint bar.
- `RsTopBar` / `RsNavBar` — Big Picture top bar: nav items (Home, Library, …), right side clock, notifications bell with badge, user avatar. LB/RB (`RsTabIntent`) cycles items.
- `RsButtonHints` — bottom bar: glyph + label pairs (A Select, B Back, …). Glyph set is a token/enum (Xbox style default).
- `RsTextField` — label, hint, obscure (password), error text, focus styling; typing must not be swallowed by global shortcuts.
- `RsDialog` (+ `showRsDialog`) — modal, focus trapped, B closes.
- `RsShelf` — titled horizontal row of focusable items; keeps focused item in view; remembers last focused child.
- `RsGameCard` — game capsule (2:3 cover or wide capsule variant), focus scale/glow, optional badges (installed, system). **Generated fallback art** when no image: deterministic gradient from system/title + title text + system name, so M1 looks good without scraping.
- `RsGrid` — focusable responsive grid for the library.
- `RsTabs` — horizontal tabs (system filter), LB/RB switching.
- `RsProgressBar`, `RsSpinner`.
- `RsToast` — Big Picture notification: icon, title, body, optional progress; used bottom-right.
- `RsListRow` — settings-style row: leading icon, title, subtitle, trailing (value/toggle/chevron); focusable.
- `RsWizardFrame` — first-run frame like Steam Deck OOBE: step indicator, title, subtitle, content, footer actions (Back / Continue). Responsive down to phone width.
- `RsHero` — game page header: wide background image (or generated), gradient fade, logo or title text overlay.
- Add any tokens you need to `RsTokens` (both light and dark).
- Add an exported `SteamGallery` widget (`rs_ui_steam/lib/src/gallery.dart`) that shows every component, so the product owner can preview the look.

### T3 — Server storage & security foundation ✅
**Owns:** `apps/server/lib/src/storage/`, `apps/server/lib/src/db/`, `apps/server/lib/src/security/`, `apps/server/lib/src/fs/`, matching `apps/server/test/<same>/`, `apps/server/pubspec.yaml` (add deps)
- **Markers:** `<dir>/.retrosteam/root.json` `{id, kind: data|library, label, createdAt}`; create/read; read-only roots can't get a marker → identify by stored id + last path, status `readOnly`.
- **Data dir:** layout (`retrosteam.db`, `artwork/`, `cache/`, `tmp/`), create/adopt.
- **SQLite** (`package:sqlite3`, bundled native lib) with versioned migrations. Tables: settings, users, devices, sessions, login_attempts, roots (id, label, last_path, status), games (id, system_id, root_id, title, region, added_at, updated_at, description, developer, publisher, release_year), game_files (game_id, rel_path, size, mtime, crc32, md5, sha1), artwork (later columns ok). Repositories with plain SQL: `UserRepo`, `DeviceRepo`, `SessionRepo`, `RootRepo`, `GameRepo` (upsert scanned games, diff → added/updated/removed ids, list/filter/sort/search, system summaries).
- **Security:** Argon2id password hashing (pure Dart), constant-time compare, token generation (32 bytes base64url) + SHA-256 storage, login rate limiter/lockout.
- **fs:** `PathGuard` (root id + relative → safe absolute; rejects `..`, absolute, drive letters, reserved Windows names, symlink escape), `PathProbe` (exists/readable/writable/permissionDenied/read-only FS/free bytes/marker id/detected ES systems with file counts), `DirectoryBrowser` (list dirs; shortcuts: home, Desktop, Documents, `/Volumes/*`, drive letters, `/media`, `/mnt`). macOS: detect TCC denial (EPERM / "Operation not permitted") as `permissionDenied`.
- Tests for all of it with temp dirs. No HTTP code.

### T4 — ROM scanner engine ✅
**Owns:** `apps/server/lib/src/scanner/`, `apps/server/test/scanner/`
Pure engine, no DB, no HTTP: `Scanner.scan(rootPath, {previous index}) → Stream<ScanProgress>` + final `List<ScannedGame>`.
- Walk `<root>/<esSystemId>/` for systems in `GameSystems.all`; accept only matching extensions; skip hidden files, `.retrosteam`, and ES media subfolders (`media`, `images`, `videos`, `manuals`, `downloaded_media`).
- Group game units: `.cue` + its `.bin` tracks, `.gdi` + tracks, `.m3u` + listed discs (discs not listed twice), multi-disc name patterns `(Disc 1)` without m3u → one game. A sub-directory per game is also allowed.
- Titles from file names: strip extension and tags (`(USA)`, `[!]`, `(Rev 1)`, `(Disc 1)`), keep region separately.
- Hashing CRC32/MD5/SHA1 in one streaming pass, in an isolate pool; skip re-hashing when (size, mtime) match the previous index; files > 4 GiB: hash size + first/last 64 MiB only, flag `partialHash`.
- Progress events: phase, processed/total, current system/file. Cancellable.
- Stable game identity for diffing: (rootId, systemId, primary file rel path).
- Tests with generated fixture trees in temp dirs.

### T5 — Server API: setup, auth, library, scan, events ✅ (after T1, T3, T4)
**Owns:** `apps/server/lib/src/routes/`, `apps/server/lib/src/http/`, `apps/server/lib/src/services/`, `apps/server/lib/src/server_context.dart`, `apps/server/lib/rs_server.dart`, `apps/server/bin/`, `apps/server/test/` (except T3/T4 subfolders)
- Auth middleware (device + session, admin guard), loopback check from `shelf.io.connection_info`.
- Every route in `docs/api-contract.md`. `POST /setup`: validate paths, create data dir + markers, open DB, create admin, register roots, save bootstrap config (`dataDir`), join the requesting device, create session, **start the initial scan**, return `AuthResult`.
- `ScanService`: one scan at a time over all online roots, persists via `GameRepo`, publishes throttled `scanProgress` and `libraryChanged` (batched during scan so the home screen fills in live).
- `EventHub` + `/events` WebSocket (`shelf_web_socket`), auth via query params.
- Startup: if configured, open DB, refresh root status (offline/readOnly), serve.
- Integration tests: full setup → login → scan → list games over real HTTP + WebSocket against temp dirs.

### T6 — Client shell: connection, session, events, notifications ✅ (after T1, T2)
**Owns:** `apps/client/lib/main.dart`, `apps/client/lib/src/{app,routing,platform,connection,session,events,notifications,storage}/`, `apps/client/pubspec.yaml`, `apps/client/test/` (shell tests), `apps/client/macos/` entitlements
- `CredentialStore` (shared_preferences now, interface for secure storage later): server base URI, server id, device token, session token, user.
- `connectionProvider`: probe `http://127.0.0.1:47320` at startup → states `searching | unreachable | unconfigured | ready`. Unreachable → a simple "Server not found" page with Retry and manual address field.
- `apiClientProvider`, `sessionProvider` (Notifier: login, logout, `adoptAuthResult` used by setup), same-machine auto-join via `POST /devices/local` when no device token.
- Router with redirect guards: unconfigured → `/welcome`; no session → `/login`; else `/home`. Routes: `/connect`, `/welcome`, `/setup`, `/setup/done`, `/login`, `/home`, `/library`, `/game/:id`. Create **stub pages** with these exact class names so T7/T8 only replace file contents: `onboarding/welcome_page.dart` `WelcomePage`, `onboarding/setup_wizard_page.dart` `SetupWizardPage`, `onboarding/setup_done_page.dart` `SetupDonePage`, `auth/login_page.dart` `LoginPage`, `home/home_page.dart` `HomePage`, `library/library_page.dart` `LibraryPage`, `game/game_page.dart` `GameDetailPage`.
- Main shell (`ShellRoute`) for home/library/game: `RsScaffold` + `RsTopBar` (Home, Library) + `RsButtonHints`.
- `eventsProvider` (stream from `RsApiClient.events()` while a session exists), `scanStatusProvider`, `libraryRevisionProvider` (bumps on `libraryChanged` so library providers refetch).
- `NotificationCenter` (Notifier) + overlay host rendering `RsToast`s bottom-right; scan progress shows one persistent toast that updates, then a summary toast on done.
- macOS: keep sandbox; add needed entitlements (network client already). Verify `flutter run -d macos` builds.

### T7 — Onboarding UI: welcome → setup wizard → congratulations, login ✅ (after T2, T6)
**Owns:** `apps/client/lib/src/onboarding/`, `apps/client/lib/src/auth/`, matching tests
- `WelcomePage`: Big Picture welcome splash, server name, [Get started].
- `SetupWizardPage` built on `RsWizardFrame`, steps: Admin account (username, password ≥ 8, confirm, inline validation) → Data folder (server-side folder browser dialog via `browse`, `checkPath`, shows writable/free space/existing data dir "will be adopted") → Game library (add/remove roots, detected systems + counts, read-only and permission warnings) → Review → Finishing (calls `setup`, progress, error recovery).
- **Folder permission help**: when `permissionDenied`, show OS-specific steps from `ServerInfo.platform` (macOS: System Settings → Privacy & Security → Full Disk Access / Files and Folders → enable the server/terminal app; Windows: folder security; Linux: chmod/group) + [Check again].
- On success: `sessionProvider.adoptAuthResult` (background login) → `SetupDonePage` "You're all set" (systems/files found so far) → [Go to library] → `/home`.
- `LoginPage`: username/password for returning sessions.
- Fully usable with keyboard/d-pad only. Widget tests with a fake `RsApiClient`.

### T8 — Home, library and game page ✅ (after T2, T6)
**Owns:** `apps/client/lib/src/home/`, `apps/client/lib/src/library/`, `apps/client/lib/src/game/`, matching tests
- Providers: `systemsProvider`, `gamesProvider(filter)`, `gameProvider(id)`, all refetching on `libraryRevisionProvider`.
- `HomePage` (Big Picture home): large background that cross-fades to the focused game's art, "Recently added" shelf of big capsules, then one `RsShelf` per system. Empty / scanning state ("Scanning your library — games appear as they're found") with live progress.
- `LibraryPage`: `RsTabs` (All + one per system, LB/RB) over an `RsGrid` of `RsGameCard`s, sort title/recent.
- `GameDetailPage`: `RsHero`, title, system, size, file list, metadata; green primary button "Install" disabled with "Downloads arrive in M3" (hidden on web via `ClientCapabilities`).
- Live updates when games are added during scanning, without losing focus.
- Widget tests with fake providers.

### T9 — Integration & E2E on macOS ✅ (product owner, after all)
- `dart tool/check.dart` green; resolve agent requests; run server + client on macOS; walk the full first-run flow with a sample ROM tree; fix gaps; update this board.
- Verified: full check passed. A real server (temp config, sample NES + SNES ROMs) went unconfigured → setup → scan done, cataloging Super Mario Bros and Super Mario World. The macOS client built and launched against that server. No agent requests were open.

---

## M2 — Art & metadata

Scraped art and metadata replace the generated capsules. Credentials live in server settings (the settings screen itself is M6). Per-game artwork overrides are stored but not browsed until M6: a scrape never replaces a row with `is_override = 1`.

```
Wave 1:  T10 artwork store ─┐  T11 ScreenScraper ─┐  T12 SteamGridDB ─┐  T13 watcher ─┐
Wave 2:                    ├── T14 scrape service (T10, T11, T12, T13) ───────────────┘
                           └── T15 serve GET /artwork (T10)
Wave 3:                    T16 client shows the art that T14 stored (T15)
```

### T10 — Artwork store & image pipeline ✅
**Owns:** `apps/server/lib/src/artwork/`, `apps/server/test/artwork/`, `image` in `apps/server/pubspec.yaml`. May attach artwork onto `Game` JSON in `mappers.dart` and `library_routes.dart`.
- `ArtworkRepo`: one row per (game, kind). `putScraped` refuses to replace `is_override = 1`. Files live in the data dir `artwork/` as `{id}.png` (alpha) or `{id}.jpg`.
- Decode with size caps (25 MB, 8192 px edge, 16 megapixels). Re-encode so uploaded bytes are never served raw.
- Resize cache under `cache/artwork/{id}/w{width}` for `GET /artwork/{id}?w=`. Width 1–2048; at or above the original width, serve the original.
- `Game` list and detail include the `artwork` map. Unknown ids stay 404.
- Tests with generated images. No HTTP, no scraping.

### T11 — ScreenScraper client ✅
**Owns:** `apps/server/lib/src/scrape/screenscraper/`, `apps/server/test/scrape/screenscraper_test.dart`, `http` in the server pubspec.
- Pure client. `http.Client` is injected. No settings I/O.
- `lookup` by CRC32/MD5/SHA1, optional ES system id → ScreenScraper `systemeid`. If the system is unknown or the hit misses, retry with the hash alone.
- Parse title, description, developer, publisher, year, and media URLs mapped onto `ArtworkKind` (box → cover, fanart → hero, wheel → logo, screen → screenshot). Prefer `us`, then `wor`, `eu`, `jp`.
- One request at a time, with a minimum gap (default 1.2 s) so a scrape can't burst the quota. Tests use a zero gap and fixture JSON. No live network.

### T12 — SteamGridDB client ✅ (after nothing; parallel with T10–T13)
**Owns:** `apps/server/lib/src/scrape/steamgriddb/`, matching tests.
- Bearer API key, injected `http.Client`. Search by name, then grids / heroes / logos / icons.
- Static images only. Map 600×900 grids → cover, 460×215 → capsule, heroes → hero, logos → logo, icons → icon.
- Same one-at-a-time pacing. Fixture tests, no live network.

### T13 — Library root watcher ✅
**Owns:** `apps/server/lib/src/watch/`, matching tests.
- `Directory.watch` on each online root, recursive. Debounce until 2 s quiet.
- Ignore hidden names, `.retrosteam`, and ES media folders (`media`, `images`, `videos`, `manuals`, `downloaded_media`).
- Emit `RootLibraryChange {rootId}` — the scan engine already diffs, so the event does not list files.
- Tests with temp dirs. No HTTP, no DB.

### T14 — Scrape service ✅ (after T10, T11, T12)
**Owns:** `apps/server/lib/src/services/scrape_service.dart`, `apps/server/lib/src/routes/settings_routes.dart`, settings keys, a short addition to `docs/api-contract.md` if the DTOs below are not there yet.
- Runs after a scan finishes, and when the watcher asks for a rescan. One scrape at a time. Skips games that already have metadata and every artwork kind, and never replaces an override.
- ScreenScraper fills identity, metadata (only fields that are still null), cover, screenshot, and logo/hero fallbacks. SteamGridDB fills hero, logo, capsule, icon, and cover when still missing.
- Downloads are capped (25 MB), checked by the image pipeline, then stored. Each saved game publishes `libraryChanged` so clients pick up the art.
- Credentials in `settings`: `scrapers.screenscraper.{devId,devPassword,username,password}` and `scrapers.steamgriddb.apiKey`. Missing credentials: the scrape no-ops.
- Admin API, secrets never returned:
  - `GET /settings/scrapers` → `{screenScraper: bool, steamGridDb: bool}`
  - `PUT /settings/scrapers` → `{screenScraper?: {devId, devPassword, username, password}, steamGridDbApiKey?: string}`. Omit a field to leave it; `""` clears that provider.
- The settings UI is M6. Tests use fake clients and temp dirs.

### T15 — Serve artwork ✅ (after T10; can land with T10)
**Owns:** the `GET /artwork/{id}` handler and its test.
- Session required. `?w=` resizes through the T10 cache. `Content-Type` matches the bytes. Path stays inside the artwork directory.

### T16 — Client art ✅ (after T14, T15)
**Owns:** `apps/client/lib/src/library/game_art.dart` and library/game tests only if something still fails.
- Cards, shelves, and the hero already draw `Game.artwork` and fall back to generated art. Confirm a library refresh after `libraryChanged` swaps in the real image without dropping focus. Fix only the gaps.

---

## M3 — Downloads

The user picks where games are installed. The server streams each catalog file with HTTP ranges. The client queues one job per game, resumes after a pause or a restart, and uninstall deletes only the local files.

Web has no install, queue, or Downloads page (`ClientCapabilities.canInstallGames`).

```
Wave 1:  T17 server range download ─┐  T18 install store ─┐
Wave 2:                             └── T19 download queue (T17, T18)
Wave 3:                                T20 Downloads page + Install button (T19)
```

### T17 — ROM download ✅
**Owns:** `packages/rs_core/lib/src/library/download.dart` (and its generated files), the new constants in `packages/rs_core/lib/src/api/api_routes.dart`, `packages/rs_api_client/` download methods, `apps/server/lib/src/routes/library_routes.dart` download handlers only, `apps/server/test/download/`.
- Contract is in `docs/api-contract.md` under "M3 additions". Do not edit that file.
- `DownloadManifest` / `DownloadFile` freezed models. Run `dart run build_runner build -d` in `packages/rs_core` and commit the generated files in the tree (do not git-commit).
- `GET /library/games/{id}/download` and `GET .../download/{index}`. Session, not admin. Resolve the file from the catalog (root id + stored relative path) through `PathGuard`. Never use a client-supplied path.
- Stream with `File.openRead`. Support a single `Range`. `200`, `206`, `416`, `404`, `409` as in the contract.
- `RsApiClient.downloadManifest` and `openGameFile(gameId, index, {int? start})` return a stream for 200/206 and throw `ApiException` otherwise. Stay web-safe: no `dart:io`.
- Tests: temp ROM, full body, a middle range, a range past EOF, unknown index, offline root. No live network beyond loopback.

### T18 — Install store ✅
**Owns:** `apps/client/lib/src/install/`, `apps/client/test/install/`.
- Device-local. Not the server API. One JSON file, atomic replace. Inject the directory so tests use a temp dir. No new dependency.
- Conditional import so the implementation's `dart:io` does not break the web build. The stub throws if called.
- Destinations: one global folder, plus an optional folder per system id. `folderFor(systemId)` returns the override or the global folder. `null` when nothing is set.
- Records keyed by `serverId` + `gameId`: phase `queued | downloading | paused | installed | failed`, `receivedBytes`, `totalBytes`, optional error, and one progress row per file (`index`, system-relative `path`, `receivedBytes`, `sizeBytes`, `complete`).
- `put` replaces the record. `remove` drops it. `installs(serverId)` lists that server only.
- Uninstall helper: delete only the recorded files, and only when the resolved path stays inside `folderFor(systemId)`. Then `remove` the record. A missing file is success. A path that escapes the folder is left on disk and reported.
- Riverpod: `installStoreProvider`, `destinationsProvider`. No download loop, no new routes, no edits to the game page.
- Widget-free unit tests for save/reload, per-system override, and uninstall path checks.
- Desktop default is the OS app-support folder (`~/Library/Application Support/retro_steam`, XDG, or `%APPDATA%`). Android and iOS pass their app-support directory through `installDirectoryProvider` when the queue is wired. No `path_provider` until then.

### T19 — Download queue ✅ (after T17, T18)
**Owns:** `apps/client/lib/src/install/download_queue.dart`, `apps/client/test/install/download_queue_test.dart`.
- One job per game. Pause, resume, and cancel. Resume sends `Range: bytes=<received>-` and appends. On success, mark the file complete and the game `installed` when every file is complete.
- Writes `<folder>/<systemId>/<GameFile.path>`. Creates parent directories. Refuses a path that escapes the folder.
- Queue survives a restart by reloading T18 records in `queued` or `downloading` (those resume as paused until the user resumes).
- Hidden when `canInstallGames` is false. No Downloads page in this task.

### T20 — Downloads page ✅ (after T19)
**Owns:** `apps/client/lib/src/downloads/`, the Downloads nav item, the Install button on the game page, and their tests.
- Shell nav gains Downloads when installs are supported. The page lists jobs with progress, pause, resume, and remove. Installed games can be uninstalled.
- Game page Install starts a job. It stays disabled until a destination exists, with a line that tells the user to pick a folder. Picking a folder reuses the setup folder browser.
- Focusable. No hardcoded colors or sizes. Feature code imports `rs_ui`, not `rs_ui_steam`.

---

## Where we are

M1, M2, and M3 are done (T1–T20). A new server can be set up from the client, scanned, scraped, and browsed with real artwork. A desktop client can pick an install folder, download a game with pause and resume, and uninstall the local files. Web can browse and administer, and does not install.

`dart tool/check.dart` passed after M3.

## M4 — Play

The user's machine already has emulators. The client finds them, the user picks one for a system or for a single game, and Play starts the installed ROM. Command lines and detection paths live in a manifest (data), not in a code switch. This milestone does not download emulator binaries and does not fetch BIOS.

Web has no Play button (`ClientCapabilities.canLaunchGames` is already false). Android and iOS keep the choice in the store, but detection and process launch in this milestone are desktop only (macOS, Windows, Linux).

```
Wave 1:  T21 emulator manifest + detection ─┐  T22 launch options store ─┐
Wave 2:                                    └── T23 launch process (T21, T22)
Wave 3:                                       T24 Play button + picker (T23)
```

### T21 — Emulator manifest and detection ✅
**Owns:** `apps/client/lib/src/launch/emulator_manifest.dart`, `apps/client/lib/src/launch/emulator_manifest_data.dart`, `apps/client/lib/src/launch/emulator_detector.dart`, `apps/client/lib/src/launch/emulator_probe.dart`, `apps/client/lib/src/launch/emulator_probe_io.dart`, `apps/client/lib/src/launch/emulator_probe_stub.dart`, `apps/client/test/launch/emulator_detector_test.dart`. Do not edit `pubspec.yaml`.
- The manifest is a JSON document stored as a string in `emulator_manifest_data.dart` and parsed by `EmulatorManifest.parse`. Detection paths, core→system rows, and argument templates live only there.
- One RetroArch entry (`id: retroarch`, `kind: retroarch`) plus standalone entries for Snes9x (`snes`), mGBA (`gb`, `gbc`, `gba`), DuckStation (`psx`), PCSX2 (`ps2`), Dolphin (`gc`, `wii`), PPSSPP (`psp`), melonDS (`nds`), Flycast (`dreamcast`), Azahar (`n3ds`), and RPCS3 (`ps3`). System ids must exist on `GameSystems`.
- Per platform `macos`, `windows`, and `linux`: executable paths (`~` is the probe home), RetroArch cores directories and core extension (`.dylib` / `.dll` / `.so`), and an args template. RetroArch args are `["-L", "{core}", "{rom}"]`. Standalone args are `["{rom}"]`. A macOS `.app` counts as found when the bundle directory exists; the executable reported is `Contents/MacOS/<bundle name>` when that file exists, otherwise the `.app` path.
- RetroArch cores: list files in the cores directories. A file whose name starts with a manifest `match` (for example `snes9x_libretro`) and ends with the platform extension is a detected core for those systems. Cover the `GameSystems` ids that have a widely shipped core (at least nes, snes, n64, gb, gbc, gba, nds, megadrive, genesis, psx, ps2, gc, wii, psp, dreamcast, fbneo, mame, arcade). Other core files are ignored.
- `EmulatorProbe` is synchronous and injected: `home`, `exists(path)`, `listFiles(directory)` (names only; empty when missing), `findOnPath(name)`. The IO probe uses `dart:io` and `PATH`. No shell. The stub throws if called. Conditional import so web still builds.
- `EmulatorDetector.detect(platform)` returns installed emulators only. Android, iOS, and web return an empty list. `DetectedEmulator`: `id`, `name`, `kind`, `executable`, `args`, `systems`, and `cores` (`path`, `match`, `systems`). Standalone `systems` come from the entry. RetroArch `systems` are the union of detected cores. RetroArch with no matching cores is still returned, with empty `cores`.
- Riverpod in the detector file: `emulatorManifestProvider`, `emulatorProbeProvider`, `detectedEmulatorsProvider` (empty when `canLaunchGames` is false). No process spawn, no UI, no edits under `install/` or `game/`.
- Tests use a fake probe and a temp-free fixture: RetroArch present with two cores, one standalone present, one missing, a core that is not in the map ignored, `~` expanded.

### T22 — Launch options store ✅ (parallel with T21)
**Owns:** `apps/client/lib/src/launch/launch_models.dart`, `apps/client/lib/src/launch/launch_store.dart`, `apps/client/lib/src/launch/launch_store_io.dart`, `apps/client/lib/src/launch/launch_store_stub.dart`, `apps/client/test/launch/launch_store_test.dart`.
- Device-local. Not the server API. One JSON file named `launch.json`, atomic replace, same style as `InstallStore`. Inject the directory so tests use a temp dir. No new dependency. Conditional import; the stub throws if called.
- Do not edit anything under `install/`. `launchStoreProvider` may watch `installDirectoryProvider` for its directory. Tests override the provider with a temp directory.
- A choice is `emulatorId` plus optional `corePath` and optional `customCommand`. `emulatorId` `custom` requires a non-empty `customCommand`. Any other id requires a non-empty `emulatorId`.
- One choice per system id. One optional choice per game, keyed by `serverId` + `gameId`. `resolve(systemId, serverId, gameId)` returns the game choice, otherwise the system choice, otherwise null. `put` replaces. `remove` drops that key. Missing is success.
- Riverpod: `launchStoreProvider`, `launchOptionsProvider` (`AsyncNotifier` with set/clear for system and game). No detection, no process, no UI, no game page.
- Widget-free tests: save/reload, game choice beats system choice, clear game falls back, `custom` without a command is rejected.

### T23 — Launch the installed ROM ✅ (after T21, T22)
**Owns:** `apps/client/lib/src/launch/game_launcher.dart`, `apps/client/lib/src/launch/game_launcher_io.dart`, `apps/client/lib/src/launch/game_launcher_stub.dart`, `apps/client/test/launch/game_launcher_test.dart`.
- Call T21 and T22. Do not edit their files. Call `resolveInstallFile` from the install store; do not edit `install/`.
- The file to open is the first `.m3u`, else `.cue`, else `.gdi`, else `Game.files.first`, resolved under `folderFor(systemId)`. A path that escapes the folder is refused and nothing is started.
- The game's install record must be `installed`. No folder, or not installed: return a failed result, do not start a process.
- Argument list: the detected executable plus its args template, with `{rom}` and `{core}` replaced. A custom command is split on whitespace with double quotes, `{rom}` replaced, and the rom path appended when `{rom}` was absent. RetroArch without a `corePath` fails. Unknown `{token}` fails.
- `Process.start` and do not wait. Inject a starter so tests never spawn a real emulator. The stub throws. Desktop only; android and ios return unsupported.
- No UI. Do not change the macOS sandbox or entitlements. If a launch would need a new entitlement, list it under Requests.

### T24 — Play button and emulator picker ✅ (after T23)
**Owns:** the install row on `apps/client/lib/src/game/game_page.dart`, `apps/client/lib/src/launch/launch_picker.dart`, and their tests. Do not edit T21–T23 files except to call them.
- When the game is installed and `canLaunchGames` is true, show Play as a primary `RsButton` beside Uninstall. Web never shows it.
- With no resolved choice, Play opens the picker instead of starting. The picker lists detected emulators whose `systems` contain this game's system, and for RetroArch each detected core for that system. A custom command field is always there. "Use for this system" writes a system choice. "Only this game" writes a game choice. Both close the dialog.
- With a choice, Play calls the launcher. A failed result is a short message on the page, not a new dialog system.
- Focusable. `RsDialog`, `RsListRow`, `RsTextField`, `RsButton`. No hardcoded colors or sizes. Feature code imports `rs_ui`, not `rs_ui_steam`.

---

## Where we are

M1–M4 are done (T1–T24). A desktop client can detect RetroArch and standalone emulators, remember a choice per system or per game, and start an installed ROM from the game page. Web does not show Play. Android and iOS keep the choice but do not start a process. `bash tool/macos_dmg.sh` writes `dist/RetroSteam-macos.dmg` (unsigned, client only).

`dart tool/check.dart` passed after M4. macOS Play can start other programs: T53 removed the App Sandbox.

The disk image now contains `Contents/MacOS/rs_server` and `Contents/lib/libsqlite3.dylib`. Opening the app starts that server when localhost is quiet. `tool/macos_dmg.sh` ad-hoc re-signs the app after those files are copied, and `codesign --verify` passed on the image. Still open on T54: a Quit Server menu item. Quitting the window already leaves the server running.

## Decisions

- **Desktop macOS drops the App Sandbox.** Bookmarks would cover a picked download folder and would still leave Play and "start the bundled server" broken. T53 removes the sandbox entitlement. There is no bookmark task.
- **One app means the client starts a server that lives inside the app.** A second copy is not started when port 47320 is already open. Quitting the window leaves that server running. A menu item stops it.
- **Adding a game is one game, not a library import.** A dropped folder that the scanner would split into two games is rejected. ScreenScraper runs once to suggest a title; the admin's saved title is what gets stored.
- **System tabs shipped in M1.** M7 search is the remaining browse gap. Extra filters, and the Material, Cupertino, and Fluent component sets, are Later.

## Now

M5 wave 1 can run as four agents at once: **T25, T26, T27, T30**. They do not share files.

These touch other files and can run beside that wave: **T34** (scraper screen), **T53** (sandbox), **T58** (phone install folder), **T59** (per-system folder).

T35, T36, T37, T41, T42, T44, and T46 edit `rs_core` and `RsApiClient`, same as T25 and T30. They wait until **T33**.

---

## M5 — Multi-device

A second device on the LAN gets a device token, then logs in with the account it already has. Joining and logging in stay two steps. The login page, `POST /devices/local`, `PairingPayload`, and `DeviceRepo.revoke` already exist. This milestone does not add password change, device rename, or remote access.

```
Wave 1:  T25 pairing API | T26 mDNS advertise | T27 mDNS browse | T30 users API
Wave 2:  T28 show QR (T25) | T29 join (T25, T27) | T31 devices screen (T25) | T32 users screen (T30)
Wave 3:  T33 integration (product owner)
```

### T25 — Pairing tokens and the device list ⬜
**Owns:** new DTOs under `packages/rs_core/lib/src/auth/`, route constants in `api_routes.dart`, the new `RsApiClient` methods, the server handlers, `apps/server/test/devices/`. No Flutter UI. No mDNS. Do not edit `docs/`.
- `POST /devices/pairing` (admin session) → `PairingOffer { token, expiresAt, serverId, hosts, port }`. Token is 32 random bytes, base64url, stored as SHA-256. Single use. Expires 5 minutes after creation. Creating an offer retires any offer that has not been used. `hosts` is the non-loopback addresses the server is listening on, skipping link-local. Empty list → `409 conflict` (bound to loopback only; nothing to pair). The QR string is the existing `PairingPayload` URI. This task does not draw it.
- `POST /devices/pair` takes no device header and no session. Body `PairDeviceRequest { token, deviceName, platform }` → `DeviceJoinResult` (`201`) via `DeviceRepo.create`. Unknown token → `401 invalid_credentials`. Expired or already used → `410` with `ApiErrorCodes.expired` (`expired`). Same rate limit as login. The offer is spent only after the device row is stored.
- `GET /devices` (admin) → `List<Device>`. `Device { id, name, platform, createdAt, lastSeenAt, revoked }`. Include revoked rows. Never return a token or a hash.
- `DELETE /devices/{id}` (admin) → `204`, using `DeviceRepo.revoke` so that device's sessions die. Unknown id → `404`. Revoking the calling device is allowed.
- `RsApiClient`: `createPairingOffer()`, `pairDevice(...)`, `devices()`, `revokeDevice(id)`.
- Tests over HTTP: pair once, second redeem fails, expired fails, list, revoke makes `GET /auth/me` with that device token return `401`.

### T26 — Advertise the server on the LAN ⬜
**Owns:** `apps/server/lib/src/discovery/`, `apps/server/test/discovery/`. No client. No pairing routes.
- When the server is configured and not bound to loopback only, advertise `Discovery.serviceType` (`_retrosteam._tcp`) on the listen port.
- TXT: `id` (server id) and `name` (server name). No token.
- Stop advertising on shutdown. Loopback-only bind: do not advertise.
- Call an advertiser interface. Tests use a fake and assert start, stop, and the TXT map. The suite must pass with no network.

### T27 — Browse for servers ⬜
**Owns:** `apps/client/lib/src/discovery/`, `apps/client/test/discovery/`. No connect-page edits. No server edits.
- `discoveredServersProvider` → `List<DiscoveredServer> { serverId, name, host, port }` from `Discovery.serviceType`. Drop a record with no host or port.
- The browser is injected. Tests: one service appears, one without a port is dropped, cancel stops the browse. No network.
- Web: the provider is an empty list. No error page.

### T28 — Admin shows a pairing QR ⬜ (after T25)
**Owns:** `apps/client/lib/src/devices/pairing_page.dart`, its route, the nav entry, its tests. No scanner. No user list.
- Admin only. A regular user does not get the nav entry (`User.role`).
- Show a QR of `PairingPayload(...).toUri()`, the first `host:port` as text, the time left, and Refresh. Refresh requests a new offer; the old code is dead.
- `409`: say the server is only listening on this computer. Do not draw a QR.
- A QR library may be added to the client `pubspec.yaml`. Focusable. Widget test with a fake client: the offer is shown, Refresh asks again.

### T29 — Join from another device ⬜ (after T25, T27)
**Owns:** the connect / join flow under `apps/client/lib/src/connection/`, a `canScanQr` flag on `ClientCapabilities` (true for android and ios, false otherwise), and tests. No admin QR page.
- Replace the "pairing arrives in a later version" branch in `connection_provider.dart`.
- With no device token, the connect page offers:
  - rows from `discoveredServersProvider` (activating a row sets that address)
  - a host and port field (default port `Discovery.defaultPort`)
  - a pairing-link field. `PairingPayload.tryParse`. Try `hosts` in order. The first host whose `GET /server` returns the same `serverId` is paired with `pairDevice`. Store the device token, then the existing login page.
- Camera scan only when `canScanQr` is true. Desktop and web paste the link.
- A bad or spent token shows the API message and stays on the page.
- Loopback `POST /devices/local` stays as it is.
- Widget tests with fakes: a pasted link joins, an unknown token shows the error, a discovered row sets the address.

### T30 — Users API ⬜
**Owns:** `CreateUserRequest` in `rs_core`, `RsApiClient` user methods, server user routes, `apps/server/test/users/`. No UI.
- `GET /users` (admin) → `List<User>`. No password hash.
- `POST /users` (admin) body `CreateUserRequest { username, password }` → `User` (`201`). Role is always `user`. Password ≥ 8, otherwise `400`. Username taken (case-insensitive, already how `UserRepo` works) → `409 conflict`. This route cannot create an admin.
- `DELETE /users/{id}` (admin) → `204`. The admin id → `409` and the row stays (`UserRepo.delete` already refuses). Unknown → `404`. That user's sessions go with the row.
- No password change and no rename.
- Tests: create, duplicate, short password, delete a user, delete the admin fails, a regular session gets `403`.

### T31 — Devices screen ⬜ (after T25)
**Owns:** `apps/client/lib/src/devices/devices_page.dart`, its route, its tests. The pairing page stays T28; this page may navigate there and does not draw a QR. No user list.
- Admin only.
- List name, platform, and last seen. A revoked row is labeled revoked and has no Revoke action.
- Revoke confirms with `RsDialog`, then `revokeDevice`. Revoking this device ends on the existing unauthorized logout.
- Focusable. Widget test: a fake list, confirm, revoke called.

### T32 — Users screen ⬜ (after T30)
**Owns:** `apps/client/lib/src/users/`, its route, its tests. No device list.
- Admin only. Nav item is hidden for `UserRole.user`.
- List username and role. Create asks for username, password, and confirm (password ≥ 8, confirm matches) and posts on submit. Delete confirms. The admin row has no delete.
- Focusable. Widget test: create calls the client, the admin row has no delete.

### T33 — M5 integration ⬜ (product owner, after T25–T32)
- `dart tool/check.dart` green. Copy the T25 and T30 routes into `docs/api-contract.md`.
- Walk a second client: paste a pairing link, log in as admin, revoke a device, create a user, log in as that user, confirm the admin nav is absent.

---

## M6 — Admin library

The first slice is credentials, add, edit, and delete. An admin can put one game into an existing root and correct its title. Artwork overrides, moving the data folder, and reopening setup are in this milestone and are not part of that slice.

```
Wave 1:  T34 scraper screen (API already exists; can start during M5)
Wave 2:  T35 delete API ─┐  T36 metadata API ─┐  T37 add-game API ─┐     (after T33)
Wave 3:                  ├── T38 delete button │                    ├── T40 add-game screen
                         └── T39 edit screen ──┘
Wave 4:  T41 upload override API ─┐  T42 artwork candidates API ─┐
Wave 5:                           └── T43 artwork picker (T41, T42)
Wave 6:  T44 migrate data dir API ─┐  T46 roots API ─┐
Wave 7:                            ├── T45 migration screen (T44)
                                   └── T47 reopen setup (T44, T46)
```

### T34 — Scraper credentials screen ⬜
**Owns:** the client scraper settings page and its tests. `GET`/`PUT /settings/scrapers` already exist. No new routes.
- Admin only.
- Two blocks: ScreenScraper (dev id, dev password, username, password) and SteamGridDB (API key). Save sends a `PUT` of the fields the admin filled. A field left blank is omitted, so the stored secret stays. A Clear control sends `""` for that provider and clears it.
- The page shows the booleans from `GET` ("Saved" / "Not set"). It does not display stored secrets.
- Focusable. Widget test with a fake client: save sends only the filled provider, Clear sends an empty string.

### T35 — Delete a game ⬜ (after T33)
**Owns:** `DELETE /library/games/{id}`, `RsApiClient.deleteGame`, server tests. No game page.
- Admin. `204` when the catalog row is gone. Unknown id → `404`. Regular user → `403`.
- Online writable root: delete only that game's `game_files`, each path resolved through `PathGuard`, then the catalog row and its artwork rows. A path that escapes the root is left on disk.
- Read-only root: `409 conflict`. Row kept. No file deleted.
- Offline root: delete the catalog row only, still `204`. The files are not on this machine.
- Tests in a temp root: the game's files are gone, a sibling ROM remains, a read-only root is rejected.

### T36 — Edit metadata ⬜ (after T33)
**Owns:** `PATCH /library/games/{id}`, `PatchGameRequest`, `RsApiClient.patchGame`, server tests. No page. Do not change `ScrapeService`.
- Admin. Optional `title`, `description`, `developer`, `publisher`, `releaseYear`. Omitted means leave the stored value. An empty title → `400`. Returns the `Game`.
- Does not change files, hashes, or artwork. There is no "clear this field" in this task. Scrape already fills only nulls, so a value saved here stays.
- Tests: title changes, an omitted field stays, empty title is rejected, a regular user gets `403`.

### T37 — Add one game ⬜ (after T33)
**Owns:** the import routes, their DTOs, `RsApiClient` methods, server tests. No Flutter. No zip or 7z.
- Admin. The target is an existing root. Read-only or offline → `409` before any byte is kept.
- `POST /library/games/imports` multipart: `rootId`, `systemId`, optional `folderName`, and one or more file parts. Each filename is a basename. A separator, `..`, or a Windows reserved name → `400 path_invalid`, and any temp files already written are deleted.
- Stream each part into that root's `tmp/<importId>/<systemId>/`. Check free space first. Reject a part over 8 GiB or an import over 16 GiB. The extension must be one `GameSystems` allows for `systemId`.
- Run the existing scanner on that temp root. It must produce exactly one game (a `.cue`/`.bin`, `.gdi`, or `.m3u` unit counts as one). Zero games or more than one → `409`, delete the temp import.
- Response `GameImport { importId, suggestedTitle, fileNames, totalBytes, expiresAt }`. Suggested title, in order: one `ScreenScraperClient` lookup by hash when credentials exist and the lookup hits; else the catalog title for that hash; else `folderName`; else the scanner's name for the primary file. A lookup miss or error falls through. No SteamGridDB call on this route.
- `POST /library/games/imports/{id}/commit` body `{ title, description?, developer?, publisher?, releaseYear? }`. `title` is required and non-empty. Move the temp files into `<root>/<systemId>/`, upsert through `GameRepo` with the scanner's identity, write the metadata from the body, delete the import record. `201` and the `Game`. Then `ScrapeService.start()` so artwork still fills in. A second commit → `404`.
- `DELETE /library/games/imports/{id}` deletes the temp files. An import older than 30 minutes is deleted on the next prepare.
- Tests: cue+bin is one import, a bad extension is rejected, two games in one drop are rejected, commit writes only under the system folder, the committed title is the body title, a read-only root is rejected.

### T38 — Delete on the game page ⬜ (after T35)
**Owns:** the delete control on `game_page.dart` and its test. No server edits.
- Admin only. A regular user does not see it.
- Confirm with `RsDialog`, naming the game. `409` shows the API message and stays. Success leaves for the library.
- Focusable. No other change to the page.

### T39 — Edit metadata on the game page ⬜ (after T36)
**Owns:** the edit dialog and its test. No server edits. No file renaming.
- Admin only.
- Fields: title, description, developer, publisher, year, prefilled from `Game`. Empty title is blocked in the form. Save calls `patchGame` with those fields.
- Focusable. Widget test: the typed title is what the client sends.

### T40 — Add a game from the client ⬜ (after T37)
**Owns:** `apps/client/lib/src/library/add_game_page.dart`, the library entry point, tests. No server edits.
- Admin only.
- One flow: choose files, edit the suggestion, commit. Desktop can drop a folder (top-level files only, plus `folderName`) or pick files. Mobile and web use the file picker. Web is included; upload is an admin task.
- The root picker lists writable online roots. Then system, then the editable title and metadata from `GameImport`. Commit sends the edited title. Cancel deletes the import.
- A `409` (more than one game, read-only root) shows the API message. The client does not try to split a folder into games.
- Focusable. Widget test with a fake client: the chosen names are the import, and the edited title is the commit body.

### T41 — Upload or clear an artwork override ⬜ (after T33)
**Owns:** `PUT` and `DELETE /library/games/{id}/artwork/{kind}`, client methods, server tests. No candidate list. No picker UI.
- Admin. `kind` is an `ArtworkKind`.
- `PUT` with a raw image body: size-capped by the existing image pipeline, re-encoded, stored with `is_override = 1`. `204` or the updated `Game`. A scrape must still refuse to replace that row (already true; do not change that rule).
- `DELETE` removes that kind's override so a later scrape may fill it. The ROM stays. Missing row → `204`.
- Tests with a generated image: upload then delete, and a following scraped `putScraped` is allowed only after the delete.

### T42 — Artwork candidates ⬜ (after T33)
**Owns:** `GET /library/games/{id}/artwork/candidates` and `PUT` that selects one, client methods, server tests. No upload-from-disk (that is T41). No picker UI.
- Admin. Query `kind`. Response: up to 20 `{ source, remoteId, previewUrl }` from ScreenScraper and SteamGridDB using stored credentials. A provider with no credentials is skipped. Both missing → an empty list, `200`.
- `PUT /library/games/{id}/artwork/{kind}` JSON `{ remoteId }` downloads that image through the existing pipeline and stores it as an override.
- Tests use fake scraper clients. No live network.

### T43 — Artwork picker ⬜ (after T41, T42)
**Owns:** the game-page artwork controls and their tests. No server edits.
- Admin only. One dialog per `ArtworkKind`: candidates from T42, plus upload from T41, plus clear.
- Choosing a candidate or a file updates the hero or card after the library refresh. Clear calls DELETE.
- Focusable. Widget test with a fake client for select, upload, and clear.

### T44 — Move the data directory ⬜ (after T33)
**Owns:** the migration routes, a `migrationProgress` `ServerEvent`, client method, server tests. No wizard. ROM roots are not copied.
- Admin, and loopback only (same check as `POST /setup`). A remote client gets `403 loopback_only`.
- `POST /storage/migration` `{ destination, mode: copy | move }` → `202`. Progress on the existing WebSocket: `migrationProgress { phase, bytesDone, bytesTotal, error }`, throttled like scan progress.
- Copies or moves the database, `artwork/`, and `cache/`. The bootstrap config starts pointing at the new directory only after the copy has finished and the new database opens. A `move` deletes the old directory only after that swap.
- A destination that already has a data marker is adopted when the marker's server id matches. A different id → `409`, source left in place.
- `POST /storage/migration/cancel` before the config swap keeps the old directory as the live one. After the swap, cancel is `409`.
- Tests with temp dirs and a few small files. No UI.

### T45 — Migration screen ⬜ (after T44)
**Owns:** the client migration screen and its test. Shown only when `ServerConnection.isLocal` and the user is admin. No root editing.
- Picks a destination with the existing folder browser, chooses copy or move, confirms, and shows `RsProgressBar` from `migrationProgress`.
- Cancel calls the cancel route and returns to the library when the server accepts it.
- Widget test with a fake event stream.

### T46 — Add or remove a library root ⬜ (after T33)
**Owns:** `POST` and `DELETE /library/roots`, client methods, server tests. No wizard. Does not delete ROM files.
- Admin. `POST` body `{ path }` creates the marker, stores the root, and starts a scan. A read-only tree is allowed and saved as `readOnly` (browse and download already work). `permissionDenied` → `403` with the path-check payload the setup UI already understands.
- `DELETE /library/roots/{id}` removes that root's catalog rows and, when the disk is writable, the marker. ROM files stay. An offline root can be removed. Unknown id → `404`.
- Tests: add a temp tree, games show up after the scan, delete drops the rows and leaves the files.

### T47 — Reopen setup ⬜ (after T44, T46)
**Owns:** the client wizard that edits an already configured server, and its tests. No `POST /setup`. No new server routes.
- Admin, and only when `ServerConnection.isLocal`. A regular user and a remote client do not see the entry.
- Steps, on `RsWizardFrame`: data folder (current path shown), library roots (current list, add and remove through T46), confirm (a list of what will change). The account step is absent.
- Cancel pops to the library and calls nothing that writes.
- A new data folder runs T45's migration and waits until it finishes. The old database and artwork are not deleted by this wizard (`move` is the admin's choice on that screen).
- Confirm applies root adds and removes, which scan on their own via T46.
- Widget test: cancel sends no mutation; confirm calls the root and migration clients with the edited values.

---

## M7 — Polish

Search, theme, gamepad, keyboard, and accessibility are five tasks. The system tabs from M1 stay the filter. New component sets are Later.

```
Wave 1:  T48 search  |  T49 theme  |  T50 gamepad  |  T52 accessibility
Wave 2:  T51 on-screen keyboard (T50)
```

### T48 — Search ⬜
**Owns:** the library search field and its test. `GET /library/games?q=` already exists. No new endpoint.
- A text field on the library page. Debounce, then pass `q`. Empty clears it. The system tab and the query both apply.
- Typing must keep working (no global letter shortcut). Focusable.
- Widget test: a query is passed to the games provider, clearing it fetches the unfiltered page.

### T49 — Theme settings ⬜
**Owns:** `theme_settings_provider.dart` (drop the persist TODO), a theme settings page, its test. `RsThemeSettings` already has `mode`, `accent`, and JSON.
- Save the settings locally, next to the other client JSON. Relaunch reads them back.
- Page: dark / light / system, and the accent. Follow the theme tokens. Focusable.
- Widget-free test for save and reload, plus a widget test that changing mode updates `themeSettingsProvider`.

### T50 — Desktop gamepad ⬜
**Owns:** the gamepad plugin wiring under `apps/client/lib/src/input/`, and tests. No new intent and no second shortcut map.
- On macOS, Windows, and Linux, a connected gamepad produces the intents `RsInputScope` already handles: A activate, B back, Start menu, Select options, LB/RB tab, d-pad and stick as directional focus.
- Mobile and web stay on the keys the platform already delivers.
- Tests feed a fake gamepad event and expect the existing intent, not a new key map.

### T51 — On-screen keyboard ⬜ (after T50)
**Owns:** `apps/client/lib/src/input/onscreen_keyboard.dart` and its test. No change to `RsTextField`'s contract beyond what the keyboard needs to type into the focused field.
- Shown when a text field is focused and the last directional input was the gamepad from T50. A physical key hides it.
- It inserts characters into the focused field. A done key closes it. Focusable, and it does not trap B (B still goes back).
- Widget test: gamepad focus on a field shows it, a letter key hides it, done closes it.

### T52 — Accessibility pass ⬜
**Owns:** semantics and motion on the home, library, and game pages, the existing buttons those pages use, and tests. No startup animation and no sound.
- Screen-reader names on game cards, shelves, and the primary buttons (Play, Install, and the admin actions once they exist).
- Text scale follows the OS. Focus ring stays visible in light and dark, using the theme tokens.
- Reduced motion: the hero cross-fade is a cut. No second widget tree.
- Widget test: a card exposes its title, and the reduced-motion flag skips the fade.

---

## M8 — One app

macOS first, because that is the broken disk image. Windows and Linux copy T54 after it works. The server stays a headless process either way.

```
Wave 1:  T53 drop the macOS sandbox          (can start during M5)
Wave 2:  T54 macOS app starts the bundled server (T53)
Wave 3:  T55 macOS login item (T54)  |  T56 Windows (T54)  |  T57 Linux (T54)
```

### T53 — Drop the macOS App Sandbox ✅
**Owns:** `apps/client/macos/Runner/DebugProfile.entitlements`, `Release.entitlements`, and a note in the client README only if one already mentions the sandbox. No server binary. No DMG script change beyond what the entitlement edit implies.
- Remove `com.apple.security.app-sandbox`. Keep `com.apple.security.network.client`.
- After this, `Process.start` for Play and writes to a folder the user picked are allowed. Do not add security-scoped bookmarks.
- Verify with `flutter build macos` (or `flutter run -d macos` if a display is available) that the app still builds.

### T54 — macOS app starts the bundled server 🟦 (after T53)
**Owns:** `tool/macos_dmg.sh`, the client startup path that launches the server, a Quit Server menu item, and tests that do not require a GUI. This is the "DMG shows Server not found" fix.
- The script builds the server binary and places it inside `retro_steam.app`. The DMG is still unsigned, drag-to-Applications.
- On startup, if `http://127.0.0.1:47320/api/v1/server` does not answer, start that binary and wait until it does (a bounded timeout, then the existing unreachable page). If it already answers, do not start a second process.
- Quitting the window leaves the server running. A menu item stops the server this app started.
- A test can assert the launch decision with a fake process starter: quiet port starts one process, a live port starts none.

### T55 — Start at login on macOS ⬜ (after T54)
**Owns:** the login-item setting and the macOS registration. No Windows or Linux.
- One client setting, "Start Retro Steam at login", default off.
- On registers this app as a login item. Off removes it. Launching the app is enough: T54 starts the server.
- Test the on/off decision with a fake registrar. Do not require a real login session in CI.

### T56 — Windows one app ⬜ (after T54)
**Owns:** the Windows packaging script and the same startup behavior as T54. No login item.
- The Windows build contains the server binary. Quiet port starts it, a live port does not, quitting the window leaves it running, a menu item stops it.
- Reuse the T54 starter behind a per-platform spawn. Do not copy a second policy.

### T57 — Linux one app ⬜ (after T54)
**Owns:** the Linux packaging script and the same startup behavior as T54. No login item.
- Same rules as T56.

---

## Open gaps

Not a milestone. Safe to pick up without waiting for M5, except where a task says otherwise.

### T58 — Phone and tablet install folder ⬜
**Owns:** `installDirectoryProvider` for android and ios, and a test. Desktop paths stay as they are.
- Add `path_provider` (or the existing equivalent) and pass the app-support directory in. The web stub still throws if called.
- Test that android and ios resolve a non-null directory when the provider is given a fake path.

### T59 — Per-system install folder ⬜
**Owns:** the Downloads page control and its test. `InstallStore.folderFor` already honors an override. No store rewrite.
- The page keeps the global folder. It adds a row per system that has an installed game or an override: the current folder, and a picker that calls the existing per-system setter. Clearing the row returns that system to the global folder.
- Focusable. Widget test: setting `snes` does not change the global folder.

---

## Later — do not build

Designed only. No task number until a milestone picks one up.

- **Remote access** over DNS. Needs TLS and a stronger auth story. LAN pairing must not assume a trusted network forever, and it also must not grow a certificate stack now.
- **More than one server** at a time. The client keeps a server id so this can be added. One active server for now.
- **Save sync**, and cloud backup of server saves.
- **Managed emulator downloads**, and whether those emulators may fetch BIOS from the server **(TBD)**.
- **Material, Cupertino, and Fluent component sets.** Each is a package that implements `RsComponentSet`. Feature code already depends on `rs_ui` only.
- **UI sounds.** Bundled cues for focus move, activate, back, and the home hero changing. A client setting turns them off. System mute is respected. No music.
- **Startup animation.** A short intro before connect or welcome. A or Esc skips it. A returning session is not held on it. Reduced motion shows a still frame.
- **HTTP suffix ranges** (`bytes=-N`). Resume already sends `bytes=<received>-`. Suffix ranges stay `416`.
- **Zip and 7z ingest.** When it exists, guard against zip-slip and decompression bombs.
- **Port and bind address** edited from the client.
- **Password change and device rename.**
- **Filters beyond the system tabs and the search box.** Year, player count, and installed-only wait until search has been used.
