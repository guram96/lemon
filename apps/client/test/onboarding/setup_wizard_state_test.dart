import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rs_api_client/rs_api_client.dart';
import 'package:rs_client/src/onboarding/permission_help.dart';
import 'package:rs_client/src/onboarding/setup_wizard_state.dart';
import 'package:rs_client/src/session/session_provider.dart';
import 'package:rs_client/src/storage/credential_store.dart';
import 'package:rs_core/rs_core.dart';

import '../support/fakes.dart';
import 'setup_api.dart';

void main() {
  const home = '/Users/test';

  ProviderContainer containerFor(SetupApi api) {
    final container = ProviderContainer(
      overrides: overridesFor(api, InMemoryCredentialStore()),
    );
    addTearDown(container.dispose);
    return container;
  }

  test('account step shows errors only after an attempt', () {
    final container = containerFor(SetupApi());
    final notifier = container.read(setupWizardProvider.notifier);
    final state = container.read(setupWizardProvider);

    expect(state.usernameError, isNull);
    expect(notifier.next(), isFalse);
    expect(container.read(setupWizardProvider).usernameError, isNotNull);

    notifier.setUsername('admin');
    notifier.setPassword('short');
    notifier.setConfirm('nope');
    expect(notifier.next(), isFalse);
    expect(
      container.read(setupWizardProvider).passwordError,
      'Use at least 8 characters',
    );
    expect(
      container.read(setupWizardProvider).confirmError,
      "Passwords don't match",
    );

    notifier
      ..setPassword('longenough')
      ..setConfirm('longenough');
    expect(notifier.next(), isTrue);
    expect(container.read(setupWizardProvider).step, SetupStep.data);
    expect(notifier.back(), isTrue);
    expect(container.read(setupWizardProvider).step, SetupStep.account);
    expect(notifier.back(), isFalse);
  });

  test('a library folder cannot be the data folder', () async {
    final api = SetupApi();
    final container = containerFor(api);
    final notifier = container.read(setupWizardProvider.notifier);
    await notifier.chooseDataDir('$home/RetroSteam');
    await notifier.addRoot('$home/RetroSteam/');
    final state = container.read(setupWizardProvider);
    expect(state.rootClashesWithData, isTrue);
    expect(state.libraryValid, isFalse);
  });

  test('finish posts setup and signs the admin in', () async {
    final api = SetupApi();
    final container = containerFor(api);
    final notifier = container.read(setupWizardProvider.notifier);
    notifier
      ..setUsername('  admin  ')
      ..setPassword('longenough')
      ..setConfirm('longenough');
    await notifier.chooseDataDir('$home/RetroSteam');
    await notifier.addRoot('$home/roms');
    expect(notifier.next(), isTrue);
    expect(notifier.next(), isTrue);
    expect(notifier.next(), isTrue);
    await notifier.finish();
    await settle();

    expect(api.setupCalls, 1);
    expect(api.lastSetup?.adminUsername, 'admin');
    expect(api.lastSetup?.dataDir, '$home/RetroSteam');
    expect(api.lastSetup?.libraryRoots, ['$home/roms']);
    expect(api.lastSetup?.deviceName, 'Test Mac');
    expect(container.read(sessionProvider)?.username, 'admin');
    expect(container.read(setupWizardProvider).password, isEmpty);
  });

  test('a library path error sends the wizard back to that step', () async {
    final api = SetupApi()
      ..setupError = const ApiException(
        statusCode: 400,
        error: ApiError(
          code: ApiErrorCodes.pathInvalid,
          message: 'Library folder is not readable',
        ),
      );
    final container = containerFor(api);
    final notifier = container.read(setupWizardProvider.notifier);
    notifier
      ..setUsername('admin')
      ..setPassword('longenough')
      ..setConfirm('longenough');
    await notifier.chooseDataDir('$home/RetroSteam');
    await notifier.addRoot('$home/roms');
    expect(notifier.next(), isTrue);
    expect(notifier.next(), isTrue);
    expect(notifier.next(), isTrue);
    await notifier.finish();

    final state = container.read(setupWizardProvider);
    expect(state.finishing, isFalse);
    expect(state.step, SetupStep.library);
    expect(state.error?.message, 'Library folder is not readable');
  });

  test('stepForError maps server failures to the step that can fix them', () {
    SetupStep step(String code, String message) =>
        SetupWizardNotifier.stepForError(
          ApiException(
            statusCode: 400,
            error: ApiError(code: code, message: message),
          ),
        );

    expect(
      step(ApiErrorCodes.pathInvalid, 'Data folder is not writable'),
      SetupStep.data,
    );
    expect(
      step(ApiErrorCodes.pathInvalid, 'Library folder is missing'),
      SetupStep.library,
    );
    expect(
      step(ApiErrorCodes.badRequest, 'Password is too short'),
      SetupStep.account,
    );
    expect(
      step(
        ApiErrorCodes.conflict,
        'Enter its admin username and password to adopt it',
      ),
      SetupStep.account,
    );
    expect(step(ApiErrorCodes.internal, 'nope'), SetupStep.review);
  });

  test('server paths join with the separator the path already uses', () {
    expect(
      joinServerPath('/Users/test', 'RetroSteam'),
      '/Users/test/RetroSteam',
    );
    expect(
      joinServerPath('/Users/test/', 'RetroSteam'),
      '/Users/test/RetroSteam',
    );
    expect(
      joinServerPath(r'C:\Users\test', 'RetroSteam'),
      r'C:\Users\test\RetroSteam',
    );
  });

  test('permission steps follow the server operating system', () {
    expect(
      permissionSteps('macos', path: '/roms').join('\n'),
      contains('Full Disk Access'),
    );
    expect(
      permissionSteps('windows', path: r'C:\roms').join('\n'),
      contains('Security'),
    );
    expect(
      permissionSteps('linux', path: '/mnt/roms').join('\n'),
      contains('/mnt/roms'),
    );
    expect(
      permissionSteps('freebsd', path: '/roms').join('\n'),
      contains('Check again'),
    );
  });
}
