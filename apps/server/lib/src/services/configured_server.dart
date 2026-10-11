import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:rs_core/rs_core.dart';

import '../artwork/artwork_files.dart';
import '../artwork/artwork_repo.dart';
import '../db/db.dart';
import '../scanner/scanner.dart';
import '../security/security.dart';
import '../storage/storage.dart';
import '../watch/library_watcher.dart';
import 'event_hub.dart';
import 'root_service.dart';
import 'scan_service.dart';
import 'scrape_service.dart';

final _log = Logger('server');

/// Everything that exists once the server is set up: the data directory, the
/// open database, repositories and long-running services.
class ConfiguredServer {
  ConfiguredServer._({
    required this.dataDir,
    required this.db,
    required this.roots,
    required this.scans,
    required EventHub events,
  }) : settings = SettingsRepo(db),
       users = UserRepo(db),
       devices = DeviceRepo(db),
       sessions = SessionRepo(db),
       games = GameRepo(db),
       rootRepo = RootRepo(db),
       loginAttempts = LoginAttemptRepo(db) {
    artworkFiles = ArtworkFiles(
      artworkDir: dataDir.artworkDir,
      cacheDir: p.join(dataDir.cacheDir, 'artwork'),
    );
    artwork = ArtworkRepo(db, artworkFiles);
    limiter = LoginRateLimiter(store: loginAttempts);
    scrapes = ScrapeService(
      games: games,
      artwork: artwork,
      settings: settings,
      events: events,
    );
    scans.onFinished = _onScanFinished;
    _watchSub = watcher.changes.listen((_) {
      if (_closed) return;
      if (!scans.start()) _scanAgain = true;
    });
    _syncWatches();
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
      events: events,
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
  late final ArtworkFiles artworkFiles;
  late final ArtworkRepo artwork;
  late final LoginRateLimiter limiter;
  late final ScrapeService scrapes;

  final watcher = LibraryWatcher();
  StreamSubscription<RootLibraryChange>? _watchSub;
  final _watchedPath = <String, String>{};
  var _scanAgain = false;
  bool _closed = false;

  void _onScanFinished() {
    if (_closed) return;
    _syncWatches();
    scrapes.start();
    if (!_scanAgain) return;
    _scanAgain = false;
    if (!scans.start()) _scanAgain = true;
  }

  void _syncWatches() {
    final live = <String>{};
    for (final root in roots.all()) {
      if (root.status != LibraryRootStatus.online) continue;
      live.add(root.id);
      if (_watchedPath[root.id] == root.lastPath) continue;
      try {
        watcher.watch(rootId: root.id, path: root.lastPath);
        _watchedPath[root.id] = root.lastPath;
      } on FileSystemException catch (e) {
        _log.warning('Not watching "${root.label}": $e');
      }
    }
    for (final id in _watchedPath.keys.toList()) {
      if (live.contains(id)) continue;
      watcher.unwatch(id);
      _watchedPath.remove(id);
    }
  }

  /// Stops the scan, the scrape and the root watcher, then closes the database.
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _watchSub?.cancel();
    await watcher.close();
    await scans.shutdown();
    await scrapes.shutdown();
    db.close();
  }
}
