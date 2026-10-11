import 'package:sqlite3/sqlite3.dart';

import 'migrations.dart';

class DatabaseException implements Exception {
  const DatabaseException(this.message);

  final String message;

  @override
  String toString() => 'DatabaseException: $message';
}

/// The server catalog: one SQLite file in the data directory.
///
/// SQLite is bundled with the server through `package:sqlite3`'s build hooks,
/// so no system library is needed. All access is synchronous and happens on
/// the server's isolate; queries are small and indexed.
class RsDatabase {
  RsDatabase._(this.db) {
    db.execute('PRAGMA foreign_keys = ON');
    db.execute('PRAGMA busy_timeout = 5000');
    _migrate();
  }

  /// Opens (creating if needed) the database file at [path] and migrates it
  /// to [schemaVersion].
  factory RsDatabase.open(String path) {
    final db = sqlite3.open(path);
    try {
      // WAL: readers don't block the writer. Falls back silently on
      // filesystems that can't do WAL.
      db.execute('PRAGMA journal_mode = WAL');
      db.execute('PRAGMA synchronous = NORMAL');
      return RsDatabase._(db);
    } on Object {
      db.close();
      rethrow;
    }
  }

  /// A throwaway in-memory database, for tests.
  factory RsDatabase.inMemory() => RsDatabase._(sqlite3.openInMemory());

  /// The raw connection, for repositories.
  final Database db;

  /// Latest schema version this build knows.
  static int get schemaVersion => migrations.length;

  int get userVersion => db.userVersion;

  void _migrate() {
    final current = db.userVersion;
    if (current > schemaVersion) {
      throw DatabaseException(
        'The database was created by a newer Retro Steam '
        '(schema $current, this build supports $schemaVersion).',
      );
    }
    for (var v = current; v < schemaVersion; v++) {
      transaction(() {
        db.execute(migrations[v]);
        db.userVersion = v + 1;
      });
    }
  }

  /// Runs [action] in a transaction; rolls back if it throws.
  /// Nested calls join the outer transaction.
  T transaction<T>(T Function() action) {
    if (!db.autocommit) return action();
    db.execute('BEGIN IMMEDIATE');
    try {
      final result = action();
      db.execute('COMMIT');
      return result;
    } on Object {
      db.execute('ROLLBACK');
      rethrow;
    }
  }

  /// Checkpoints the WAL and closes the connection, leaving a single
  /// self-contained file (safe to move the data directory afterwards).
  void close() {
    try {
      db.execute('PRAGMA wal_checkpoint(TRUNCATE)');
    } on SqliteException {
      // In-memory or non-WAL database.
    }
    db.close();
  }
}

/// Milliseconds since the epoch (UTC) for storage.
int toDbTime(DateTime t) => t.toUtc().millisecondsSinceEpoch;

DateTime fromDbTime(int ms) =>
    DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);

DateTime? fromDbTimeOrNull(Object? ms) =>
    ms == null ? null : fromDbTime(ms as int);
