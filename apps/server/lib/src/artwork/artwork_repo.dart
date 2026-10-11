import 'dart:typed_data';

import 'package:rs_core/rs_core.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:uuid/uuid.dart';

import '../db/database.dart';
import 'artwork_files.dart';

const _uuid = Uuid();

/// One processed artwork file for a game.
class ArtworkRecord {
  const ArtworkRecord({
    required this.id,
    required this.gameId,
    required this.kind,
    required this.source,
    required this.relPath,
    required this.isOverride,
    this.width,
    this.height,
  });

  final String id;
  final String gameId;
  final ArtworkKind kind;
  final ArtworkSource source;

  /// File name inside the artwork directory.
  final String relPath;
  final int? width;
  final int? height;

  /// Set by an admin. A scrape must not replace it.
  final bool isOverride;

  Artwork toDto() =>
      Artwork(id: id, kind: kind, source: source, width: width, height: height);
}

/// Catalog of processed artwork. One image per game and kind; an override
/// wins over anything a scrape wants to write.
class ArtworkRepo {
  ArtworkRepo(this._db, this._files);

  final RsDatabase _db;
  final ArtworkFiles _files;

  ArtworkRecord? byId(String id) {
    final rows = _db.db.select('SELECT * FROM artwork WHERE id = ?', [id]);
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  /// Selected artwork for each game, keyed by game id. Overrides win when a
  /// kind has more than one row.
  Map<String, Map<ArtworkKind, ArtworkRecord>> forGames(Iterable<String> ids) {
    final list = ids.toList();
    if (list.isEmpty) return const {};
    final marks = List.filled(list.length, '?').join(', ');
    final rows = _db.db.select(
      'SELECT * FROM artwork WHERE game_id IN ($marks)',
      list,
    );
    final out = <String, Map<ArtworkKind, ArtworkRecord>>{};
    for (final row in rows) {
      final record = _fromRow(row);
      final kinds = out.putIfAbsent(record.gameId, () => {});
      final current = kinds[record.kind];
      if (current == null || record.isOverride) kinds[record.kind] = record;
    }
    return out;
  }

  bool hasOverride(String gameId, ArtworkKind kind) => _db.db.select(
    'SELECT 1 FROM artwork WHERE game_id = ? AND kind = ? AND is_override = 1',
    [gameId, kind.name],
  ).isNotEmpty;

  /// Stores scraped art. Returns `null` when an override already occupies
  /// [kind], leaving that image untouched.
  ArtworkRecord? putScraped({
    required String gameId,
    required ArtworkKind kind,
    required ArtworkSource source,
    required List<int> bytes,
    DateTime? now,
  }) {
    if (hasOverride(gameId, kind)) return null;
    final previous = _db.db.select(
      'SELECT rel_path FROM artwork WHERE game_id = ? AND kind = ? '
      'AND is_override = 0',
      [gameId, kind.name],
    );
    final stored = _put(
      gameId: gameId,
      kind: kind,
      source: source,
      bytes: bytes,
      isOverride: false,
      now: now,
    );
    for (final row in previous) {
      _files.delete(row['rel_path'] as String);
    }
    return stored;
  }

  ArtworkRecord _put({
    required String gameId,
    required ArtworkKind kind,
    required ArtworkSource source,
    required List<int> bytes,
    required bool isOverride,
    DateTime? now,
  }) {
    final id = _uuid.v4();
    final stored = _files.save(
      id,
      bytes is Uint8List ? bytes : Uint8List.fromList(bytes),
    );
    _db.transaction(() {
      if (!isOverride) {
        _db.db.execute(
          'DELETE FROM artwork WHERE game_id = ? AND kind = ? AND is_override = 0',
          [gameId, kind.name],
        );
      }
      _db.db.execute(
        'INSERT INTO artwork (id, game_id, kind, source, rel_path, width, '
        'height, is_override, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          id,
          gameId,
          kind.name,
          source.name,
          stored.relPath,
          stored.width,
          stored.height,
          isOverride ? 1 : 0,
          toDbTime(now ?? DateTime.now()),
        ],
      );
    });
    return byId(id)!;
  }

  ArtworkRecord _fromRow(Row row) => ArtworkRecord(
    id: row['id'] as String,
    gameId: row['game_id'] as String,
    kind: ArtworkKind.values.byName(row['kind'] as String),
    source: ArtworkSource.values.byName(row['source'] as String),
    relPath: row['rel_path'] as String,
    width: row['width'] as int?,
    height: row['height'] as int?,
    isOverride: (row['is_override'] as int) != 0,
  );
}
