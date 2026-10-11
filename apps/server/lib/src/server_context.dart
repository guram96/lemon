import 'dart:io';

import 'config/bootstrap_config.dart';
import 'fs/directory_browser.dart';
import 'http/api_failure.dart';
import 'scanner/scanner.dart';
import 'security/security.dart';
import 'services/configured_server.dart';
import 'services/event_hub.dart';

/// A device that joined through `POST /devices/local` before setup. Kept in
/// memory and written to the database when setup completes.
class PendingDevice {
  const PendingDevice({
    required this.id,
    required this.name,
    required this.platform,
    required this.tokenHash,
  });

  /// Kept when the device is written to the database.
  final String id;
  final String name;
  final String platform;
  final String tokenHash;
}

/// Long-lived server state shared by request handlers.
///
/// The server is either *unconfigured* ([server] is `null`: only server info,
/// setup and local device join work) or *configured* ([server] holds the open
/// database and services). `POST /setup` switches from the first to the
/// second in-process, through [activate].
class ServerContext {
  ServerContext({
    required this._config,
    required this.name,
    this.configFile,
    this.hasher = const PasswordHasher(),
    this.scanner = const Scanner(),
    this._rootSearchDirs,
    EventHub? events,
  }) : events = events ?? EventHub();

  /// Display name, defaults to the host machine name.
  final String name;

  /// Where [config] is saved after setup. `null` keeps it in memory only.
  final File? configFile;

  /// Password hashing. Tests pass cheap parameters.
  final PasswordHasher hasher;
  final Scanner scanner;
  final EventHub events;
  final List<String>? _rootSearchDirs;

  BootstrapConfig _config;
  ConfiguredServer? _server;

  /// Devices joined locally before setup. Bounded.
  final pendingDevices = <PendingDevice>[];
  static const maxPendingDevices = 16;

  /// Set while `POST /setup` runs, so two setups can't race.
  bool setupInProgress = false;

  late final Future<String> _dummyHash = hasher.hash(
    'retro-steam-timing-equalizer',
  );

  BootstrapConfig get config => _config;

  /// The open data directory and services, or `null` before setup.
  ConfiguredServer? get server => _server;

  bool get isConfigured => _server != null || _config.isConfigured;

  /// Folders searched for library roots mounted under a new path.
  List<String> get rootSearchDirs =>
      _rootSearchDirs ?? DirectoryBrowser().volumeParents;

  /// The configured server, or a `409 setup_required` failure.
  ConfiguredServer requireServer() =>
      _server ?? (throw const ApiFailure.setupRequired());

  /// A password hash used to make logins for unknown users take as long as
  /// real ones.
  Future<String> get dummyPasswordHash => _dummyHash;

  /// Opens the data directory if [config] is already set up. Throws
  /// (`StorageException`, `DatabaseException`, `FileSystemException`) when it
  /// can't be opened, for example when its drive is missing.
  Future<void> start() async {
    final dataDir = _config.dataDir;
    if (dataDir == null || _server != null) return;
    _server = await ConfiguredServer.open(
      dataDir,
      events: events,
      scanner: scanner,
      rootSearchDirs: rootSearchDirs,
    );
  }

  /// Switches to the configured state after a successful setup.
  void activate(BootstrapConfig config, ConfiguredServer server) {
    _config = config;
    _server = server;
    pendingDevices.clear();
  }

  /// Stops scans, closes WebSockets and the database.
  Future<void> close() async {
    await events.close();
    await _server?.close();
  }
}
