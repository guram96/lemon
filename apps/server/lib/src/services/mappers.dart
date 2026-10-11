import 'package:rs_core/rs_core.dart';

import '../artwork/artwork_repo.dart';
import '../db/auth_repos.dart';
import '../db/game_repo.dart';
import '../db/root_repo.dart';
import '../fs/directory_browser.dart';
import '../fs/path_probe.dart';
import '../scanner/scan_models.dart';

/// Conversions between server records and `rs_core` DTOs.
abstract final class Mappers {
  static User user(UserRecord u) =>
      User(id: u.id, username: u.username, role: u.role);

  static LibraryRoot root(RootRecord r) =>
      LibraryRoot(id: r.id, label: r.label, status: r.status);

  /// A catalog game. File paths become relative to the system folder
  /// (`snes/Game.sfc` → `Game.sfc`).
  static Game game(
    GameRecord g, {
    Map<ArtworkKind, ArtworkRecord> artwork = const {},
  }) {
    final prefix = '${g.systemId}/';
    return Game(
      id: g.id,
      systemId: g.systemId,
      title: g.title,
      rootId: g.rootId,
      addedAt: g.addedAt,
      description: g.description,
      developer: g.developer,
      publisher: g.publisher,
      releaseYear: g.releaseYear,
      artwork: {for (final e in artwork.entries) e.key: e.value.toDto()},
      files: [
        for (final f in g.files)
          GameFile(
            path: f.relPath.startsWith(prefix)
                ? f.relPath.substring(prefix.length)
                : f.relPath,
            sizeBytes: f.size,
            sha1: f.sha1,
          ),
      ],
    );
  }

  static SystemSummary system(SystemGameCount c) => SystemSummary(
    systemId: c.systemId,
    name: GameSystems.byId(c.systemId)?.name ?? c.systemId,
    gameCount: c.gameCount,
  );

  static BrowseEntry browseEntry(BrowseItem i) => BrowseEntry(
    name: i.name,
    path: i.path,
    isDirectory: i.isDirectory,
    readable: i.readable,
  );

  static BrowseResult browse(BrowseListing l) => BrowseResult(
    path: l.path,
    parent: l.parent,
    entries: l.entries.map(browseEntry).toList(),
    shortcuts: l.shortcuts.map(browseEntry).toList(),
  );

  static ProbeKind probeKind(PathKind k) => switch (k) {
    PathKind.dataDir => ProbeKind.dataDir,
    PathKind.libraryRoot => ProbeKind.libraryRoot,
  };

  static PathCheckResult pathCheck(PathProbeResult r, PathKind kind) =>
      PathCheckResult(
        path: r.path,
        kind: kind,
        exists: r.exists,
        readable: r.readable,
        writable: r.writable,
        permissionDenied: r.permissionDenied,
        existingMarkerId: r.existingMarkerId,
        detectedSystems: [
          for (final s in r.detectedSystems)
            DetectedSystem(systemId: s.systemId, fileCount: s.fileCount),
        ],
        freeBytes: r.freeBytes,
        warnings: [for (final w in r.warnings) w.message],
      );

  // --- Scanner ↔ catalog ----------------------------------------------------

  static ScannedFile scannedFile(GameFileRecord f) => ScannedFile(
    relPath: f.relPath,
    size: f.size,
    modified: f.mtime,
    crc32: f.crc32,
    md5: f.md5,
    sha1: f.sha1,
    partialHash: f.partialHash,
  );

  static ScannedGameInput scannedGame(ScannedGame g) => ScannedGameInput(
    systemId: g.systemId,
    primaryRelPath: g.primaryRelPath,
    title: g.title,
    region: g.region,
    files: [
      for (final f in g.files)
        GameFileRecord(
          relPath: f.relPath,
          size: f.size,
          mtime: f.modified,
          crc32: f.crc32,
          md5: f.md5,
          sha1: f.sha1,
          partialHash: f.partialHash,
        ),
    ],
  );
}
