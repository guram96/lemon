import 'package:sqlite3/sqlite3.dart';
import 'package:uuid/uuid.dart';

import '../fs/path_guard.dart';
import 'database.dart';

/// One file of a game. [relPath] is relative to the **library root**
/// (`snes/Super Mario World.sfc`), `/`-separated; never absolute.
class GameFileRecord {
  const GameFileRecord({
    required this.relPath,
    required this.size,
    required this.mtime,
    this.crc32,
    this.md5,
    this.sha1,
    this.partialHash = false,
  });

  factory GameFileRecord._fromRow(Row r) => GameFileRecord(
    relPath: r['rel_path'] as String,
    size: r['size'] as int,
    mtime: fromDbTime(r['mtime'] as int),
    crc32: r['crc32'] as String?,
    md5: r['md5'] as String?,
    sha1: r['sha1'] as String?,
    partialHash: (r['partial_hash'] as int) != 0,
  );

  final String relPath;
  final int size;
  final DateTime mtime;
  final String? crc32;
  final String? md5;
  final String? sha1;

  /// Hashes cover only size + first/last chunks (files > 4 GiB).
  final bool partialHash;

  bool sameAs(GameFileRecord o) =>
      o.relPath == relPath &&
      o.size == size &&
      toDbTime(o.mtime) == toDbTime(mtime) &&
      o.crc32 == crc32 &&
      o.md5 == md5 &&
      o.sha1 == sha1 &&
      o.partialHash == partialHash;
}

/// A game as stored in the catalog.
class GameRecord {
  const GameRecord({
    required this.id,
    required this.rootId,
    required this.systemId,
    required this.primaryRelPath,
    required this.title,
    required this.addedAt,
    required this.updatedAt,
    required this.files,
    this.region,
    this.description,
    this.developer,
    this.publisher,
    this.releaseYear,
  });

  final String id;
  final String rootId;
  final String systemId;

  /// Root-relative path of the main file (`.cue`, `.m3u`, the ROM itself).
  /// Together with [rootId] and [systemId] this is the game's identity.
  final String primaryRelPath;
  final String title;
  final String? region;
  final DateTime addedAt;
  final DateTime updatedAt;
  final String? description;
  final String? developer;
  final String? publisher;
  final int? releaseYear;

  /// In scan order; the primary file first.
  final List<GameFileRecord> files;

  int get sizeBytes => files.fold(0, (sum, f) => sum + f.size);
}

/// A game unit produced by the scanner, input to [GameRepo.upsertScanned].
class ScannedGameInput {
  const ScannedGameInput({
    required this.systemId,
    required this.primaryRelPath,
    required this.title,
    required this.files,
    this.region,
  });

  final String systemId;
  final String primaryRelPath;
  final String title;
  final String? region;
  final List<GameFileRecord> files;
}

/// What [GameRepo.upsertScanned] changed.
class GameDiff {
  const GameDiff({
    this.added = const [],
    this.updated = const [],
    this.removed = const [],
  });

  final List<String> added;
  final List<String> updated;
  final List<String> removed;

  bool get isEmpty => added.isEmpty && updated.isEmpty && removed.isEmpty;
}

enum GameOrder {
  /// Title A–Z (case-insensitive).
  title,

  /// Most recently added first.
  recent,
}

class GameListResult {
  const GameListResult(this.games, this.total);

  final List<GameRecord> games;

  /// Matching games before paging.
  final int total;
}

class SystemGameCount {
  const SystemGameCount(this.systemId, this.gameCount);

  final String systemId;
  final int gameCount;
}

/// The game catalog.
class GameRepo {
  GameRepo(this._db);

  final RsDatabase _db;
  static const _uuid = Uuid();

