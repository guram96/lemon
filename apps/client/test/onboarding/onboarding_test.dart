import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rs_api_client/rs_api_client.dart';
import 'package:rs_client/src/app/retro_steam_app.dart';
import 'package:rs_client/src/home/home_page.dart';
import 'package:rs_client/src/onboarding/setup_done_page.dart';
import 'package:rs_client/src/onboarding/welcome_page.dart';
import 'package:rs_client/src/storage/credential_store.dart';
import 'package:rs_core/rs_core.dart';
import 'package:rs_ui/rs_ui.dart';

import '../support/fakes.dart';
import 'setup_api.dart';

void main() {
  Future<ProviderContainer> pumpApp(WidgetTester tester, SetupApi api) async {
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
    return container;
  }

  Future<void> unmount(WidgetTester tester) =>
      tester.pumpWidget(const SizedBox.shrink());

  Future<void> enter(WidgetTester tester, String key, String value) async {
    await tester.enterText(
      find.descendant(
        of: find.byKey(Key(key)),
        matching: find.byType(EditableText),
      ),
      value,
    );
    await tester.pump();
  }

  Future<void> tapButton(WidgetTester tester, String label) async {
    final finder = find.widgetWithText(RsButton, label);
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> reachDataStep(WidgetTester tester) async {
    await enter(tester, 'setup-username', 'admin');
    await enter(tester, 'setup-password', 'short');
    await enter(tester, 'setup-confirm', 'short');
    await tapButton(tester, 'Continue');
    expect(find.text('Use at least 8 characters'), findsOneWidget);

    await enter(tester, 'setup-password', 'longenough');
    await enter(tester, 'setup-confirm', 'longenough');
    await tapButton(tester, 'Continue');
  }

  testWidgets('welcome introduces the server and opens setup', (tester) async {
    final api = SetupApi();
    await pumpApp(tester, api);

    expect(find.byType(WelcomePage), findsOneWidget);
    expect(find.text('Welcome to Retro Steam'), findsOneWidget);
    expect(find.textContaining('Test server'), findsOneWidget);

    await tapButton(tester, 'Get started');
    expect(find.text('Create the admin account'), findsOneWidget);

    await tapButton(tester, 'Back');
    expect(find.byType(WelcomePage), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('setup walks account, folders, and review into the library', (
    tester,
  ) async {
    final api = SetupApi();
    await pumpApp(tester, api);
    await tapButton(tester, 'Get started');
    await reachDataStep(tester);

    expect(find.text('${SetupApi.home}/RetroSteam'), findsOneWidget);
    expect(find.text('50.0 GB free'), findsOneWidget);
    expect(find.text('This folder will be created'), findsOneWidget);

    await tapButton(tester, 'Continue');
    expect(
      find.text('No library folders yet. Add at least one.'),
      findsOneWidget,
    );

    await tapButton(tester, 'Add folder');
    expect(find.text('roms'), findsOneWidget);
    await tester.tap(find.text('roms'));
    await tester.pumpAndSettle();
    await tapButton(tester, 'Add this folder');

    expect(find.textContaining('Super Nintendo'), findsWidgets);
    expect(find.textContaining('16 files'), findsOneWidget);

    await tapButton(tester, 'Continue');
    expect(find.text('Review and finish'), findsOneWidget);
    expect(find.text('admin'), findsOneWidget);
    expect(find.text('50.0 GB free'), findsOneWidget);

    await tapButton(tester, 'Finish setup');
    expect(find.byType(SetupDonePage), findsOneWidget);
    expect(find.text("You're all set"), findsOneWidget);
    expect(find.textContaining('Super Nintendo'), findsWidgets);
    expect(api.setupCalls, 1);
    expect(api.lastSetup?.adminUsername, 'admin');
    expect(api.lastSetup?.libraryRoots, ['${SetupApi.home}/roms']);

    await tapButton(tester, 'Go to library');
    expect(find.byType(HomePage), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('a denied data folder explains how to grant access', (
    tester,
  ) async {
    var allowed = false;
    final api = SetupApi()
      ..script = (path, kind) {
        if (kind == PathKind.dataDir && !allowed) {
          return PathCheckResult(
            path: path,
            kind: kind,
            exists: true,
            readable: false,
            writable: false,
            permissionDenied: true,
          );
        }
        return PathCheckResult(
          path: path,
          kind: kind,
          exists: true,
          readable: true,
          writable: true,
          freeBytes: kind == PathKind.dataDir ? 1000 : null,
        );
      };
    await pumpApp(tester, api);
    await tapButton(tester, 'Get started');
    await reachDataStep(tester);

    expect(find.textContaining('Full Disk Access'), findsOneWidget);
    expect(find.widgetWithText(RsButton, 'Continue'), findsOneWidget);
    final continueButton = tester.widget<RsButton>(
      find.widgetWithText(RsButton, 'Continue'),
    );
    expect(continueButton.onPressed, isNull);

    allowed = true;
    await tapButton(tester, 'Check again');
    expect(find.textContaining('Full Disk Access'), findsNothing);
    expect(find.text('Ready to use'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('a setup failure returns to the library step', (tester) async {
    final api = SetupApi()
      ..setupError = const ApiException(
        statusCode: 400,
        error: ApiError(
          code: ApiErrorCodes.pathInvalid,
          message: 'Library folder is not readable',
        ),
      );
    await pumpApp(tester, api);
    await tapButton(tester, 'Get started');
    await reachDataStep(tester);
    await tapButton(tester, 'Continue');
    await tapButton(tester, 'Add folder');
    await tester.tap(find.text('roms'));
    await tester.pumpAndSettle();
    await tapButton(tester, 'Add this folder');
    await tapButton(tester, 'Continue');
    await tapButton(tester, 'Finish setup');

    expect(find.text('Add your games'), findsOneWidget);
    expect(find.text('Library folder is not readable'), findsOneWidget);
    expect(api.setupCalls, 1);
    await unmount(tester);
  });
}
