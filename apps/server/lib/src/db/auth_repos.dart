import 'package:rs_core/rs_core.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:uuid/uuid.dart';

import '../security/login_rate_limiter.dart';
import 'database.dart';

const _uuid = Uuid();

/// Key/value server settings.
class SettingsRepo {
  SettingsRepo(this._db);

  final RsDatabase _db;

  String? get(String key) {
    final rows = _db.db.select('SELECT value FROM settings WHERE key = ?', [
      key,
    ]);
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  void set(String key, String value) => _db.db.execute(
    'INSERT INTO settings (key, value) VALUES (?, ?) '
    'ON CONFLICT (key) DO UPDATE SET value = excluded.value',
    [key, value],
  );

  void remove(String key) =>
      _db.db.execute('DELETE FROM settings WHERE key = ?', [key]);

  Map<String, String> all() => {
    for (final r in _db.db.select('SELECT key, value FROM settings'))
      r['key'] as String: r['value'] as String,
  };
}

class UserRecord {
  const UserRecord({
    required this.id,
    required this.username,
    required this.role,
    required this.passwordHash,
    required this.createdAt,
  });

  factory UserRecord._fromRow(Row r) => UserRecord(
    id: r['id'] as String,
    username: r['username'] as String,
    role: UserRole.values.byName(r['role'] as String),
    passwordHash: r['password_hash'] as String,
    createdAt: fromDbTime(r['created_at'] as int),
  );

  final String id;
  final String username;
  final UserRole role;

  /// Argon2id PHC string from `PasswordHasher`.
  final String passwordHash;
  final DateTime createdAt;

  bool get isAdmin => role == UserRole.admin;
}

class ConflictException implements Exception {
  const ConflictException(this.message);

  final String message;

  @override
  String toString() => 'ConflictException: $message';
}

class UserRepo {
  UserRepo(this._db);

  final RsDatabase _db;

  /// Creates a user. [passwordHash] must already be hashed.
  ///
  /// Throws [ConflictException] if the username is taken (case-insensitive)
  /// or a second admin is created.
  UserRecord create({
    required String username,
    required UserRole role,
    required String passwordHash,
    DateTime? now,
  }) {
    final user = UserRecord(
      id: _uuid.v4(),
      username: username.trim(),
      role: role,
      passwordHash: passwordHash,
      createdAt: (now ?? DateTime.now()).toUtc(),
    );
    try {
      _db.db.execute(
        'INSERT INTO users (id, username, role, password_hash, created_at) '
        'VALUES (?, ?, ?, ?, ?)',
        [
          user.id,
          user.username,
          user.role.name,
          user.passwordHash,
          toDbTime(user.createdAt),
        ],
      );
    } on SqliteException catch (e) {
      if (_isConstraint(e)) {
        throw ConflictException(
          role == UserRole.admin && hasAdmin()
              ? 'An admin account already exists.'
              : 'Username "${user.username}" is taken.',
        );
      }
      rethrow;
    }
    return user;
  }

  UserRecord? byId(String id) => _one('SELECT * FROM users WHERE id = ?', [id]);

  /// Case-insensitive lookup.
  UserRecord? byUsername(String username) =>
      _one('SELECT * FROM users WHERE username = ?', [username.trim()]);

  List<UserRecord> all() => _db.db
      .select('SELECT * FROM users ORDER BY username COLLATE NOCASE')
      .map(UserRecord._fromRow)
      .toList();

  bool hasAdmin() =>
      _db.db.select("SELECT 1 FROM users WHERE role = 'admin'").isNotEmpty;

  int count() =>
      _db.db.select('SELECT COUNT(*) AS n FROM users').first['n'] as int;

  void updatePasswordHash(String id, String passwordHash) => _db.db.execute(
    'UPDATE users SET password_hash = ? WHERE id = ?',
    [passwordHash, id],
  );

  /// Deletes a user and (by cascade) their sessions. The admin can't be
  /// deleted: returns `false`.
  bool delete(String id) {
    _db.db.execute("DELETE FROM users WHERE id = ? AND role != 'admin'", [id]);
    return _db.db.updatedRows > 0;
  }

  UserRecord? _one(String sql, List<Object?> args) {
    final rows = _db.db.select(sql, args);
    return rows.isEmpty ? null : UserRecord._fromRow(rows.first);
  }
}

class DeviceRecord {
  const DeviceRecord({
    required this.id,
    required this.name,
    required this.platform,
    required this.createdAt,
    this.lastSeenAt,
    this.revokedAt,
  });