  /// Replaces the catalog of [rootId] with the result of a scan.
  ///
  /// Games are matched by (root, system, primary rel path). New ones are
  /// added; existing ones whose title, region or files changed are updated
  /// (scraped metadata is kept); games of the root that are not in [games]
  /// are removed. When [systems] is given, only games of those systems are
  /// considered for removal (a partial scan).
  ///
  /// Runs in one transaction. Never call it for an offline root: that would
  /// remove all its games.
  GameDiff upsertScanned(
    String rootId,
    List<ScannedGameInput> games, {
    Set<String>? systems,
    DateTime? now,
  }) {
    for (final g in games) {
      _checkRelPath(g.primaryRelPath);
      for (final f in g.files) {
        _checkRelPath(f.relPath);
      }
    }
    final t = toDbTime(now ?? DateTime.now());
    return _db.transaction(() {
      final existing = <String, GameRecord>{
        for (final g in _query('WHERE g.root_id = ?', [rootId]))
          _key(g.systemId, g.primaryRelPath): g,
      };
      final added = <String>[];
      final updated = <String>[];
      final seen = <String>{};

      for (final input in games) {
        final key = _key(input.systemId, input.primaryRelPath);
        if (!seen.add(key)) continue; // duplicate in input: first wins
        final old = existing[key];
        if (old == null) {
          final id = _uuid.v4();
          _db.db.execute(
            'INSERT INTO games (id, root_id, system_id, primary_rel_path, '
            'title, region, added_at, updated_at) '
            'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
            [
              id,
              rootId,
              input.systemId,
              input.primaryRelPath,
              input.title,
              input.region,
              t,
              t,
            ],
          );
          _insertFiles(id, input.files);
          added.add(id);
        } else if (_changed(old, input)) {
          _db.db.execute(
            'UPDATE games SET title = ?, region = ?, updated_at = ? '
            'WHERE id = ?',
            [input.title, input.region, t, old.id],
          );
          _db.db.execute('DELETE FROM game_files WHERE game_id = ?', [old.id]);
          _insertFiles(old.id, input.files);
          updated.add(old.id);
        }
      }

      final removed = <String>[];
      for (final entry in existing.entries) {
        if (seen.contains(entry.key)) continue;
        if (systems != null && !systems.contains(entry.value.systemId)) {
          continue;
        }
        removed.add(entry.value.id);
      }
      for (final id in removed) {
        _db.db.execute('DELETE FROM games WHERE id = ?', [id]);
      }
      return GameDiff(added: added, updated: updated, removed: removed);
    });
  }

  /// The stored files of [rootId] by root-relative path, so the scanner can
  /// skip re-hashing files whose size and mtime didn't change.
  Map<String, GameFileRecord> fileIndex(String rootId) => {
    for (final r in _db.db.select(
      'SELECT f.* FROM game_files f JOIN games g ON g.id = f.game_id '
      'WHERE g.root_id = ?',
      [rootId],
    ))
      r['rel_path'] as String: GameFileRecord._fromRow(r),
  };

  GameRecord? byId(String id) {
    final list = _query('WHERE g.id = ?', [id]);
    return list.isEmpty ? null : list.first;
  }

