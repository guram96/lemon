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

### The first-run experience (Milestone 1 target)

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
| **M1** | First run → Home | Setup wizard, background login, scan with live progress, Big Picture home/library/game page with generated art |
| M2 | Art & metadata | ScreenScraper + SteamGridDB scraping, artwork pipeline & serving, real hero/logo/capsules, file watching |
| M3 | Downloads | Install destinations, download queue (pause/resume, range requests), installed state, uninstall, Downloads page |
| M4 | Play | Emulator detection (RetroArch + cores, standalone), launch options per game/system, managed emulator manifest |
| M5 | Multi-device | mDNS discovery, QR pairing, manual address, login screen, user & device admin |
| M6 | Admin | ROM upload, game delete, metadata edit, artwork overrides, storage migration, server settings |
| M7 | Polish | Search, filters, theme settings, desktop gamepad, on-screen keyboard, more component sets |

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

## Backlog (M3+, refined when M2 lands)

- M3: client storage service · install destinations (global + per system) · download queue w/ HTTP range resume · `GET /games/{id}/download` · installed-state DB on client · Downloads page · uninstall.
- M4: emulator manifest format · RetroArch + core detection per OS · launch options UI · process launch · managed emulator installs.
- M5: mDNS advertise/browse · pairing tokens + QR (show/scan) · manual address · users admin · devices admin.
- M6: upload (streamed, validated, atomic) · delete via catalog · metadata edit · artwork override browser · data-dir migration with progress · server settings UI.
- M7: search · theme settings · desktop gamepad plugin · on-screen keyboard · Material/Cupertino/Fluent sets.