  factory DeviceRecord._fromRow(Row r) => DeviceRecord(
    id: r['id'] as String,
    name: r['name'] as String,
    platform: r['platform'] as String,
    createdAt: fromDbTime(r['created_at'] as int),
    lastSeenAt: fromDbTimeOrNull(r['last_seen_at']),
    revokedAt: fromDbTimeOrNull(r['revoked_at']),
  );

  final String id;
  final String name;
  final String platform;
  final DateTime createdAt;
  final DateTime? lastSeenAt;
  final DateTime? revokedAt;

  bool get revoked => revokedAt != null;
}

/// Joined devices. Tokens are stored only as SHA-256 hashes
/// (`Tokens.hash`).
class DeviceRepo {
  DeviceRepo(this._db);

  final RsDatabase _db;

  DeviceRecord create({
    required String name,
    required String platform,
    required String tokenHash,
    DateTime? now,
  }) {
    final device = DeviceRecord(
      id: _uuid.v4(),
      name: name,
      platform: platform,
      createdAt: (now ?? DateTime.now()).toUtc(),
    );
    _db.db.execute(
      'INSERT INTO devices (id, name, platform, token_hash, created_at) '
      'VALUES (?, ?, ?, ?, ?)',
      [
        device.id,
        device.name,
        device.platform,
        tokenHash,
        toDbTime(device.createdAt),
      ],
    );
    return device;
  }

  DeviceRecord? byId(String id) =>
      _one('SELECT * FROM devices WHERE id = ?', [id]);

  /// The non-revoked device with this token hash.
  DeviceRecord? byTokenHash(String tokenHash) => _one(
    'SELECT * FROM devices WHERE token_hash = ? AND revoked_at IS NULL',
    [tokenHash],
  );

  List<DeviceRecord> all() => _db.db
      .select('SELECT * FROM devices ORDER BY created_at')
      .map(DeviceRecord._fromRow)
      .toList();

  void touch(String id, {DateTime? now}) => _db.db.execute(
    'UPDATE devices SET last_seen_at = ? WHERE id = ?',
    [toDbTime(now ?? DateTime.now()), id],
  );

  /// Revokes the device and deletes its sessions.
  bool revoke(String id, {DateTime? now}) => _db.transaction(() {
    _db.db.execute(
      'UPDATE devices SET revoked_at = ? WHERE id = ? AND revoked_at IS NULL',
      [toDbTime(now ?? DateTime.now()), id],
    );
    final changed = _db.db.updatedRows > 0;
    _db.db.execute('DELETE FROM sessions WHERE device_id = ?', [id]);
    return changed;
  });

  DeviceRecord? _one(String sql, List<Object?> args) {
    final rows = _db.db.select(sql, args);
    return rows.isEmpty ? null : DeviceRecord._fromRow(rows.first);
  }
}

class SessionRecord {
  const SessionRecord({
    required this.id,
    required this.userId,
    required this.deviceId,
    required this.createdAt,
    required this.lastSeenAt,
    required this.expiresAt,
  });

  factory SessionRecord._fromRow(Row r) => SessionRecord(
    id: r['id'] as String,
    userId: r['user_id'] as String,
    deviceId: r['device_id'] as String,
    createdAt: fromDbTime(r['created_at'] as int),
    lastSeenAt: fromDbTime(r['last_seen_at'] as int),
    expiresAt: fromDbTime(r['expires_at'] as int),
  );

  final String id;
  final String userId;
  final String deviceId;
  final DateTime createdAt;
  final DateTime lastSeenAt;
  final DateTime expiresAt;
}

/// Logged-in users. Tokens are stored only as SHA-256 hashes.
///
/// Sessions slide: [validate] extends [SessionRecord.expiresAt] by [ttl].
class SessionRepo {
  SessionRepo(this._db, {this.ttl = const Duration(days: 30)});

  final RsDatabase _db;
  final Duration ttl;

