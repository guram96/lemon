/// Versioned schema migrations. Entry `i` upgrades the schema from version
/// `i` to `i + 1`; `PRAGMA user_version` holds the current version.
///
/// Never edit a released migration. Append a new one instead.
///
/// Conventions: ids are UUID strings, timestamps are UTC milliseconds since
/// the epoch (INTEGER), booleans are 0/1, ROM paths are relative to their
/// library root with `/` separators.
const List<String> migrations = [
  // 1: initial schema.
  '''
CREATE TABLE settings (
  key   TEXT PRIMARY KEY,
  value TEXT NOT NULL
);

CREATE TABLE users (
  id            TEXT PRIMARY KEY,
  username      TEXT NOT NULL UNIQUE COLLATE NOCASE,
  role          TEXT NOT NULL CHECK (role IN ('admin', 'user')),
  password_hash TEXT NOT NULL,
  created_at    INTEGER NOT NULL
);
-- Exactly one admin account.
CREATE UNIQUE INDEX users_single_admin ON users (role) WHERE role = 'admin';

CREATE TABLE devices (
  id           TEXT PRIMARY KEY,
  name         TEXT NOT NULL,
  platform     TEXT NOT NULL,
  token_hash   TEXT NOT NULL UNIQUE,
  created_at   INTEGER NOT NULL,
  last_seen_at INTEGER,
  revoked_at   INTEGER
);

CREATE TABLE sessions (
  id           TEXT PRIMARY KEY,
  token_hash   TEXT NOT NULL UNIQUE,
  user_id      TEXT NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  device_id    TEXT NOT NULL REFERENCES devices (id) ON DELETE CASCADE,
  created_at   INTEGER NOT NULL,
  last_seen_at INTEGER NOT NULL,
  expires_at   INTEGER NOT NULL
);
CREATE INDEX sessions_user ON sessions (user_id);
CREATE INDEX sessions_device ON sessions (device_id);

CREATE TABLE login_attempts (
  key              TEXT PRIMARY KEY,
  failures         INTEGER NOT NULL,
  first_failure_at INTEGER NOT NULL,
  locked_until     INTEGER
);

CREATE TABLE roots (
  id        TEXT PRIMARY KEY,
  label     TEXT NOT NULL,
  last_path TEXT NOT NULL,
  status    TEXT NOT NULL CHECK (status IN ('online', 'readOnly', 'offline')),
  added_at  INTEGER NOT NULL
);

CREATE TABLE games (
  id               TEXT PRIMARY KEY,
  root_id          TEXT NOT NULL REFERENCES roots (id) ON DELETE CASCADE,
  system_id        TEXT NOT NULL,
  primary_rel_path TEXT NOT NULL,
  title            TEXT NOT NULL,
  region           TEXT,
  added_at         INTEGER NOT NULL,
  updated_at       INTEGER NOT NULL,
  description      TEXT,
  developer        TEXT,
  publisher        TEXT,
  release_year     INTEGER,
  UNIQUE (root_id, system_id, primary_rel_path)
);
CREATE INDEX games_system_title ON games (system_id, title COLLATE NOCASE);
CREATE INDEX games_title ON games (title COLLATE NOCASE);
CREATE INDEX games_added ON games (added_at);

CREATE TABLE game_files (
  game_id      TEXT NOT NULL REFERENCES games (id) ON DELETE CASCADE,
  position     INTEGER NOT NULL,
  rel_path     TEXT NOT NULL,
  size         INTEGER NOT NULL,
  mtime        INTEGER NOT NULL,
  crc32        TEXT,
  md5          TEXT,
  sha1         TEXT,
  partial_hash INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (game_id, rel_path)
);
CREATE INDEX game_files_sha1 ON game_files (sha1);

CREATE TABLE artwork (
  id          TEXT PRIMARY KEY,
  game_id     TEXT NOT NULL REFERENCES games (id) ON DELETE CASCADE,
  kind        TEXT NOT NULL,
  source      TEXT NOT NULL,
  rel_path    TEXT NOT NULL,
  width       INTEGER,
  height      INTEGER,
  is_override INTEGER NOT NULL DEFAULT 0,
  created_at  INTEGER NOT NULL
);
CREATE INDEX artwork_game ON artwork (game_id, kind);
''',
];