  /// Games, filtered by [systemId] and a case-insensitive title substring
  /// [query], sorted and paged.
  GameListResult list({
    String? systemId,
    String? query,
    GameOrder sort = GameOrder.title,
    int offset = 0,
    int? limit,
  }) {
    final where = <String>[];
    final args = <Object?>[];
    if (systemId != null && systemId.isNotEmpty) {
      where.add('g.system_id = ?');
      args.add(systemId);
    }
    final q = query?.trim();
    if (q != null && q.isNotEmpty) {
      where.add(r"g.title LIKE ? ESCAPE '\'");
      args.add('%${_escapeLike(q)}%');
    }
    final whereSql = where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}';
    final total =
        _db.db
                .select('SELECT COUNT(*) AS n FROM games g $whereSql', args)
                .first['n']
            as int;
    final order = switch (sort) {
      GameOrder.title => 'g.title COLLATE NOCASE, g.system_id, g.id',
      GameOrder.recent => 'g.added_at DESC, g.title COLLATE NOCASE, g.id',
    };
    final paging = limit == null
        ? (offset > 0 ? 'LIMIT -1 OFFSET $offset' : '')
        : 'LIMIT ${limit < 0 ? 0 : limit} OFFSET ${offset < 0 ? 0 : offset}';
    final games = _query('$whereSql ORDER BY $order $paging', args);
    return GameListResult(games, total);
  }

  /// Game count per system, only systems with at least one game, by id.
  List<SystemGameCount> systemCounts() => _db.db
      .select(
        'SELECT system_id, COUNT(*) AS n FROM games '
        'GROUP BY system_id ORDER BY system_id',
      )
      .map((r) => SystemGameCount(r['system_id'] as String, r['n'] as int))
      .toList();

  int count({String? rootId}) =>
      (rootId == null
                  ? _db.db.select('SELECT COUNT(*) AS n FROM games')
                  : _db.db.select(
                      'SELECT COUNT(*) AS n FROM games WHERE root_id = ?',
                      [rootId],
                    ))
              .first['n']
          as int;

  /// Updates scraped/edited metadata. `null` arguments are left unchanged.
  void updateMetadata(
    String id, {
    String? title,
    String? description,
    String? developer,
    String? publisher,
    int? releaseYear,
    DateTime? now,
  }) => _db.db.execute(
    'UPDATE games SET title = COALESCE(?, title), '
    'description = COALESCE(?, description), '
    'developer = COALESCE(?, developer), '
    'publisher = COALESCE(?, publisher), '
    'release_year = COALESCE(?, release_year), updated_at = ? WHERE id = ?',
    [
      title,
      description,
      developer,
      publisher,
      releaseYear,
      toDbTime(now ?? DateTime.now()),
      id,
    ],
  );

  /// Removes a game from the catalog (not its files).
  bool delete(String id) {
    _db.db.execute('DELETE FROM games WHERE id = ?', [id]);
    return _db.db.updatedRows > 0;
  }

  // ---------------------------------------------------------------------

  /// ROM paths must be canonical root-relative paths: never absolute, no
  /// `..`, `/`-separated. Throws [ArgumentError] otherwise.
  static void _checkRelPath(String relPath) {
    final String canonical;
    try {
      canonical = PathGuard.normalizeRelative(relPath);
    } on PathGuardException catch (e) {
      throw ArgumentError.value(relPath, 'relPath', e.reason.name);
    }
    if (canonical != relPath) {
      throw ArgumentError.value(relPath, 'relPath', 'not canonical');
    }
  }

  static String _key(String systemId, String relPath) => '$systemId\n$relPath';

  static String _escapeLike(String s) =>
      s.replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_');

  static bool _changed(GameRecord old, ScannedGameInput input) {
    if (old.title != input.title || old.region != input.region) return true;
    if (old.files.length != input.files.length) return true;
    for (var i = 0; i < old.files.length; i++) {
      if (!old.files[i].sameAs(input.files[i])) return true;
    }
    return false;
  }

  void _insertFiles(String gameId, List<GameFileRecord> files) {
    final stmt = _db.db.prepare(
      'INSERT OR REPLACE INTO game_files (game_id, position, rel_path, size, '
      'mtime, crc32, md5, sha1, partial_hash) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
    );
    try {
      for (var i = 0; i < files.length; i++) {
        final f = files[i];
        stmt.execute([
          gameId,
          i,
          f.relPath,
          f.size,
          toDbTime(f.mtime),
          f.crc32,
          f.md5,
          f.sha1,
          f.partialHash ? 1 : 0,
        ]);
      }
    } finally {
      stmt.close();
    }
  }

  /// Loads games matching [tail] (WHERE/ORDER/LIMIT on alias `g`) with their
  /// files in two queries.
  List<GameRecord> _query(String tail, List<Object?> args) {
    final rows = _db.db.select('SELECT g.* FROM games g $tail', args);
    if (rows.isEmpty) return const [];
    final ids = [for (final r in rows) r['id'] as String];
    final files = <String, List<GameFileRecord>>{};
    // Chunk to stay under SQLite's bound-parameter limit.
    for (var i = 0; i < ids.length; i += 500) {
      final chunk = ids.sublist(i, i + 500 > ids.length ? ids.length : i + 500);
      final marks = List.filled(chunk.length, '?').join(',');
      for (final r in _db.db.select(
        'SELECT * FROM game_files WHERE game_id IN ($marks) '
        'ORDER BY game_id, position',
        chunk,
      )) {
        (files[r['game_id'] as String] ??= []).add(GameFileRecord._fromRow(r));
      }
    }
    return [
      for (final r in rows)
        GameRecord(
          id: r['id'] as String,
          rootId: r['root_id'] as String,
          systemId: r['system_id'] as String,
          primaryRelPath: r['primary_rel_path'] as String,
          title: r['title'] as String,
          region: r['region'] as String?,
          addedAt: fromDbTime(r['added_at'] as int),
          updatedAt: fromDbTime(r['updated_at'] as int),
          description: r['description'] as String?,
          developer: r['developer'] as String?,
          publisher: r['publisher'] as String?,
          releaseYear: r['release_year'] as int?,
          files: files[r['id'] as String] ?? const [],
        ),
    ];
  }
}
