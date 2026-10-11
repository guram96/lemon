import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rs_api_client/rs_api_client.dart';
import 'package:rs_core/rs_core.dart';

import '../connection/connection_provider.dart';
import '../storage/credential_store.dart';

/// The user logged in on this device, or `null`.
///
/// Restored by [connectionProvider] at startup. Any `401` from a call made
/// with the session (and a `4401` close of the event stream) clears it, which
/// sends the router to the login page.
final sessionProvider = NotifierProvider<SessionNotifier, User?>(
  SessionNotifier.new,
);

class SessionNotifier extends Notifier<User?> {
  @override
  User? build() => null;

  bool get isAdmin => state?.role == UserRole.admin;

  /// Logs in on the active server. Throws [ApiException] on failure (for
  /// example `401 invalid_credentials` or `429 rate_limited`).
  Future<User> login(String username, String password) async {
    final result = await ref.read(apiClientProvider).login(username, password);
    await adoptAuthResult(result);
    return result.user;
  }

  /// Takes over credentials from `POST /setup` or `POST /auth/login`: stores
  /// the device token (when present) and session token, sets them on the API
  /// client, and logs the user in.
  ///
  /// After setup this also marks the server configured, so the router moves
  /// from `/setup` to `/setup/done`.
  Future<void> adoptAuthResult(AuthResult result) async {
    final client = ref.read(apiClientProvider);
    final store = ref.read(credentialStoreProvider);
    final creds = await store.load();
    if (result.deviceToken case final token?) client.deviceToken = token;
    client.sessionToken = result.sessionToken;
    await store.save(
      creds.copyWith(
        serverUri: client.baseUri,
        serverId: ref.read(serverInfoProvider)?.serverId,
        deviceToken: result.deviceToken,
        sessionToken: result.sessionToken,
        user: result.user,
      ),
    );
    if (!ref.mounted) return;
    state = result.user;
    final connection = ref.read(connectionProvider);
    if (connection.status == ConnectionStatus.unconfigured) {
      ref.read(connectionProvider.notifier).markConfigured();
    }
  }

  /// Ends the session on the server (best effort) and locally.
  Future<void> logout() async {
    final client = ref.read(apiClientProvider);
    if (client.sessionToken != null) {
      try {
        await client.logout();
      } on Object {
        // Logged out locally either way.
      }
    }
    await _clear();
  }

  /// The server rejected the session: forget it locally.
  Future<void> handleUnauthorized() async {
    final client = ref.read(apiClientProvider);
    if (state == null && client.sessionToken == null) return;
    await _clear();
  }

  /// Clears the session when [error] is a `401` [ApiException]. Returns
  /// whether it did. For screens that catch API errors themselves.
  bool handleApiError(Object error) {
    if (error is ApiException && error.statusCode == 401) {
      handleUnauthorized();
      return true;
    }
    return false;
  }

  /// Used by [ConnectionNotifier] after it validated stored credentials.
  void restore(User? user) => state = user;

  Future<void> _clear() async {
    ref.read(apiClientProvider).sessionToken = null;
    state = null;
    await ref.read(credentialStoreProvider).clearSession();
  }
}
