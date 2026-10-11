import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:rs_core/rs_core.dart';

import '../config/bootstrap_config.dart';
import '../db/db.dart';
import '../fs/fs.dart';
import '../http/api_failure.dart';
import '../security/security.dart';
import '../server_context.dart';
import '../storage/storage.dart';
import 'configured_server.dart';
import 'mappers.dart';

final _log = Logger('setup');

const maxUsernameLength = 64;
const maxDeviceNameLength = 100;
const maxPlatformLength = 20;

/// Trims and validates a device name / platform from a join request.
(String, String) validateDeviceInfo(String name, String platform) {
  final n = name.trim();
  final pl = platform.trim().toLowerCase();
  if (n.isEmpty || n.length > maxDeviceNameLength || _hasControl(n)) {
    throw const ApiFailure.badRequest('Invalid device name.');
  }
  if (pl.isEmpty || pl.length > maxPlatformLength || _hasControl(pl)) {
    throw const ApiFailure.badRequest('Invalid platform.');
  }
  return (n, pl);
}

bool _hasControl(String s) => s.codeUnits.any((c) => c < 0x20 || c == 0x7f);

/// First-run setup (`POST /setup`).
///
/// Validates everything before writing anything. Writes happen in this
/// order: data directory + marker, database, library root markers, then one
/// transaction for admin, roots, devices and session, then the bootstrap
/// config. A failure before the config is saved leaves the server
/// unconfigured; a retry adopts the data directory (and, if the transaction
/// committed, requires the same admin credentials).
class SetupService {
  SetupService(this._ctx, {this._probe = const PathProbe()});

  final ServerContext _ctx;
  final PathProbe _probe;

  Future<AuthResult> run(
    SetupRequest request, {
    String? callerDeviceTokenHash,
  }) async {
    final username = request.adminUsername.trim();
    if (username.isEmpty ||
        username.length > maxUsernameLength ||
        _hasControl(username)) {
      throw const ApiFailure.badRequest('Enter a valid admin username.');
    }
    final password = request.adminPassword;
    if (password.length < SetupRequest.minPasswordLength) {
      throw const ApiFailure.badRequest(
        'The admin password must have at least '
        '${SetupRequest.minPasswordLength} characters.',
      );
    }
    if (password.length > PasswordHasher.maxPasswordLength) {
      throw const ApiFailure.badRequest('The admin password is too long.');
    }
    if (request.libraryRoots.isEmpty) {
      throw const ApiFailure.badRequest(
        'Add at least one game library folder.',
      );
    }
    var deviceName = request.deviceName.trim();
    if (deviceName.isEmpty || _hasControl(deviceName)) {
      deviceName = 'Server computer';
    }
    if (deviceName.length > maxDeviceNameLength) {
      deviceName = deviceName.substring(0, maxDeviceNameLength);
    }

    // --- Validate paths (no writes yet) ------------------------------------
    final dataProbe = await _probe.check(request.dataDir, ProbeKind.dataDir);
    if (!dataProbe.ok) {
      throw ApiFailure.pathInvalid(_describe('Data folder', dataProbe));
    }
    final rootPaths = <String>[];
    for (final input in request.libraryRoots) {
      final probe = await _probe.check(input, ProbeKind.libraryRoot);
      if (!probe.ok) {
        throw ApiFailure.pathInvalid(_describe('Library folder', probe));
      }
      if (p.equals(probe.path, dataProbe.path)) {
        throw const ApiFailure.pathInvalid(
          'The data folder and a game library folder must be different.',
        );
      }
      if (!rootPaths.any((r) => p.equals(r, probe.path))) {
        rootPaths.add(probe.path);
      }
    }

    final passwordHash = await _ctx.hasher.hash(password);

    // --- Write ---------------------------------------------------------------
    final dataDir = await DataDir.openOrCreate(dataProbe.path);
    final db = RsDatabase.open(dataDir.dbPath);
    ConfiguredServer? server;
    try {
      final users = UserRepo(db);
      final existingAdmin = users.all().where((u) => u.isAdmin).firstOrNull;
      if (existingAdmin != null) {
        // Adopting a data folder that already has an admin: only with the
        // same credentials.
        final same =
            existingAdmin.username.toLowerCase() == username.toLowerCase() &&
            await _ctx.hasher.verify(password, existingAdmin.passwordHash);
        if (!same) {
          throw const ApiFailure.conflict(
            'This data folder already belongs to a Retro Steam server. Enter '
            'its admin username and password to use it, or pick another '
            'folder.',
          );
        }
      }

      final registrations = <RootRegistration>[];
      for (final path in rootPaths) {
        registrations.add(await const LibraryRoots().register(path));
      }

      final deviceToken = Tokens.generate();
      final sessionToken = Tokens.generate();
      final pending = [
        for (final d in _ctx.pendingDevices)
          if (d.tokenHash != callerDeviceTokenHash) d,
      ];
      final (admin, device) = db.transaction(() {
        final admin =
            existingAdmin ??
            users.create(
              username: username,
              role: UserRole.admin,
              passwordHash: passwordHash,
            );
        final roots = RootRepo(db);
        for (final r in registrations) {
          roots.upsert(
            id: r.id,
            label: r.label,
            lastPath: r.path,
            status: r.status,
          );
        }
        final devices = DeviceRepo(db);
        for (final d in pending) {
          final created = devices.create(
            name: d.name,
            platform: d.platform,
            tokenHash: d.tokenHash,
          );
          // Keep the id the device was given before setup.
          db.db.execute('UPDATE devices SET id = ? WHERE id = ?', [
            d.id,
            created.id,
          ]);
        }
        final device = devices.create(
          name: deviceName,
          platform: Platform.operatingSystem,
          tokenHash: Tokens.hash(deviceToken),
        );
        SessionRepo(db).create(
          userId: admin.id,
          deviceId: device.id,
          tokenHash: Tokens.hash(sessionToken),
        );
        return (admin, device);
      });

      server = await ConfiguredServer.attach(
        dataDir: dataDir,
        db: db,
        events: _ctx.events,
        scanner: _ctx.scanner,
        rootSearchDirs: _ctx.rootSearchDirs,
      );
      final config = BootstrapConfig(
        serverId: _ctx.config.serverId,
        port: _ctx.config.port,
        bindAddress: _ctx.config.bindAddress,
        dataDir: dataDir.path,
      );
      final file = _ctx.configFile;
      if (file != null) await config.save(file);

      _ctx.activate(config, server);
      _log.info(
        'Setup complete: data folder ${dataDir.path}'
        '${dataDir.adopted ? ' (adopted)' : ''}, '
        '${registrations.length} library folder(s).',
      );
      server.scans.start();
      return AuthResult(
        sessionToken: sessionToken,
        user: Mappers.user(admin),
        deviceId: device.id,
        deviceToken: deviceToken,
      );
    } on Object {
      if (server != null) {
        await server.close();
      } else {
        db.close();
      }
      rethrow;
    }
  }

  static String _describe(String what, PathProbeResult r) {
    final reasons = r.warnings
        .where((w) => w != PathWarning.willBeCreated)
        .map((w) => w.message);
    return '$what "${r.path}" can not be used.'
        '${reasons.isEmpty ? '' : ' ${reasons.join(' ')}'}';
  }
}
