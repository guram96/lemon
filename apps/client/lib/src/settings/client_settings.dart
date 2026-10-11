import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rs_theme/rs_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../install/install_store.dart';
import '../platform/client_capabilities.dart';
import 'client_settings_store_stub.dart'
    if (dart.library.io) 'client_settings_store_io.dart'
    as file_store;

/// Name of the JSON file next to `installs.json`.
const clientSettingsFileName = 'client_settings.json';

/// Theme and UI-sound preference stored on this device.
@immutable
class ClientSettings {
  const ClientSettings({
    this.theme = const RsThemeSettings(),
    this.uiSounds = true,
  });

  final RsThemeSettings theme;

  /// When false, interface cues stay silent. Nothing plays them yet.
  final bool uiSounds;

  ClientSettings copyWith({RsThemeSettings? theme, bool? uiSounds}) =>
      ClientSettings(
        theme: theme ?? this.theme,
        uiSounds: uiSounds ?? this.uiSounds,
      );

  Map<String, Object?> toJson() => {
    'theme': theme.toJson(),
    'uiSounds': uiSounds,
  };

  factory ClientSettings.fromJson(Map<String, Object?> json) {
    final rawTheme = json['theme'];
    final theme = rawTheme is Map
        ? RsThemeSettings.fromJson(Map<String, Object?>.from(rawTheme))
        : const RsThemeSettings();
    final sounds = json['uiSounds'];
    return ClientSettings(
      theme: theme,
      uiSounds: sounds is bool ? sounds : true,
    );
  }

  /// Decodes [text]. Invalid JSON, or a value that is not an object, is
  /// [ClientSettings] defaults.
  static ClientSettings parse(String text) {
    try {
      final decoded = jsonDecode(text);
      if (decoded is! Map) return const ClientSettings();
      return ClientSettings.fromJson(Map<String, Object?>.from(decoded));
    } on Object {
      return const ClientSettings();
    }
  }

  @override
  bool operator ==(Object other) =>
      other is ClientSettings &&
      other.theme == theme &&
      other.uiSounds == uiSounds;

  @override
  int get hashCode => Object.hash(theme, uiSounds);

  @override
  String toString() => 'ClientSettings(theme: $theme, uiSounds: $uiSounds)';
}

/// Persists [ClientSettings] across launches.
abstract interface class ClientSettingsStore {
  Future<ClientSettings> load();

  Future<void> save(ClientSettings settings);
}

/// Store used by tests. The app uses a file or shared preferences.
class InMemoryClientSettingsStore implements ClientSettingsStore {
  InMemoryClientSettingsStore([this.settings = const ClientSettings()]);

  ClientSettings settings;

  @override
  Future<ClientSettings> load() async => settings;

  @override
  Future<void> save(ClientSettings settings) async {
    this.settings = settings;
  }
}

/// Web store. The file store needs a filesystem, which the browser does not
/// have, so shared preferences holds one JSON string.
class SharedPreferencesClientSettingsStore implements ClientSettingsStore {
  SharedPreferencesClientSettingsStore({SharedPreferencesAsync? preferences})
    : _prefs = preferences ?? SharedPreferencesAsync();

  static const key = 'rs.client.settings';

  final SharedPreferencesAsync _prefs;

  @override
  Future<ClientSettings> load() async {
    try {
      final raw = await _prefs.getString(key);
      if (raw == null || raw.trim().isEmpty) return const ClientSettings();
      return ClientSettings.parse(raw);
    } on Object {
      return const ClientSettings();
    }
  }

  @override
  Future<void> save(ClientSettings settings) =>
      _prefs.setString(key, jsonEncode(settings.toJson()));
}

/// File-backed store. On the web the returned store throws when used; the
/// provider below picks [SharedPreferencesClientSettingsStore] instead.
ClientSettingsStore openClientSettingsStore(Object? directory) =>
    file_store.openClientSettingsStore(directory);

/// Shared preferences when the plugin is registered. Widget tests that only
/// pretend to be web have no plugin, so they keep the defaults in memory.
ClientSettingsStore _webStore() {
  try {
    return SharedPreferencesClientSettingsStore();
  } on Object {
    return InMemoryClientSettingsStore();
  }
}

/// Store for this process. Tests override it.
///
/// Web has no install directory, so it uses shared preferences. Every other
/// platform writes [clientSettingsFileName] beside `installs.json`.
final clientSettingsStoreProvider = Provider<ClientSettingsStore>((ref) {
  final platform = ref.watch(
    clientCapabilitiesProvider.select((caps) => caps.platform),
  );
  if (platform == 'web') return _webStore();
  return openClientSettingsStore(ref.watch(installDirectoryProvider));
});

/// Loaded client settings. Starts as defaults, then replaces them with
/// [clientSettingsStoreProvider].
final clientSettingsProvider =
    NotifierProvider<ClientSettingsNotifier, ClientSettings>(
      ClientSettingsNotifier.new,
    );

class ClientSettingsNotifier extends Notifier<ClientSettings> {
  int _ticket = 0;
  Future<void> _writes = Future<void>.value();
  Completer<void>? _ready;

  /// Completes when the current load from the store has been applied.
  Future<void> get ready => _ready?.future ?? Future<void>.value();

  /// Completes when the latest save has finished.
  Future<void> get persisted => _writes;

  @override
  ClientSettings build() {
    final store = ref.watch(clientSettingsStoreProvider);
    final ticket = ++_ticket;
    final done = Completer<void>();
    _ready = done;
    unawaited(_hydrate(store, ticket, done));
    ref.onDispose(() {
      _ticket++;
      if (!done.isCompleted) done.complete();
    });
    return const ClientSettings();
  }

  Future<void> _hydrate(
    ClientSettingsStore store,
    int ticket,
    Completer<void> done,
  ) async {
    var loaded = const ClientSettings();
    try {
      loaded = await store.load();
    } on Object {
      loaded = const ClientSettings();
    }
    if (ref.mounted && ticket == _ticket) state = loaded;
    if (!done.isCompleted) done.complete();
  }

  Future<void> setTheme(RsThemeSettings theme) =>
      _update((current) => current.copyWith(theme: theme));

  Future<void> setUiSounds(bool uiSounds) =>
      _update((current) => current.copyWith(uiSounds: uiSounds));

  Future<void> _update(ClientSettings Function(ClientSettings current) change) {
    final store = ref.read(clientSettingsStoreProvider);
    final pending = _writes.then((_) async {
      final ready = _ready?.future;
      if (ready != null) await ready;
      if (!ref.mounted) return;
      state = change(state);
      try {
        await store.save(state);
      } on Object {
        // The in-memory value stays. The next edit writes again.
      }
    });
    _writes = pending.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return pending;
  }
}

/// Whether interface cues are enabled. Default on. Playback is later.
final uiSoundsProvider = NotifierProvider<UiSoundsNotifier, bool>(
  UiSoundsNotifier.new,
);

class UiSoundsNotifier extends Notifier<bool> {
  @override
  bool build() =>
      ref.watch(clientSettingsProvider.select((settings) => settings.uiSounds));

  Future<void> setEnabled(bool enabled) =>
      ref.read(clientSettingsProvider.notifier).setUiSounds(enabled);
}
