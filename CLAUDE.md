# Retro Steam

A self-hosted retro game library: **EmulationStation meets Steam**.

- A **server** runs on a desktop machine (macOS, Windows, or Linux). It points at a ROM collection that uses EmulationStation folder names, scans it, processes artwork and metadata, and serves the library over the local network.
- A **client** works like the Steam client. It connects to a server, browses the library, **downloads games to the device**, and launches them with an emulator, which it detects automatically or which the user configures.
- Games can be **added and deleted on both sides**. The admin manages the server library, including uploading ROMs from a client. Any user can install and uninstall games on their own device.
- The client UI is a **one-to-one recreation of Steam Big Picture mode**, made for controller, keyboard, and touch. The look can be swapped through UI component sets.

> Status: M1–M3 are built (first run, artwork and metadata, downloads). Next is M4, launching a game. The board is `tasks.md`. Items marked **(TBD)** wait on decisions. Items marked **(Later)** are planned but out of scope for now. Design for them, but don't build them yet.

---

## Core principles

1. **Portable and simple.** Prefer the simplest design that works. Avoid heavy infrastructure. The server is a single binary plus a data folder.
2. **Decoupled server and client.** The server is a standalone, headless process with no Flutter dependency. The client knows the server only through its public network API.
3. **Contract first.** Shared models and the API contract live in `rs_core`. Both sides depend on it. Neither depends on the other.
4. **Modular client.** Feature screens build against an abstract UI component layer, never against Material, Cupertino, or Fluent widgets directly. The whole look and feel can be swapped (see the UI architecture section).
5. **Portable data.** Moving drives between machines, or splitting data across drives (data on an SSD, ROMs on an HDD), must just work.
6. **EmulationStation folder names.** System folders use EmulationStation names (`snes`, `psx`, `ps3`, …), so an existing ROM collection can be pointed at directly. This is naming compatibility only. Retro Steam never reads or writes EmulationStation files (`gamelist.xml`, its media folders), and the two apps are not meant to manage the same system at the same time.

---

## Repository layout

A Dart **pub workspace**: one root `pubspec.yaml` lists the members, and they share one lockfile and `.dart_tool`.

```
retro_steam/
├── pubspec.yaml           # workspace root (members listed under `workspace:`)
├── analysis_options.yaml  # shared lints for every member (strict casts/inference/raw types)
├── tool/check.dart        # all quality gates: codegen, format, analyze, tests
├── apps/
│   ├── client/            # rs_client: Flutter app, all platforms
│   └── server/            # rs_server: pure Dart, headless, bin/rs_server.dart
└── packages/
    ├── rs_core/           # shared models + API contract (freezed/json_serializable), pure Dart
    ├── rs_api_client/     # typed HTTP client for the server API, pure Dart, web-safe
    ├── rs_theme/          # RsTokens ThemeExtension, RsThemeSettings, RsThemeBuilder
    ├── rs_ui/             # abstract components (RsButton, RsToggle, RsTile, …), RsFocusable, input intents
    └── rs_ui_steam/       # SteamComponentSet: the Big Picture look
```

Feature packages go in `packages/features/<name>/` (for example `rs_feature_library`) once a feature grows beyond a few files. Until then a feature can live in `apps/client/lib/src/<feature>/`. Every new member must be added to the root `pubspec.yaml` `workspace:` list and to `tool/check.dart`.

### Dependency rules

```
rs_core ◄── rs_api_client ◄──┐
   ▲                         │
   └──── rs_server           ├── rs_client (app)
rs_theme ◄── rs_ui_steam ◄───┤
rs_ui    ◄───────┘ ◄─────────┘
```

- `rs_core`, `rs_api_client` and `rs_server` are pure Dart. They never import Flutter.
- `rs_core` and `rs_api_client` must stay **web-safe**: no `dart:io`.
- Feature code depends on `rs_ui`, never on a concrete component set such as `rs_ui_steam`.
- `rs_ui` doesn't depend on `rs_theme`. Component sets read the theme themselves.

### Commands

