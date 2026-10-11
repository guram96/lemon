import 'local_server.dart';

/// Web stand-in. The browser cannot start the bundled server.
LocalServer openLocalServer() => const _NoLocalServer();

class _NoLocalServer implements LocalServer {
  const _NoLocalServer();

  @override
  Future<bool> start() async => false;
}
