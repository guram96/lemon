import 'package:logging/logging.dart';

import '../db/db.dart';
import '../scanner/scanner.dart';
import '../security/security.dart';
import '../storage/storage.dart';
import 'event_hub.dart';
import 'root_service.dart';
import 'scan_service.dart';

final _log = Logger('server');

/// Everything that exists once the server is set up: the data directory, the
/// open database, repositories and long-running services.
class ConfiguredServer {
  ConfiguredServer._({
    required this.dataDir,
    required this.db,
    required this.roots,
    required this.scans,
  }) : settings = SettingsRepo(db),
       users = UserRepo(db),
       devices = DeviceRepo(db),
       sessions = SessionRepo(db),
       games = GameRepo(db),
       rootRepo = RootRepo(db),
       loginAttempts = LoginAttemptRepo(db) {
    limiter = LoginRateLimiter(store: loginAttempts);
  }

  /// Wraps an already open [db] in [dataDir] and refreshes the status of
  /// every library root. Does not close [db] on failure.
  static Future<ConfiguredServer> attach({
    required DataDir dataDir,
    required RsDatabase db,
    required EventHub events,
    required Scanner scanner,
    required List<String> rootSearchDirs,
  }) async {
    final rootRepo = RootRepo(db);
    final rootService = RootService(
      rootRepo,
      events,
      searchDirs: rootSearchDirs,
    );
    final scans = ScanService(
      roots: rootService,
      games: GameRepo(db),
      events: events,
      scanner: scanner,
    );
    final server = ConfiguredServer._(
      dataDir: dataDir,
      db: db,
      roots: rootService,
      scans: scans,
    );
    final purged = server.sessions.purgeExpired();
    if (purged > 0) _log.fine('Purged $purged expired session(s)');
    final all = await rootService.refresh();
    for (final r in all) {
      _log.info('Library root "${r.label}": ${r.status.name} (${r.lastPath})');
    }
    return server;
  }

  /// Opens the data directory at [dataDirPath] and its database.
  static Future<ConfiguredServer> open(
    String dataDirPath, {
    required EventHub events,
    required Scanner scanner,
    required List<String> rootSearchDirs,
  }) async {
    final dataDir = await DataDir.open(dataDirPath);
    await dataDir.clearTmp();
    final db = RsDatabase.open(dataDir.dbPath);
    try {
      return await attach(
        dataDir: dataDir,
        db: db,
        events: events,
        scanner: scanner,
        rootSearchDirs: rootSearchDirs,
      );
    } on Object {
      db.close();
      rethrow;
    }
  }

  final DataDir dataDir;
  final RsDatabase db;
  final RootService roots;
  final ScanService scans;

  final SettingsRepo settings;
  final UserRepo users;
  final DeviceRepo devices;
  final SessionRepo sessions;
  final GameRepo games;
  final RootRepo rootRepo;
  final LoginAttemptRepo loginAttempts;
  late final LoginRateLimiter limiter;

  bool _closed = false;

  /// Stops the scan and closes the database.
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await scans.shutdown();
    db.close();
  }
}