```sh
flutter pub get                      # at repo root, resolves the whole workspace
dart tool/check.dart                 # codegen + format check + analyze + all tests
dart tool/check.dart --fix           # same, but applies formatting
cd packages/rs_core && dart run build_runner build -d   # regenerate models after editing them
cd apps/server && dart run bin/rs_server.dart -v        # run the server (--config, --port)
cd apps/client && flutter run -d macos                  # run the client
```

Generated files (`*.freezed.dart`, `*.g.dart`) are committed, so the apps build without running codegen.

---

## Server

### Stack
Pure Dart: `shelf` for HTTP, WebSocket for push events, SQLite for the catalog. Ships as one native executable for each desktop OS. It has **no UI of its own**. Everything is configured through the client's admin UI.

### Storage model (portable)
Server state is split into three independent locations, and each can live on any drive:

| Location | Contents | Configurable |
|---|---|---|
| **Bootstrap config** | A tiny file in the OS app-config directory. It only points to the data directory, plus the port and bind address. | Set during first-run setup |
| **Data directory** | SQLite database, processed artwork, caches, server settings | Initial setup + settings |
| **Library roots** | ROM folders (one or more), EmulationStation layout | Initial setup + settings |

- Every library root and the data directory get a **marker file** (for example `.retrosteam/root.json` with a UUID). Then, if a drive is moved to another machine or mounted at a different path, the server finds the root again by its UUID instead of its absolute path.
- ROM paths in the database are stored **relative to their library root** (root UUID + relative path), never as absolute paths.
- When the data directory location changes, the client prompts the admin to **migrate** the existing database and artwork (copy or move, with progress). The server can also adopt an existing data directory it finds at the new location.

### Filesystems
- Must work with **external drives and NTFS**, exFAT, FAT32, APFS, HFS+, and ext4.
- Handle **read-only mounts** gracefully. For example, macOS mounts NTFS read-only by default. On a read-only root, browsing and downloads still work, and the admin UI marks upload, delete, and scraping into that root as unavailable.
- Handle case-insensitive filesystems, Windows path rules (reserved names, path length), and drives that are unplugged or plugged back in. A missing root is shown as "offline" and is not deleted from the catalog.

### Library
- Folder layout and system IDs follow the EmulationStation naming scheme (`<root>/snes/`, `<root>/psx/`, `<root>/ps3/`, …), with the same file extensions for each system. **Naming only:** never read or write `gamelist.xml` or EmulationStation media folders.
- Identify ROMs by hash (CRC32, MD5, SHA1). Multi-file games (`.cue`/`.bin`, `.m3u`, multi-disc) are one game unit.
- Metadata and artwork come from online scraping and are stored in the data directory, never next to the ROMs:
  - **ScreenScraper:** identifies games by hash and provides metadata (title, description, developer, year) plus box art and screenshots.
  - **SteamGridDB:** provides Steam-style assets: hero, logo, capsule (grid), and icon.
  - **Per-game artwork override:** the admin can browse alternatives from both sources, or upload their own image, for each artwork kind. Overrides are remembered and are never replaced by a rescan.
- Watch the roots for changes. Push scan progress and library changes to clients over WebSocket.

### Serving
- Catalog API, artwork (resized variants), and ROM downloads. Downloads are resumable through HTTP range requests, and a multi-file game downloads as one unit.
- Admin endpoints: upload ROMs, delete games, edit metadata, and change library, storage, and server settings.

### Networking and discovery
- **LAN only for now.** Reachable by IP address or local DNS name on a configurable port. **(Later)** Remote access over DNS, which will need TLS and stronger authentication. Don't design anything that blocks this.
- Advertises itself through mDNS/Bonjour (`_retrosteam._tcp`).
- **Same machine:** the client probes `localhost` at startup and connects automatically.
- **Other devices:** pair by scanning a **QR code** that the client shows on the admin's device. The QR holds the server addresses, port, server ID, and a one-time pairing token. Manual IP or hostname entry is the fallback.
- After pairing, the device stores a token. The server keeps a list of paired devices that the admin can revoke.

