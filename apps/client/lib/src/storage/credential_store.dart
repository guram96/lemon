import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rs_core/rs_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What the client remembers about its server between launches.
@immutable
class StoredCredentials {
  const StoredCredentials({
    this.serverUri,
    this.serverId,
    this.deviceToken,
    this.sessionToken,
    this.user,
  });

  static const empty = StoredCredentials();

  /// Base URI of the last server, for example `http://192.168.1.10:47320`.
  final Uri? serverUri;
  final String? serverId;

  /// Proves this device joined [serverId].
  final String? deviceToken;

  /// Logged-in user's session on this device.
  final String? sessionToken;

  /// Last known user for [sessionToken].
  final User? user;

  StoredCredentials copyWith({
    Uri? serverUri,
    String? serverId,
    String? deviceToken,
    String? sessionToken,
    User? user,
  }) => StoredCredentials(
    serverUri: serverUri ?? this.serverUri,
    serverId: serverId ?? this.serverId,
    deviceToken: deviceToken ?? this.deviceToken,
    sessionToken: sessionToken ?? this.sessionToken,
    user: user ?? this.user,
  );

  /// Same server and device, nobody logged in.
  StoredCredentials withoutSession() => StoredCredentials(
    serverUri: serverUri,
    serverId: serverId,
    deviceToken: deviceToken,
  );

  @override
  bool operator ==(Object other) =>
      other is StoredCredentials &&
      other.serverUri == serverUri &&
      other.serverId == serverId &&
      other.deviceToken == deviceToken &&
      other.sessionToken == sessionToken &&
      other.user == user;

  @override
  int get hashCode =>
      Object.hash(serverUri, serverId, deviceToken, sessionToken, user);

  @override
  String toString() =>
      'StoredCredentials(server: $serverUri, id: $serverId, '
      'device: ${deviceToken != null}, session: ${sessionToken != null}, '
      'user: ${user?.username})';
}

/// Persists [StoredCredentials].
///
/// Backed by shared_preferences for now. Tokens should move to secure storage
/// (Keychain / Keystore) later; only this interface's implementation changes.
abstract interface class CredentialStore {
  Future<StoredCredentials> load();

  /// Replaces everything stored with [credentials].
  Future<void> save(StoredCredentials credentials);

  /// Forgets the session token and user only (device stays joined).
  Future<void> clearSession();

  /// Forgets everything.
  Future<void> clear();
}

/// [CredentialStore] used by the app. Override in tests with
/// [InMemoryCredentialStore].
final credentialStoreProvider = Provider<CredentialStore>(
  (_) => SharedPreferencesCredentialStore(),
);

class InMemoryCredentialStore implements CredentialStore {
  InMemoryCredentialStore([this.credentials = StoredCredentials.empty]);

  StoredCredentials credentials;

  @override
  Future<StoredCredentials> load() async => credentials;

  @override
  Future<void> save(StoredCredentials credentials) async =>
      this.credentials = credentials;

  @override
  Future<void> clearSession() async =>
      credentials = credentials.withoutSession();

  @override
  Future<void> clear() async => credentials = StoredCredentials.empty;
}

class SharedPreferencesCredentialStore implements CredentialStore {
  SharedPreferencesCredentialStore({SharedPreferencesAsync? preferences})
    : _prefs = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _prefs;

  static const _serverUri = 'rs.server.uri';
  static const _serverId = 'rs.server.id';
  static const _deviceToken = 'rs.device.token';
  static const _sessionToken = 'rs.session.token';
  static const _user = 'rs.session.user';
  static const _all = {
    _serverUri,
    _serverId,
    _deviceToken,
    _sessionToken,
    _user,
  };

  @override
  Future<StoredCredentials> load() async {
    final values = await _prefs.getAll(allowList: _all);
    String? read(String key) => switch (values[key]) {
      final String s when s.isNotEmpty => s,
      _ => null,
    };
    return StoredCredentials(
      serverUri: switch (read(_serverUri)) {
        final s? => Uri.tryParse(s),
        null => null,
      },
      serverId: read(_serverId),
      deviceToken: read(_deviceToken),
      sessionToken: read(_sessionToken),
      user: _decodeUser(read(_user)),
    );
  }

  @override
  Future<void> save(StoredCredentials c) async {
    await _write(_serverUri, c.serverUri?.toString());
    await _write(_serverId, c.serverId);
    await _write(_deviceToken, c.deviceToken);
    await _write(_sessionToken, c.sessionToken);
    await _write(_user, c.user == null ? null : jsonEncode(c.user!.toJson()));
  }

  @override
  Future<void> clearSession() async {
    await _prefs.remove(_sessionToken);
    await _prefs.remove(_user);
  }

  @override
  Future<void> clear() => _prefs.clear(allowList: _all);

  Future<void> _write(String key, String? value) =>
      value == null ? _prefs.remove(key) : _prefs.setString(key, value);

  static User? _decodeUser(String? json) {
    if (json == null) return null;
    try {
      final map = jsonDecode(json);
      return map is Map<String, Object?> ? User.fromJson(map) : null;
    } on Object {
      return null;
    }
  }
}
