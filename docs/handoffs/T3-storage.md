# T3 storage & security — handoff for T5

Barrels: `package:rs_server/src/{storage/storage,db/db,security/security,fs/fs}.dart`
(not exported from `lib/rs_server.dart`; T5 decides).

## storage/
- `MarkerStore.read/write(dir)`, `RootMarker {id, kind: MarkerKind.data|library, label, createdAt}`.
- `DataDir.openOrCreate(dir, {label})` (adopts an existing data marker; throws
  `StorageException` if dir is a library root), `DataDir.open(dir, {expectedId})`;
  `dbPath`, `artworkDir`, `cacheDir`, `tmpDir`, `adopted`, `id`.
- `LibraryRoots.register(path, {label}) → RootRegistration {id, label, path, status, markerWritten, adopted}`
  (throws `FsAccessException` / `StorageException`).
- `LibraryRoots.locate(id, lastPath, {label, searchDirs}) → RootLocation {status, path}`.
  Pass `DirectoryBrowser().volumeParents` as `searchDirs`. Call at startup.

## db/
- `RsDatabase.open(path)` / `.inMemory()`, `transaction(fn)`, `close()`.
- Repos: `SettingsRepo`, `UserRepo` (create throws `ConflictException`; `hasAdmin`, `byUsername`
  case-insensitive), `DeviceRepo` (`create({name, platform, tokenHash})`, `byTokenHash`, `touch`, `revoke`),
  `SessionRepo` (`create({userId, deviceId, tokenHash})`, `validate(tokenHash)` sliding 30-day expiry,
  `deleteByTokenHash`), `LoginAttemptRepo` (a `LoginAttemptStore`), `RootRepo`
  (`upsert`, `all`, `updateStatus`), `GameRepo`:
  - `upsertScanned(rootId, List<ScannedGameInput>, {Set<String>? systems}) → GameDiff {added, updated, removed}`.
    With `systems`, only those systems' games can be removed. **Never call for an offline root.**
  - `fileIndex(rootId) → Map<relPath, GameFileRecord>` → build the scanner's `ScanIndex`.
  - `list({systemId, query, GameOrder sort, offset, limit}) → GameListResult(games, total)`, `byId`, `systemCounts()`.
- `GameFileRecord.relPath` is relative to the **root** (`snes/x.sfc`); rs_core `GameFile.path` is
  relative to the system folder → strip `systemId/` when mapping.
- Sort enum is `GameOrder` (rs_core has `GameSort` string constants).

## security/
- `Tokens.generate()`, `Tokens.hash(token)` (use for every lookup), `constantTimeStringEquals`.
- `PasswordHasher().hash/verify` (Argon2id in an isolate, ~250 ms; tests: `Argon2Params.insecureFastForTests`).
- `LoginRateLimiter({store})`: `check(username, {address}) → LoginGate {allowed, retryAfter}` **before**
  verifying; `recordFailure` (also for unknown users), `recordSuccess`.

## fs/
- `PathProbe().check(input, ProbeKind) → PathProbeResult` (fields ⊇ contract `PathCheckResult`;
  `warnings` is `List<PathWarning>` with `.message`). Throws only `PathGuardException`.
- `DirectoryBrowser().browse(path?) → BrowseListing {path, parent, entries, shortcuts}`;
  null path = home. Throws `FsAccessException` / `PathGuardException`.
- `PathGuard(rootId, rootPath).resolveSafe(rel)`; `classifyFsError`.
- Map `PathGuardException` → 400 `path_invalid`; `FsAccessException(permissionDenied)` → 403.

## Packaging
`dart build cli` → `bundle/bin/rs_server` + `bundle/lib/libsqlite3.dylib`. Accepted for now
(PO decision); static linking revisited at release packaging.