### Devices vs. users
Two separate steps:
1. **Device joins the server.** It connects automatically on the same machine, and otherwise pairs by QR code or manual address. This only makes the server reachable from that device.
2. **User logs in** on a joined device, as the admin or a regular user. Any joined device can be used to log in as the admin.

### First-run setup
- The server starts in an *unconfigured* state. Because the server has no UI, setup is done through the client running **on the server machine**, which connects through `localhost`.
- The setup wizard creates **the admin account** (once, and only here), then picks the data directory and the library roots.
- After setup, the admin can log in from any joined client: desktop, Android, or web.

### Users and roles
- **Admin:** exactly one admin account, created during first-run setup, which can be signed in on several clients. The admin can do everything: library management, uploads and deletes, server settings, storage migration, and user and device management.
- **Regular user:** can browse the library and download games, and can uninstall games on their own device. No server-side changes.
- The admin sections of the client UI are only shown to the admin.
- Regular user accounts are **created by the admin** in the admin UI.

---

## Client

Runs on **every platform**: macOS, Windows, Linux, Android, and iOS, as the full client.

**Web** is a reduced client, like Steam on the web: browsing the library plus admin tasks (library management, uploads, settings, users). No downloads, installs, or launching. Features that are not available on web are left out using platform capability checks, not separate code paths in each screen.

### Library and downloads
- Browse: home, library, game detail, search, and filters by system.
- **Install destination:** the user sets where games are downloaded, globally and/or per system. This is usually the folder the user's emulator already reads from. The default layout is the EmulationStation layout (`<dest>/<system>/…`).
- Download queue with pause and resume, progress, and storage view. Uninstall removes the local files only.
- **Admin:** upload a ROM from the client to the server, delete games from the server, and edit metadata.

### Emulators and launching ("Proton for retro")
- **Default assumption:** the user's device already has emulators and BIOS files set up. The client only downloads ROMs into the right folders.
- **Launch options** for each game, with an override for each system:
  - Detect installed emulators automatically (for example RetroArch and its cores, and standalone emulators) and map them to systems.
  - The user can choose an emulator or core manually, or give a custom command line.
- **Optional managed emulators:** download and configure an emulator once when the first game for that system is installed, the way SteamOS installs Proton for you. Per-platform emulator definitions are kept as data (a manifest), not hardcoded.
- **BIOS:** not served by the server for now. The user provides BIOS files on the device. **(TBD)** Whether managed emulators should be able to fetch BIOS from the server.

### Saves
- **(Later)** Sync saves and save states to and from the server. **(Later)** Back up server saves to cloud storage (for example Google Drive). Keep save handling behind an interface so sync can be added later.

### Multiple servers
- **(Later)** Connecting to more than one server. For now the client connects to one active server at a time. Keep server identity in the data model so this is easy to add later.

---

## Client UI architecture

### Component sets (swappable look and feel)
- **Look:** a one-to-one copy of Steam Big Picture mode, with controller-first focus navigation, d-pad and keyboard focus handling, and on-screen button hints.
- `rs_ui` defines **abstract component contracts** (`RsButton`, `RsTile`, `RsCarousel`, `RsDialog`, `RsTextField`, `RsToggle`, `RsNavBar`, …) and a registry the app shell provides at the root.
- **Component sets** implement these contracts. Each set is its own package:
  - `rs_ui_steam`: the default, Big Picture.
  - Planned: Cupertino, Material, and Fluent (Windows-style) sets.
- The user picks the component set in the client settings. Feature code never imports a concrete set.

### Theming
- Use **standard Flutter theming**: `ThemeData`, `ColorScheme`, and `ThemeExtension`s for app-specific tokens (focus ring, hero gradients, button-hint colors, and so on).
- Dark mode by default, plus light mode. Colors, accent, and other theme options can be **configured in the client UI** and are saved locally.
- Component sets read from the theme. No hardcoded colors, sizes, or text styles in feature or component code.