  SessionRecord create({
    required String userId,
    required String deviceId,
    required String tokenHash,
    DateTime? now,
  }) {
    final t = (now ?? DateTime.now()).toUtc();
    final s = SessionRecord(
      id: _uuid.v4(),
      userId: userId,
      deviceId: deviceId,
      createdAt: t,
      lastSeenAt: t,
      expiresAt: t.add(ttl),
    );
    _db.db.execute(
      'INSERT INTO sessions (id, token_hash, user_id, device_id, created_at, '
      'last_seen_at, expires_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [
        s.id,
        tokenHash,
        userId,
        deviceId,
        toDbTime(t),
        toDbTime(t),
        toDbTime(s.expiresAt),
      ],
    );
    return s;
  }

  /// The live session for [tokenHash] (not expired, device not revoked),
  /// with its expiry extended. `null` if invalid; expired rows are deleted.
  SessionRecord? validate(String tokenHash, {DateTime? now}) {
    final t = (now ?? DateTime.now()).toUtc();
    final rows = _db.db.select(
      'SELECT s.* FROM sessions s JOIN devices d ON d.id = s.device_id '
      'WHERE s.token_hash = ? AND d.revoked_at IS NULL',
      [tokenHash],
    );
    if (rows.isEmpty) return null;
    final s = SessionRecord._fromRow(rows.first);
    if (!s.expiresAt.isAfter(t)) {
      _db.db.execute('DELETE FROM sessions WHERE id = ?', [s.id]);
      return null;
    }
    final expires = t.add(ttl);
    _db.db.execute(
      'UPDATE sessions SET last_seen_at = ?, expires_at = ? WHERE id = ?',
      [toDbTime(t), toDbTime(expires), s.id],
    );
    return SessionRecord(
      id: s.id,
      userId: s.userId,
      deviceId: s.deviceId,
      createdAt: s.createdAt,
      lastSeenAt: t,
      expiresAt: expires,
    );
  }

  void deleteByTokenHash(String tokenHash) =>
      _db.db.execute('DELETE FROM sessions WHERE token_hash = ?', [tokenHash]);

  void deleteForUser(String userId) =>
      _db.db.execute('DELETE FROM sessions WHERE user_id = ?', [userId]);

  List<SessionRecord> forUser(String userId) => _db.db
      .select('SELECT * FROM sessions WHERE user_id = ? ORDER BY created_at', [
        userId,
      ])
      .map(SessionRecord._fromRow)
      .toList();

  /// Deletes expired sessions; returns how many.
  int purgeExpired({DateTime? now}) {
    _db.db.execute('DELETE FROM sessions WHERE expires_at <= ?', [
      toDbTime(now ?? DateTime.now()),
    ]);
    return _db.db.updatedRows;
  }
}

/// Persistent [LoginAttemptStore] so lockouts survive restarts.
class LoginAttemptRepo implements LoginAttemptStore {
  LoginAttemptRepo(this._db);

  final RsDatabase _db;

  @override
  LoginAttemptState? get(String key) {
    final rows = _db.db.select('SELECT * FROM login_attempts WHERE key = ?', [
      key,
    ]);
    if (rows.isEmpty) return null;
    final r = rows.first;
    return LoginAttemptState(
      failures: r['failures'] as int,
      firstFailureAt: fromDbTime(r['first_failure_at'] as int),
      lockedUntil: fromDbTimeOrNull(r['locked_until']),
    );
  }

  @override
  void put(String key, LoginAttemptState state) => _db.db.execute(
    'INSERT INTO login_attempts (key, failures, first_failure_at, '
    'locked_until) VALUES (?, ?, ?, ?) ON CONFLICT (key) DO UPDATE SET '
    'failures = excluded.failures, '
    'first_failure_at = excluded.first_failure_at, '
    'locked_until = excluded.locked_until',
    [
      key,
      state.failures,
      toDbTime(state.firstFailureAt),
      state.lockedUntil == null ? null : toDbTime(state.lockedUntil!),
    ],
  );

  @override
  void delete(String key) =>
      _db.db.execute('DELETE FROM login_attempts WHERE key = ?', [key]);

  /// Deletes entries older than [olderThan] that aren't locked.
  void purge(DateTime olderThan) => _db.db.execute(
    'DELETE FROM login_attempts WHERE first_failure_at < ? AND '
    '(locked_until IS NULL OR locked_until < ?)',
    [toDbTime(olderThan), toDbTime(olderThan)],
  );
}

bool _isConstraint(SqliteException e) =>
    e.extendedResultCode & 0xff == 19; // SQLITE_CONSTRAINT
