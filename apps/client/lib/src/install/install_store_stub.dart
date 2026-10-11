import 'install_models.dart';
import 'install_store.dart';

/// Web stand-in. The install store needs a filesystem.
InstallStore openInstallStore(Object? _) => const _UnsupportedInstallStore();

String? resolveInstallFile({
  required String folder,
  required String systemId,
  required String relativePath,
}) => _unsupported();

class _UnsupportedInstallStore implements InstallStore {
  const _UnsupportedInstallStore();

  @override
  Future<InstallDestination> readDestinations() async => _unsupported();

  @override
  Future<void> writeDestinations(InstallDestination destinations) async =>
      _unsupported();

  @override
  Future<void> put(InstallRecord record) async => _unsupported();

  @override
  Future<void> remove(String serverId, String gameId) async => _unsupported();

  @override
  Future<List<InstallRecord>> installs(String serverId) async => _unsupported();

  @override
  Future<List<String>> uninstall(InstallRecord record) async => _unsupported();
}

Never _unsupported() => throw UnsupportedError(
  'InstallStore is unavailable where dart:io is missing',
);
