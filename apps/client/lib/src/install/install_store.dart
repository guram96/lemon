import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'install_models.dart';
import 'install_store_stub.dart'
    if (dart.library.io) 'install_store_io.dart'
    as install_io;

/// Name of the JSON file inside the directory passed to [openInstallStore].
const installStoreFileName = 'installs.json';

/// Device-local installs and destination folders. Not the server API.
///
/// Records are keyed by [InstallRecord.serverId] and [InstallRecord.gameId].
abstract interface class InstallStore {
  Future<InstallDestination> readDestinations();

  Future<void> writeDestinations(InstallDestination destinations);

  /// Inserts [record], replacing any record with the same identity.
  Future<void> put(InstallRecord record);

  /// Drops the record for [serverId] and [gameId]. Missing is success.
  Future<void> remove(String serverId, String gameId);

  /// Records for [serverId] only, ordered by game id.
  /// Equal game ids keep their previous order.
  Future<List<InstallRecord>> installs(String serverId);

  /// Deletes [record]'s files when each path stays inside
  /// `destinations.folderFor(record.systemId)`, then removes the record.
  ///
  /// A missing file counts as deleted. An absolute path, an empty segment,
  /// `..`, or a lexically normalized path outside that folder is left on disk
  /// and returned. Symlinks are not resolved. When no folder is set, every
  /// file is skipped and the record is still removed.
  Future<List<String>> uninstall(InstallRecord record);
}

/// Store backed by [directory].
///
/// On IO, [directory] is a `Directory` (`dart:io`). Null uses the platform
/// default. On the web, the returned store throws [UnsupportedError].
InstallStore openInstallStore(Object? directory) =>
    install_io.openInstallStore(directory);

/// Lexical path of [folder]/[systemId]/[relativePath], or null when that
/// path must not be written or deleted.
///
/// Rejects an absolute [relativePath], an empty segment, and `..`. Does not
/// resolve symlinks. Null unless the result is strictly inside [folder].
/// On the web this throws [UnsupportedError].
String? resolveInstallFile({
  required String folder,
  required String systemId,
  required String relativePath,
}) => install_io.resolveInstallFile(
  folder: folder,
  systemId: systemId,
  relativePath: relativePath,
);

/// Directory that holds [installStoreFileName].
///
/// Override with a `Directory` in tests. Null selects the platform default
/// (`~/Library/Application Support/retro_steam` on macOS, and the equivalent
/// data directory on Linux and Windows).
final installDirectoryProvider = Provider<Object?>((ref) => null);

/// Install store for the app. Override in tests, or override
/// [installDirectoryProvider] with a temp directory.
final installStoreProvider = Provider<InstallStore>(
  (ref) => openInstallStore(ref.watch(installDirectoryProvider)),
);

/// Destination folders, loaded from [installStoreProvider].
final destinationsProvider =
    AsyncNotifierProvider<DestinationsNotifier, InstallDestination>(
      DestinationsNotifier.new,
    );

/// Reads and writes the destination section of the install store.
class DestinationsNotifier extends AsyncNotifier<InstallDestination> {
  @override
  Future<InstallDestination> build() =>
      ref.watch(installStoreProvider).readDestinations();

  Future<void> save(InstallDestination destinations) async {
    await ref.read(installStoreProvider).writeDestinations(destinations);
    if (!ref.mounted) return;
    state = AsyncData(destinations);
  }

  Future<void> setGlobalFolder(String? folder) async {
    final current = await future;
    await save(current.withGlobalFolder(folder));
  }

  /// Sets one system's folder. Null clears the override.
  Future<void> setSystemFolder(String systemId, String? folder) async {
    final current = await future;
    await save(current.withSystemFolder(systemId, folder));
  }
}
