import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rs_client/src/connection/connection_provider.dart';
import 'package:rs_client/src/connection/server_address.dart';
import 'package:rs_client/src/connection/unauthorized_interceptor.dart';
import 'package:rs_client/src/events/events_provider.dart';
import 'package:rs_client/src/session/session_provider.dart';
import 'package:rs_client/src/storage/credential_store.dart';
import 'package:rs_core/rs_core.dart';

import 'support/fakes.dart';

void main() {
  test('adoptAuthResult after setup stores tokens and logs in', () async {
    final api = FakeApiClient(
      info: serverInfo(state: ServerSetupState.unconfigured),
    );
    final store = InMemoryCredentialStore();
    final container = makeContainer(api, store);
    addTearDown(container.dispose);
    expect((await connect(container)).status, ConnectionStatus.unconfigured);

    await container
        .read(sessionProvider.notifier)
        .adoptAuthResult(
          const AuthResult(
            sessionToken: 'sess',
            user: adminUser,
            deviceId: 'd1',
            deviceToken: 'dev',
          ),
        );

    expect(container.read(sessionProvider), adminUser);
    expect(container.read(connectionProvider).status, ConnectionStatus.ready);
    expect(
      container.read(serverInfoProvider)?.setupState,
      ServerSetupState.ready,
    );
    expect(api.deviceToken, 'dev');
    expect(api.sessionToken, 'sess');
    expect(
      store.credentials,
      StoredCredentials(
        serverUri: defaultLocalServerUri,
        serverId: 'server-1',
        deviceToken: 'dev',
        sessionToken: 'sess',
        user: adminUser,
      ),
    );
  });

  test('login keeps the existing device token', () async {
    final api = FakeApiClient(info: serverInfo())
      ..loginResult = const AuthResult(sessionToken: 'sess', user: adminUser);
    final store = InMemoryCredentialStore();
    final container = makeContainer(api, store);
    addTearDown(container.dispose);
    await connect(container);

    final user = await container
        .read(sessionProvider.notifier)
        .login('admin', 'password');
    expect(user, adminUser);
    expect(container.read(sessionProvider), adminUser);
    expect(store.credentials.deviceToken, 'device-new');
    expect(store.credentials.sessionToken, 'sess');
  });

  test('failed login throws and stays logged out', () async {
    final api = FakeApiClient(info: serverInfo())
      ..loginError = apiError(401, ApiErrorCodes.invalidCredentials);
    final container = makeContainer(api, InMemoryCredentialStore());
    addTearDown(container.dispose);
    await connect(container);

    await expectLater(
      container.read(sessionProvider.notifier).login('admin', 'nope'),
      throwsA(isA<Object>()),
    );
    expect(container.read(sessionProvider), isNull);
  });

  Future<(FakeApiClient, InMemoryCredentialStore, ProviderContainer)>
  loggedIn() async {
    final api = FakeApiClient(info: serverInfo());
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
    await connect(container);
    expect(container.read(sessionProvider), adminUser);
    return (api, store, container);
  }

  test('logout ends the session but keeps the device', () async {
    final (api, store, container) = await loggedIn();
    await container.read(sessionProvider.notifier).logout();

    expect(api.logoutCalls, 1);
    expect(container.read(sessionProvider), isNull);
    expect(api.sessionToken, isNull);
    expect(api.deviceToken, 'dev');
    expect(store.credentials.sessionToken, isNull);
    expect(store.credentials.user, isNull);
    expect(store.credentials.deviceToken, 'dev');
  });

  test('a 401 clears the session', () async {
    final (api, store, container) = await loggedIn();
    final handled = container
        .read(sessionProvider.notifier)
        .handleApiError(apiError(401, ApiErrorCodes.unauthorized));
    await settle();

    expect(handled, isTrue);
    expect(container.read(sessionProvider), isNull);
    expect(store.credentials.sessionToken, isNull);
    expect(api.sessionToken, isNull);
  });

  test('other errors keep the session', () async {
    final (_, _, container) = await loggedIn();
    final handled = container
        .read(sessionProvider.notifier)
        .handleApiError(apiError(500, ApiErrorCodes.internal));
    expect(handled, isFalse);
    expect(container.read(sessionProvider), adminUser);
  });

  test('event stream closed with 4401 clears the session', () async {
    final (api, _, container) = await loggedIn();
    final sub = container.read(eventsProvider).listen((_) {});
    addTearDown(sub.cancel);
    await settle();
    expect(api.eventSubscriptions, 1);

    api.eventsController.addError(apiError(401, ApiErrorCodes.unauthorized));
    await settle();
    expect(container.read(sessionProvider), isNull);
  });

  group('UnauthorizedInterceptor', () {
    test('reports 401s of requests that carried a session', () async {
      var calls = 0;
      final client = UnauthorizedInterceptor(
        MockClient((_) async => http.Response('{}', 401)),
        onUnauthorized: () => calls++,
      );
      await client.get(
        Uri.parse('http://x/a'),
        headers: {ApiHeaders.authorization: 'Bearer t'},
      );
      expect(calls, 1);

      // Login without a session (wrong password) is not a dead session.
      await client.post(Uri.parse('http://x/login'));
      expect(calls, 1);
    });

    test('ignores other statuses', () async {
      var calls = 0;
      final client = UnauthorizedInterceptor(
        MockClient((_) async => http.Response('{}', 403)),
        onUnauthorized: () => calls++,
      );
      await client.get(
        Uri.parse('http://x/a'),
        headers: {ApiHeaders.authorization: 'Bearer t'},
      );
      expect(calls, 0);
    });
  });
}
