import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:rs_api_client/rs_api_client.dart';
import 'package:rs_core/rs_core.dart';

import '../platform/client_capabilities.dart';
import '../session/session_provider.dart';
import '../storage/credential_store.dart';
import 'server_address.dart';
import 'unauthorized_interceptor.dart';

enum ConnectionStatus {
  /// Probing the saved (or local) server.
  searching,

  /// No server answered, or this device can't join it.
  unreachable,

  /// The server runs but first-run setup hasn't happened.
  unconfigured,

  /// Configured, reachable, and this device joined it.
  ready,
}

/// Where the client is with its server.
@immutable
class ServerConnection {
  const ServerConnection({
    required this.status,
    required this.baseUri,
    required this.client,
    this.info,
    this.error,
  });

  final ConnectionStatus status;
  final Uri baseUri;

  /// API client for [baseUri]. Tokens are set on it once known.
  final RsApiClient client;

  /// Set from the first successful `GET /server`.
  final ServerInfo? info;

  /// Why the server is [ConnectionStatus.unreachable], for the connect page.
  final String? error;

  bool get isLocal => isLoopbackUri(baseUri);

  ServerConnection copyWith({
    ConnectionStatus? status,
    ServerInfo? info,
    String? error,
  }) => ServerConnection(
    status: status ?? this.status,
    baseUri: baseUri,
    client: client,
    info: info ?? this.info,
    error: error,
  );
}

/// Creates the [RsApiClient] for a server address. Override in tests to
/// return a fake.
typedef ApiClientFactory = RsApiClient Function(Uri baseUri);

final apiClientFactoryProvider = Provider<ApiClientFactory>(
  (ref) =>
      (baseUri) => RsApiClient(
        baseUri: baseUri,
        httpClient: UnauthorizedInterceptor(
          http.Client(),
          onUnauthorized: () => scheduleMicrotask(
            () => ref.read(sessionProvider.notifier).handleUnauthorized(),
          ),
        ),
      ),
);

/// Connection to the active server. Starts probing as soon as it is first
/// read.
final connectionProvider =
    NotifierProvider<ConnectionNotifier, ServerConnection>(
      ConnectionNotifier.new,
    );

/// The API client of the active server. Stable for the lifetime of a server
/// address; device and session tokens are kept on it by the shell.
final apiClientProvider = Provider<RsApiClient>(
  (ref) => ref.watch(connectionProvider.select((c) => c.client)),
);

/// Public info of the active server, `null` until it answered.
final serverInfoProvider = Provider<ServerInfo?>(
  (ref) => ref.watch(connectionProvider.select((c) => c.info)),
);

class ConnectionNotifier extends Notifier<ServerConnection> {
  int _attempt = 0;
  final _clients = <Uri, RsApiClient>{};

  @override
  ServerConnection build() {
    ref.onDispose(() {
      for (final c in _clients.values) {
        c.close();
      }
      _clients.clear();
    });
    scheduleMicrotask(_connect);
    return ServerConnection(
      status: ConnectionStatus.searching,
      baseUri: defaultLocalServerUri,
      client: _clientFor(defaultLocalServerUri),
    );
  }

  /// Probes the current address again (Retry on the connect page).
  Future<void> retry() => _connect(address: state.baseUri);

  /// Connects to a manually entered address. On success it becomes the
  /// saved server.
  Future<void> connectTo(Uri address) => _connect(address: address);

  /// Called after first-run setup succeeded: the server is now configured.
  void markConfigured() {
    final info = state.info;
    state = state.copyWith(
      status: ConnectionStatus.ready,
      info: info?.copyWith(setupState: ServerSetupState.ready),
    );
  }

  RsApiClient _clientFor(Uri uri) =>
      _clients.putIfAbsent(uri, () => ref.read(apiClientFactoryProvider)(uri));

  Future<void> _connect({Uri? address}) async {
    final attempt = ++_attempt;
    bool stale() => attempt != _attempt || !ref.mounted;

    final store = ref.read(credentialStoreProvider);
    var creds = await store.load();
    if (stale()) return;

    final uri = address ?? creds.serverUri ?? defaultLocalServerUri;
    final client = _clientFor(uri);
    state = ServerConnection(
      status: ConnectionStatus.searching,
      baseUri: uri,
      client: client,
    );

    try {
      final info = await client.getServerInfo();
      if (stale()) return;

      if (creds.serverId != null && creds.serverId != info.serverId) {
        // A different server: old tokens mean nothing here.
        creds = StoredCredentials.empty;
      }
      creds = creds.copyWith(serverUri: uri, serverId: info.serverId);

      if (info.setupState == ServerSetupState.unconfigured) {
        creds = StoredCredentials(serverUri: uri, serverId: info.serverId);
        client
          ..deviceToken = null
          ..sessionToken = null;
        await store.save(creds);
        if (stale()) return;
        ref.read(sessionProvider.notifier).restore(null);
        state = state.copyWith(
          status: ConnectionStatus.unconfigured,
          info: info,
        );
        return;
      }

      if (creds.deviceToken == null) {
        if (!isLoopbackUri(uri)) {
          // TODO(M5): QR / pairing-token join for other devices.
          state = state.copyWith(
            status: ConnectionStatus.unreachable,
            info: info,
            error:
                'This device has not joined "${info.name}" yet. Pairing '
                'other devices arrives in a later version; for now, run the '
                'client on the server machine.',
          );
          return;
        }
        final caps = ref.read(clientCapabilitiesProvider);
        final joined = await client.joinLocal(
          DeviceJoinRequest(
            deviceName: caps.deviceName,
            platform: caps.platform,
          ),
        );
        if (stale()) return;
        creds = creds.copyWith(deviceToken: joined.deviceToken);
      }

      client
        ..deviceToken = creds.deviceToken
        ..sessionToken = creds.sessionToken;

      User? user;
      if (creds.sessionToken != null) {
        try {
          user = await client.me();
        } on ApiException catch (e) {
          if (e.statusCode == 401) {
            creds = creds.withoutSession();
            client.sessionToken = null;
          } else {
            // Keep the remembered user; the next call will tell.
            user = creds.user;
          }
        }
        if (stale()) return;
      }
      await store.save(
        user == null ? creds.withoutSession() : creds.copyWith(user: user),
      );
      if (stale()) return;

      // Session first, so the router never sees "ready, logged out" on the
      // way to "ready, logged in".
      ref.read(sessionProvider.notifier).restore(user);
      state = state.copyWith(status: ConnectionStatus.ready, info: info);
    } on ApiException catch (e) {
      if (stale()) return;
      state = state.copyWith(
        status: ConnectionStatus.unreachable,
        error: e.isUnreachable
            ? 'No Retro Steam server answered at ${displayAddress(uri)}.'
            : e.error.message,
      );
    } on Object catch (e) {
      if (stale()) return;
      state = state.copyWith(
        status: ConnectionStatus.unreachable,
        error: 'Could not talk to ${displayAddress(uri)}: $e',
      );
    }
  }
}
