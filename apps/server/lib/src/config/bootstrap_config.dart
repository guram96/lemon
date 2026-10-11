import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:rs_core/rs_core.dart';
import 'package:uuid/uuid.dart';

/// The tiny machine-local config that tells the server where everything else is.
///
/// Lives in the OS app-config directory. Everything heavy (database, artwork)
/// lives in [dataDir], which can be on any drive and moved between machines.
class BootstrapConfig {
  BootstrapConfig({
    required this.serverId,
    this.port = Discovery.defaultPort,
    this.bindAddress = '0.0.0.0',
    this.dataDir,
  });

  factory BootstrapConfig.fromJson(Map<String, Object?> json) =>
      BootstrapConfig(
        serverId: json['serverId']! as String,
        port: (json['port'] as int?) ?? Discovery.defaultPort,
        bindAddress: (json['bindAddress'] as String?) ?? '0.0.0.0',
        dataDir: json['dataDir'] as String?,
      );

  final String serverId;
  final int port;
  final String bindAddress;

  /// Absolute path to the data directory. `null` until first-run setup.
  final String? dataDir;

  bool get isConfigured => dataDir != null;

  Map<String, Object?> toJson() => {
    'serverId': serverId,
    'port': port,
    'bindAddress': bindAddress,
    'dataDir': ?dataDir,
  };

  /// Loads the config from [file], creating it with a fresh server ID if missing.
  static Future<BootstrapConfig> loadOrCreate(File file) async {
    if (await file.exists()) {
      final json = jsonDecode(await file.readAsString());
      return BootstrapConfig.fromJson(json as Map<String, Object?>);
    }
    final config = BootstrapConfig(serverId: const Uuid().v4());
    await config.save(file);
    return config;
  }

  Future<void> save(File file) async {
    await file.parent.create(recursive: true);
    // Write-then-rename so a crash never leaves a half-written config.
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(
      const JsonEncoder.withIndent('  ').convert(toJson()),
      flush: true,
    );
    await tmp.rename(file.path);
  }

  /// Default config location for the current OS.
  static File defaultFile() {
    final env = Platform.environment;
    final String dir;
    if (Platform.isMacOS) {
      dir = p.join(
        env['HOME']!,
        'Library',
        'Application Support',
        'RetroSteam',
      );
    } else if (Platform.isWindows) {
      dir = p.join(env['APPDATA']!, 'RetroSteam');
    } else {
      final xdg = env['XDG_CONFIG_HOME'];
      dir = xdg != null && xdg.isNotEmpty
          ? p.join(xdg, 'retrosteam')
          : p.join(env['HOME']!, '.config', 'retrosteam');
    }
    return File(p.join(dir, 'server.json'));
  }
}
