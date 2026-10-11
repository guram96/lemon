import 'launch_models.dart';
import 'launch_store.dart';

/// Web stand-in. Launch options need a filesystem.
LaunchStore openLaunchStore(Object? _) => const _UnsupportedLaunchStore();

class _UnsupportedLaunchStore implements LaunchStore {
  const _UnsupportedLaunchStore();

  @override
  Future<LaunchOptions> read() async => _unsupported();

  @override
  Future<void> putSystem(String systemId, LaunchChoice choice) async =>
      _unsupported();

  @override
  Future<void> removeSystem(String systemId) async => _unsupported();

  @override
  Future<void> putGame(
    String serverId,
    String gameId,
    LaunchChoice choice,
  ) async => _unsupported();

  @override
  Future<void> removeGame(String serverId, String gameId) async =>
      _unsupported();
}

Never _unsupported() => throw UnsupportedError(
  'LaunchStore is unavailable where dart:io is missing',
);
