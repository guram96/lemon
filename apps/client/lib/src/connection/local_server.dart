import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'local_server_stub.dart'
    if (dart.library.io) 'local_server_io.dart'
    as local_io;

/// Starts the Retro Steam server that ships inside the macOS app.
///
/// [start] returns true when a process was launched. It returns false when
/// this platform has no bundled server, or when `rs_server` is not next to
/// the client (a `flutter run` build, or a test). A false result must not
/// spawn a process.
abstract interface class LocalServer {
  Future<bool> start();
}

/// Host implementation. On the web this never starts a process.
LocalServer openLocalServer() => local_io.openLocalServer();

/// Server bundled with this app. Override in tests.
///
/// The default is a no-op when `rs_server` is not next to this process, so a
/// fake API client in tests is never paired with a real spawn.
final localServerProvider = Provider<LocalServer>((ref) => openLocalServer());
