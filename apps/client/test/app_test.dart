import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rs_client/src/app/retro_steam_app.dart';
import 'package:rs_client/src/auth/login_page.dart';
import 'package:rs_client/src/connection/connect_page.dart';
import 'package:rs_client/src/connection/server_address.dart';
import 'package:rs_client/src/home/home_page.dart';
import 'package:rs_client/src/library/library_page.dart';
import 'package:rs_client/src/notifications/notification_center.dart';
import 'package:rs_client/src/onboarding/setup_done_page.dart';
import 'package:rs_client/src/onboarding/welcome_page.dart';
import 'package:rs_client/src/routing/router.dart';
import 'package:rs_client/src/session/session_provider.dart';
import 'package:rs_client/src/storage/credential_store.dart';
import 'package:rs_core/rs_core.dart';
import 'package:rs_ui/rs_ui.dart';

import 'support/fakes.dart';

void main() {
  Future<ProviderContainer> pumpApp(
    WidgetTester tester,
    FakeApiClient api, [
    StoredCredentials creds = StoredCredentials.empty,
  ]) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final container = ProviderContainer(
      overrides: overridesFor(api, InMemoryCredentialStore(creds)),
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const RetroSteamApp(),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  // The top bar clock keeps a timer: unmount before the test ends.
  Future<void> unmount(WidgetTester tester) =>
      tester.pumpWidget(const SizedBox.shrink());

  const session = StoredCredentials(
    serverId: 'server-1',
    deviceToken: 'dev',
    sessionToken: 'sess',
    user: adminUser,
  );

  testWidgets('no server → connect page', (tester) async {
    await pumpApp(tester, FakeApiClient());
    expect(find.byType(ConnectPage), findsOneWidget);
    expect(find.text('Server not found'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('unconfigured server → welcome; setup → done', (tester) async {
    final api = FakeApiClient(
      info: serverInfo(state: ServerSetupState.unconfigured),
    );
    final container = await pumpApp(tester, api);
    expect(find.byType(WelcomePage), findsOneWidget);

    container.read(routerProvider).go(AppRoutes.setup);
    await tester.pumpAndSettle();
    await container
        .read(sessionProvider.notifier)
        .adoptAuthResult(
          const AuthResult(
            sessionToken: 's',
            user: adminUser,
            deviceToken: 'd',
          ),
        );
    await tester.pumpAndSettle();
    expect(find.byType(SetupDonePage), findsOneWidget);

    container.read(routerProvider).go(AppRoutes.home);
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('no session → login', (tester) async {
    await pumpApp(tester, FakeApiClient(info: serverInfo()));
    expect(find.byType(LoginPage), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('session → home shell, nav, toasts, 401 → login', (tester) async {
    final api = FakeApiClient(info: serverInfo());
    final container = await pumpApp(
      tester,
      api,
      session.copyWith(serverUri: defaultLocalServerUri),
    );
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(RsTopBar), findsOneWidget);
    expect(find.text('Library'), findsWidgets);

    container.read(routerProvider).go(AppRoutes.library);
    await tester.pumpAndSettle();
    expect(find.byType(LibraryPage), findsOneWidget);

    container
        .read(notificationCenterProvider.notifier)
        .show(
          const AppNotification(id: 'hello', title: 'Hello', persistent: true),
        );
    await tester.pumpAndSettle();
    expect(find.text('Hello'), findsOneWidget);

    container
        .read(sessionProvider.notifier)
        .handleApiError(apiError(401, ApiErrorCodes.unauthorized));
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);
    await unmount(tester);
  });
}
