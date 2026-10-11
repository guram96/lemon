import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../install/install_store.dart';
import 'launch_models.dart';
import 'launch_store_stub.dart'
    if (dart.library.io) 'launch_store_io.dart'
    as launch_io;

/// Name of the JSON file inside the directory passed to [openLaunchStore].
const launchStoreFileName = 'launch.json';

/// Device-local launch choices. Not the server API.
///
/// System choices are keyed by EmulationStation system id. Game choices are
/// keyed by server id and game id. [LaunchOptions.resolve] prefers the game.
abstract interface class LaunchStore {
  /// Current options. A missing or empty file is empty options.
  ///
  /// Malformed JSON throws [FormatException].
  Future<LaunchOptions> read();

  /// Inserts [choice] for [systemId], replacing any previous choice.
  Future<void> putSystem(String systemId, LaunchChoice choice);

  /// Drops the choice for [systemId]. Missing is success.
  Future<void> removeSystem(String systemId);

  /// Inserts [choice] for [serverId] and [gameId], replacing any previous one.
  Future<void> putGame(String serverId, String gameId, LaunchChoice choice);

  /// Drops the choice for [serverId] and [gameId]. Missing is success.
  Future<void> removeGame(String serverId, String gameId);
}

/// Store backed by [directory].
///
/// On IO, [directory] is a `Directory` (`dart:io`). Null uses the platform
/// default, the same folder as the install store. On the web, the returned
/// store throws [UnsupportedError] when used.
LaunchStore openLaunchStore(Object? directory) =>
    launch_io.openLaunchStore(directory);

/// Directory that holds [launchStoreFileName].
///
/// Defaults to [installDirectoryProvider]. Override with a `Directory` in
/// tests. Null selects the platform default.
final launchDirectoryProvider = Provider<Object?>(
  (ref) => ref.watch(installDirectoryProvider),
);

/// Launch store for the app. Override in tests, or override
/// [launchDirectoryProvider] with a temp directory.
final launchStoreProvider = Provider<LaunchStore>(
  (ref) => openLaunchStore(ref.watch(launchDirectoryProvider)),
);

/// Launch choices, loaded from [launchStoreProvider].
final launchOptionsProvider =
    AsyncNotifierProvider<LaunchOptionsNotifier, LaunchOptions>(
      LaunchOptionsNotifier.new,
    );

/// Reads and writes device-local launch choices.
class LaunchOptionsNotifier extends AsyncNotifier<LaunchOptions> {
  @override
  Future<LaunchOptions> build() => ref.watch(launchStoreProvider).read();

  Future<void> setSystem(String systemId, LaunchChoice choice) async {
    final current = await future;
    await ref.read(launchStoreProvider).putSystem(systemId, choice);
    if (!ref.mounted) return;
    state = AsyncData(current.withSystem(systemId, choice));
  }

  Future<void> clearSystem(String systemId) async {
    final current = await future;
    await ref.read(launchStoreProvider).removeSystem(systemId);
    if (!ref.mounted) return;
    state = AsyncData(current.withoutSystem(systemId));
  }

  Future<void> setGame(
    String serverId,
    String gameId,
    LaunchChoice choice,
  ) async {
    final current = await future;
    await ref.read(launchStoreProvider).putGame(serverId, gameId, choice);
    if (!ref.mounted) return;
    state = AsyncData(current.withGame(serverId, gameId, choice));
  }

  Future<void> clearGame(String serverId, String gameId) async {
    final current = await future;
    await ref.read(launchStoreProvider).removeGame(serverId, gameId);
    if (!ref.mounted) return;
    state = AsyncData(current.withoutGame(serverId, gameId));
  }
}
