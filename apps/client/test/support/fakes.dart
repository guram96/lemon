import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:rs_api_client/rs_api_client.dart';
import 'package:rs_client/src/connection/connection_provider.dart';
import 'package:rs_client/src/connection/server_address.dart';
import 'package:rs_client/src/platform/client_capabilities.dart';
import 'package:rs_client/src/storage/credential_store.dart';
import 'package:rs_core/rs_core.dart';

const adminUser = User(id: 'u1', username: 'admin', role: UserRole.admin);

ServerInfo serverInfo({
  String id = 'server-1',
  ServerSetupState state = ServerSetupState.ready,
}) => ServerInfo(
  serverId: id,
  name: 'Test server',
  version: '0.1.0',
  apiVersion: ApiRoutes.version,
  setupState: state,
  platform: 'macos',
);

ApiException apiError(int? status, String code) => ApiException(
  statusCode: status,
  error: ApiError(code: code, message: code),
);

/// Scriptable [RsApiClient]; no network.
class FakeApiClient extends RsApiClient {
  FakeApiClient({Uri? baseUri, this.info})
    : super(baseUri: baseUri ?? defaultLocalServerUri);

  ServerInfo? info;
  Object? infoError;
  int infoCalls = 0;

  int joinCalls = 0;
  DeviceJoinRequest? lastJoin;

  User? meUser = adminUser;
  Object? meError;

  AuthResult? loginResult;
  Object? loginError;
  int logoutCalls = 0;

  ScanStatus scan = ScanStatus.idle;
  int scanCalls = 0;

  final eventsController = StreamController<ServerEvent>.broadcast();
  int eventSubscriptions = 0;

  @override
  Future<ServerInfo> getServerInfo() async {
    infoCalls++;
    if (infoError case final e?) throw e;
    return info ?? (throw apiError(null, ApiErrorCodes.unreachable));
  }

  @override
  Future<DeviceJoinResult> joinLocal(DeviceJoinRequest request) async {
    joinCalls++;
    lastJoin = request;
    return const DeviceJoinResult(deviceId: 'd1', deviceToken: 'device-new');
  }

  @override
  Future<User> me() async {
    if (meError case final e?) throw e;
    return meUser!;
  }

  @override
  Future<AuthResult> login(String username, String password) async {
    if (loginError case final e?) throw e;
    return loginResult!;
  }

  @override
  Future<void> logout() async => logoutCalls++;

  @override
  Future<ScanStatus> scanStatus() async {
    scanCalls++;
    return scan;
  }

  @override
  Stream<ServerEvent> events({void Function()? onConnected}) {
    eventSubscriptions++;
    scheduleMicrotask(() => onConnected?.call());
    return eventsController.stream;
  }
}

List<Override> overridesFor(FakeApiClient api, CredentialStore store) => [
  apiClientFactoryProvider.overrideWithValue((_) => api),
  credentialStoreProvider.overrideWithValue(store),
  clientCapabilitiesProvider.overrideWithValue(
    ClientCapabilities.full(platform: 'macos', deviceName: 'Test Mac'),
  ),
];

ProviderContainer makeContainer(
  FakeApiClient api,
  CredentialStore store, {
  List<Override> overrides = const [],
}) {
  return ProviderContainer(
    overrides: [...overridesFor(api, store), ...overrides],
  );
}

/// Lets queued microtasks and zero-delay timers run.
Future<void> settle([int rounds = 20]) async {
  for (var i = 0; i < rounds; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

/// Reads [connectionProvider] (which starts probing) and waits for it.
Future<ServerConnection> connect(ProviderContainer container) async {
  container.read(connectionProvider);
  await settle();
  return container.read(connectionProvider);
}
