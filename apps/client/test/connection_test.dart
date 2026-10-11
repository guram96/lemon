import 'package:flutter_test/flutter_test.dart';
import 'package:rs_client/src/connection/connection_provider.dart';
import 'package:rs_client/src/connection/server_address.dart';
import 'package:rs_client/src/session/session_provider.dart';
import 'package:rs_client/src/storage/credential_store.dart';
import 'package:rs_core/rs_core.dart';

import 'support/fakes.dart';

void main() {
  group('connection probe', () {
    test('no server → unreachable with a message', () async {
      final api = FakeApiClient();
      final container = makeContainer(api, InMemoryCredentialStore());
      addTearDown(container.dispose);

      final c = await connect(container);
      expect(c.status, ConnectionStatus.unreachable);
      expect(c.baseUri, defaultLocalServerUri);
      expect(c.error, contains('127.0.0.1:47320'));
    });

    test('unconfigured server → unconfigured, no auto-join', () async {
      final api = FakeApiClient(
        info: serverInfo(state: ServerSetupState.unconfigured),
      );
      final store = InMemoryCredentialStore();
      final container = makeContainer(api, store);
      addTearDown(container.dispose);

      final c = await connect(container);
      expect(c.status, ConnectionStatus.unconfigured);
      expect(container.read(serverInfoProvider)?.serverId, 'server-1');
      expect(api.joinCalls, 0);
      expect(store.credentials.serverId, 'server-1');
      expect(store.credentials.serverUri, defaultLocalServerUri);
    });

    test('local server without device token auto-joins', () async {
      final api = FakeApiClient(info: serverInfo());
      final store = InMemoryCredentialStore();
      final container = makeContainer(api, store);
      addTearDown(container.dispose);

      final c = await connect(container);
      expect(c.status, ConnectionStatus.ready);
      expect(api.joinCalls, 1);
      expect(api.lastJoin?.platform, 'macos');
      expect(api.lastJoin?.deviceName, 'Test Mac');
      expect(api.deviceToken, 'device-new');
      expect(store.credentials.deviceToken, 'device-new');
      expect(container.read(sessionProvider), isNull);
    });

    test('saved session is validated with /auth/me', () async {
      final api = FakeApiClient(info: serverInfo());
      final store = InMemoryCredentialStore(
        StoredCredentials(
          serverUri: defaultLocalServerUri,
          serverId: 'server-1',
          deviceToken: 'dev',
          sessionToken: 'sess',
        ),
      );
      final container = makeContainer(api, store);
      addTearDown(container.dispose);

      final c = await connect(container);
      expect(c.status, ConnectionStatus.ready);
      expect(api.joinCalls, 0);
      expect(api.deviceToken, 'dev');
      expect(api.sessionToken, 'sess');
      expect(container.read(sessionProvider), adminUser);
      expect(store.credentials.user, adminUser);
    });

    test('expired saved session is dropped', () async {
      final api = FakeApiClient(info: serverInfo())
        ..meError = apiError(401, ApiErrorCodes.unauthorized);
      final store = InMemoryCredentialStore(
        StoredCredentials(
          serverUri: defaultLocalServerUri,
          serverId: 'server-1',
          deviceToken: 'dev',
          sessionToken: 'sess',
          user: adminUser,
        ),
      );
      final container = makeContainer(api, store);
      addTearDown(container.dispose);

      final c = await connect(container);
      expect(c.status, ConnectionStatus.ready);
      expect(container.read(sessionProvider), isNull);
      expect(api.sessionToken, isNull);
      expect(store.credentials.sessionToken, isNull);
      expect(store.credentials.deviceToken, 'dev');
    });

    test('a different server at the saved address resets tokens', () async {
      final api = FakeApiClient(info: serverInfo(id: 'server-2'));
      final store = InMemoryCredentialStore(
        StoredCredentials(
          serverUri: defaultLocalServerUri,
          serverId: 'server-1',
          deviceToken: 'old',
          sessionToken: 'old',
          user: adminUser,
        ),
      );
      final container = makeContainer(api, store);
      addTearDown(container.dispose);

      await connect(container);
      expect(api.joinCalls, 1);
      expect(store.credentials.serverId, 'server-2');
      expect(store.credentials.deviceToken, 'device-new');
      expect(store.credentials.sessionToken, isNull);
      expect(container.read(sessionProvider), isNull);
    });

    test('remote server without device token is not joined', () async {
      final remote = Uri.parse('http://192.168.1.10:47320');
      final api = FakeApiClient(baseUri: remote, info: serverInfo());
      final store = InMemoryCredentialStore(
        StoredCredentials(serverUri: remote),
      );
      final container = makeContainer(api, store);
      addTearDown(container.dispose);

      final c = await connect(container);
      expect(c.status, ConnectionStatus.unreachable);
      expect(c.baseUri, remote);
      expect(c.error, contains('not joined'));
      expect(api.joinCalls, 0);
    });

    test('retry and manual address', () async {
      final api = FakeApiClient();
      final container = makeContainer(api, InMemoryCredentialStore());
      addTearDown(container.dispose);

      expect((await connect(container)).status, ConnectionStatus.unreachable);
      api.info = serverInfo();
      await container.read(connectionProvider.notifier).retry();
      expect(container.read(connectionProvider).status, ConnectionStatus.ready);

      await container
          .read(connectionProvider.notifier)
          .connectTo(Uri.parse('http://localhost:1234'));
      expect(
        container.read(connectionProvider).baseUri,
        Uri.parse('http://localhost:1234'),
      );
    });
  });

  group('server address', () {
    test('parses user input', () {
      expect(
        parseServerAddress('192.168.1.10'),
        Uri.parse('http://192.168.1.10:47320'),
      );
      expect(
        parseServerAddress(' nas.local:8080 '),
        Uri.parse('http://nas.local:8080'),
      );
      expect(
        parseServerAddress('https://host'),
        Uri.parse('https://host:47320'),
      );
      expect(parseServerAddress(''), isNull);
      expect(parseServerAddress('ftp://host'), isNull);
    });

    test('loopback detection', () {
      expect(isLoopbackUri(defaultLocalServerUri), isTrue);
      expect(isLoopbackUri(Uri.parse('http://localhost:1')), isTrue);
      expect(isLoopbackUri(Uri.parse('http://[::1]:1')), isTrue);
      expect(isLoopbackUri(Uri.parse('http://192.168.0.2:1')), isFalse);
    });
  });
}