### Input
- `RsFocusable` (in `rs_ui`) is the only focus and activation primitive. Every interactive part of every component set uses it, so d-pad, keyboard, mouse, and touch behave the same in every look. It scrolls itself into view when focused.
- `RsInputScope` maps keys and controller buttons to intents: A/Enter/Space → `ActivateIntent`, B/Esc/Backspace → `RsBackIntent`, Start → `RsMenuIntent`, Select → `RsOptionsIntent`, LB/RB/PageUp/PageDown → `RsTabIntent`. Arrow keys and the d-pad use Flutter's directional focus.
- Never bind single-letter keys globally, because they would swallow typing in text fields.
- **(Later)** Desktop gamepad support through a plugin that sends events to the same intents.

### State and navigation
- **Riverpod 3** (`flutter_riverpod`, plain `Notifier` and `Provider`, no code generation) for state and dependency injection.
- **go_router** for routing. The router is a provider (`routerProvider`). `RsBackIntent` pops the router globally.
- `MaterialApp.router` is used only as plumbing (theme, localizations, overlays). Visible widgets come from the component set.
- Platform differences go through `ClientCapabilities` (`clientCapabilitiesProvider`), never through direct `kIsWeb` or `Platform` checks in features.

---

## Security

The server writes to the user's disks and is reachable over the LAN (and later the internet).
Treat every request as untrusted, even on a home network.

### Filesystem safety (server)
- **Path traversal:** never build a filesystem path from client input directly. Resolve every
  path to (root UUID + relative path), normalize it, and check that the result stays inside its
  library root or data directory before reading or writing. Reject `..`, absolute paths,
  drive letters, symlinks that escape the root, and Windows reserved names.
- **Deletion only through the catalog:** only delete files that belong to a known catalog
  entry. Never delete a path that only the client provided.
- **Uploads:** stream them to a temp file in the target root, check size, extension (it must
  match the system), and hash, then move them into place atomically. Enforce a maximum upload
  size and check free disk space first. Never run or extract uploaded content in place.
- **Archive handling (later):** if the server ever unpacks zip or 7z files, guard against zip-slip
  and decompression bombs.
- The server runs as a normal user. It never needs root or admin rights.

### Authentication and authorization
- Joining a device and logging in a user are separate steps. Both are required for anything
  beyond `GET /server` (the public server info).
- **Pairing tokens:** single-use, short-lived (for example 5 minutes), random (≥128 bits),
  and only created by an admin session or by the local setup flow.
- **Device tokens:** random, stored hashed on the server, and revocable from the admin UI.
- **Passwords:** hashed with Argon2id (or scrypt/bcrypt), with a rate limit and lockout on
  failed logins.
- **First-run setup:** only accepted while the server is unconfigured, and only from
  the loopback interface (the client running on the server machine).

---

## Conventions

- **Adding a component:** add the abstract widget to `rs_ui` (it delegates to `RsComponents.of(context).<name>(context, this)`), add a method to `RsComponentSet`, implement it in every set, and add a widget test.
- **Adding an API endpoint:** add the route constant and DTOs to `rs_core`, add a handler in `apps/server/lib/src/routes/`, add the method to `RsApiClient`, and test both sides.
- The server returns errors as JSON `ApiError {code, message}`. The client turns them into `ApiException`.
- Test pure Dart code with `package:test` and widgets with `flutter_test`. Every package has tests, and `dart tool/check.dart` must pass.
- Feature packages depend on `rs_core`, `rs_api_client`, `rs_ui`, and `rs_theme`. They never depend on each other or on a concrete component set.
- Every interactive widget must be focusable and usable with a controller or d-pad.
- The server must never import Flutter.
- Never store absolute ROM paths on the server. Use root UUID + relative path.
- Keep things simple. Don't add infrastructure (extra services, brokers, ORMs) without a clear need.

## Platform notes

- **macOS client:** the app is sandboxed. It has the `network.client` entitlement. Writing downloads to folders the user picks will need security-scoped bookmarks, or the sandbox has to be dropped for the desktop build. Decide this when building downloads.
- **Bundle IDs** are still the scaffold's `com.example.retro_steam` / `com.example.retroSteam`. Change them before any release.
