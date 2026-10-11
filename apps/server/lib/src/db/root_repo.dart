import 'package:rs_core/rs_core.dart';
import 'package:sqlite3/sqlite3.dart';

import 'database.dart';

class RootRecord {
  const RootRecord({
    required this.id,
    required this.label,
    required this.lastPath,
    required this.status,
    required this.addedAt,
  });

  factory RootRecord._fromRow(Row r) => RootRecord(
    id: r['id'] as String,
    label: r['label'] as String,
    lastPath: r['last_path'] as String,
    status: LibraryRootStatus.values.byName(r['status'] as String),
    addedAt: fromDbTime(r['added_at'] as int),
  );

  /// The UUID from the root's marker file (or generated, for read-only roots).
  final String id;
  final String label;

  /// Absolute path where the root was last found. A hint only: the marker id
  /// is the identity.
  final String lastPath;
  final LibraryRootStatus status;
  final DateTime addedAt;
}

/// Library roots. Removing a root deletes its games (cascade).
class RootRepo {
  RootRepo(this._db);

  final RsDatabase _db;

  /// Inserts or updates a root by id (label, last path, status).
  RootRecord upsert({
    required String id,
    required String label,
    required String lastPath,
    required LibraryRootStatus status,
    DateTime? now,
  }) {
    _db.db.execute(
      'INSERT INTO roots (id, label, last_path, status, added_at) '
      'VALUES (?, ?, ?, ?, ?) ON CONFLICT (id) DO UPDATE SET '
      'label = excluded.label, last_path = excluded.last_path, '
      'status = excluded.status',
      [id, label, lastPath, status.name, toDbTime(now ?? DateTime.now())],
    );
    return byId(id)!;
  }

  RootRecord? byId(String id) {
    final rows = _db.db.select('SELECT * FROM roots WHERE id = ?', [id]);
    return rows.isEmpty ? null : RootRecord._fromRow(rows.first);
  }

  List<RootRecord> all() => _db.db
      .select('SELECT * FROM roots ORDER BY added_at, label')
      .map(RootRecord._fromRow)
      .toList();

  void updateStatus(String id, LibraryRootStatus status, {String? lastPath}) {
    if (lastPath == null) {
      _db.db.execute('UPDATE roots SET status = ? WHERE id = ?', [
        status.name,
        id,
      ]);
    } else {
      _db.db.execute(
        'UPDATE roots SET status = ?, last_path = ? WHERE id = ?',
        [status.name, lastPath, id],
      );
    }
  }

  void rename(String id, String label) =>
      _db.db.execute('UPDATE roots SET label = ? WHERE id = ?', [label, id]);

  /// Removes the root and all its games from the catalog. Never touches files.
  bool delete(String id) {
    _db.db.execute('DELETE FROM roots WHERE id = ?', [id]);
    return _db.db.updatedRows > 0;
  }
}
