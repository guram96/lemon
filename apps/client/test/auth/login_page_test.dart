import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rs_client/src/app/retro_steam_app.dart';
import 'package:rs_client/src/auth/login_page.dart';
import 'package:rs_client/src/home/home_page.dart';
import 'package:rs_client/src/storage/credential_store.dart';
import 'package:rs_core/rs_core.dart';
import 'package:rs_ui/rs_ui.dart';

import '../support/fakes.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester, FakeApiClient api) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final container = ProviderContainer(
      overrides: overridesFor(api, InMemoryCredentialStore()),
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const RetroSteamApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> unmount(WidgetTester tester) =>
      tester.pumpWidget(const SizedBox.shrink());

  Finder field(String key) => find.descendant(
    of: find.byKey(Key(key)),
    matching: find.byType(EditableText),
  );

  testWidgets('empty, wrong, then correct credentials', (tester) async {
    final api = FakeApiClient(info: serverInfo())
      ..loginError = apiError(401, ApiErrorCodes.invalidCredentials);
    await pumpApp(tester, api);

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.textContaining('Test server'), findsOneWidget);

    await tester.tap(find.widgetWithText(RsButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your username and password.'), findsOneWidget);

    await tester.enterText(field('login-username'), 'admin');
    await tester.enterText(field('login-password'), 'wrong-password');
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(
      find.text('That username or password is not right.'),
      findsOneWidget,
    );

    api
      ..loginError = null
      ..loginResult = const AuthResult(
        sessionToken: 'session',
        user: adminUser,
      );
    await tester.enterText(field('login-password'), 'correct-password');
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.byType(HomePage), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('too many attempts is explained', (tester) async {
    final api = FakeApiClient(info: serverInfo())
      ..loginError = apiError(429, ApiErrorCodes.rateLimited);
    await pumpApp(tester, api);
    await tester.enterText(field('login-username'), 'admin');
    await tester.enterText(field('login-password'), 'longenough');
    await tester.tap(find.widgetWithText(RsButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Too many attempts'), findsOneWidget);
    expect(find.byType(LoginPage), findsOneWidget);
    await unmount(tester);
  });
}
