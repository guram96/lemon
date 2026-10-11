import 'client_settings.dart';

/// Web stand-in for the file store. Shared preferences is the web store;
/// calling this filesystem path throws.
ClientSettingsStore openClientSettingsStore(Object? _) =>
    const _UnsupportedClientSettingsStore();

class _UnsupportedClientSettingsStore implements ClientSettingsStore {
  const _UnsupportedClientSettingsStore();

  @override
  Future<ClientSettings> load() async => _unsupported();

  @override
  Future<void> save(ClientSettings settings) async => _unsupported();
}

Never _unsupported() => throw UnsupportedError(
  'Client settings files are unavailable where dart:io is missing',
);
