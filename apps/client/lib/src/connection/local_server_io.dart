import 'dart:io';

import 'local_server.dart';

/// macOS implementation. Other IO platforms do not start a server.
LocalServer openLocalServer() => const IoLocalServer();

/// Spawns `rs_server` next to this executable and does not wait for it.
///
/// The process is detached. Quitting the client does not stop it, and
/// disposing the provider does not kill it.
class IoLocalServer implements LocalServer {
  const IoLocalServer();

  @override
  Future<bool> start() async {
    if (!Platform.isMacOS) return false;
    final executable = bundledServerPath(Platform.resolvedExecutable);
    if (!File(executable).existsSync()) return false;
    await Process.start(
      executable,
      const <String>[],
      mode: ProcessStartMode.detached,
      runInShell: false,
    );
    return true;
  }
}

/// `rs_server` beside [clientExecutable].
///
/// In the app bundle that is `Contents/MacOS/rs_server`, next to the Flutter
/// binary `Contents/MacOS/retro_steam`.
String bundledServerPath(String clientExecutable) {
  final separator = Platform.pathSeparator;
  final slash = clientExecutable.lastIndexOf(separator);
  final directory = slash == -1 ? '' : clientExecutable.substring(0, slash + 1);
  return '${directory}rs_server';
}
