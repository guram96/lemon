import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:logging/logging.dart';
import 'package:rs_core/rs_core.dart';
import 'package:rs_server/rs_server.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addOption('config', help: 'Path to the bootstrap config file.')
    ..addOption('port', help: 'Override the configured port.')
    ..addOption(
      'bind',
      help: 'Override the configured bind address (e.g. 127.0.0.1).',
    )
    ..addFlag('verbose', abbr: 'v', help: 'Log every request.')
    ..addFlag('help', abbr: 'h', negatable: false);

  final ArgResults options;
  try {
    options = parser.parse(args);
  } on FormatException catch (e) {
    stderr.writeln('${e.message}\n\n${parser.usage}');
    exit(64);
  }
  if (options.flag('help')) {
    stdout.writeln('Usage: rs_server [options]\n\n${parser.usage}');
    return;
  }

  Logger.root.level = options.flag('verbose') ? Level.ALL : Level.INFO;
  Logger.root.onRecord.listen((r) {
    stdout.writeln(
      '${r.time.toIso8601String()} ${r.level.name} ${r.loggerName}: ${r.message}',
    );
    if (r.error != null) stdout.writeln('  ${r.error}\n${r.stackTrace ?? ''}');
  });
  final log = Logger('server');

  final portOption = options.option('port');
  final portOverride = portOption == null ? null : int.tryParse(portOption);
  if (portOption != null &&
      (portOverride == null || portOverride < 0 || portOverride > 65535)) {
    stderr.writeln('Invalid --port "$portOption".');
    exit(64);
  }

  final configPath = options.option('config');
  final configFile = configPath != null
      ? File(configPath)
      : BootstrapConfig.defaultFile();
  final config = await BootstrapConfig.loadOrCreate(configFile);
  final port = portOverride ?? config.port;
  final bind = options.option('bind') ?? config.bindAddress;

  final ctx = ServerContext(
    config: config,
    name: Platform.localHostname,
    configFile: configFile,
  );
  try {
    await ctx.start();
  } on Object catch (e) {
    log.severe(
      'Cannot open the data folder ${config.dataDir}: $e\n'
      'Is its drive connected? Fix the path in ${configFile.path} or '
      'reconnect the drive, then start the server again.',
    );
    exit(1);
  }

  final HttpServer server;
  try {
    server = await shelf_io.serve(buildApp(ctx), bind, port);
  } on SocketException catch (e) {
    log.severe('Cannot listen on $bind:$port: ${e.message}');
    await ctx.close();
    exit(1);
  }

  log.info('Retro Steam server $serverVersion');
  log.info('Config: ${configFile.path}');
  for (final url in await _urls(server)) {
    log.info('Listening on $url${ApiRoutes.base}');
  }
  if (!ctx.isConfigured) {
    log.info(
      'Server is not set up yet. Open the Retro Steam client on this machine '
      'to finish setup.',
    );
  }

  // Shut down cleanly on Ctrl+C / SIGTERM.
  final signals = [
    ProcessSignal.sigint.watch(),
    if (!Platform.isWindows) ProcessSignal.sigterm.watch(),
  ];
  await Future.any(signals.map((s) => s.first));
  log.info('Shutting down…');
  await ctx.events.close();
  await server.close(force: true);
  await ctx.close();
  exit(0);
}

/// Human-friendly URLs for the bound address.
Future<List<String>> _urls(HttpServer server) async {
  final port = server.port;
  final address = server.address;
  if (!address.isAnyLocal()) return ['http://${_host(address)}:$port'];
  final urls = ['http://localhost:$port'];
  try {
    for (final nic in await NetworkInterface.list()) {
      for (final a in nic.addresses) {
        if (a.type == InternetAddressType.IPv4 && !a.isLoopback) {
          urls.add('http://${a.address}:$port');
        }
      }
    }
  } on Object {
    // Interface listing is best effort.
  }
  return urls;
}

String _host(InternetAddress a) =>
    a.type == InternetAddressType.IPv6 ? '[${a.address}]' : a.address;

extension on InternetAddress {
  bool isAnyLocal() =>
      address == InternetAddress.anyIPv4.address ||
      address == InternetAddress.anyIPv6.address;
}
