import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rs_client/src/install/install_store.dart';
import 'package:rs_client/src/launch/launch_models.dart';
import 'package:rs_client/src/launch/launch_store.dart';

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('rs_launch_');
  });

  tearDown(() async {
    if (root.existsSync()) await root.delete(recursive: true);
  });

  test('saves and reloads choices', () async {
    final system = LaunchChoice(
      emulatorId: ' retroarch ',
      corePath: '/cores/snes9x.dylib',
      customCommand: 'retroarch "{rom}"',
    );
    final psx = LaunchChoice(emulatorId: 'duckstation');
    final game = LaunchChoice(
      emulatorId: ' custom ',
      customCommand: '  snes9x "{rom}" ',
    );
    expect(game.emulatorId, customEmulatorId);
    expect(game.customCommand, 'snes9x "{rom}"');
    expect(system.emulatorId, 'retroarch');

    final first = openLaunchStore(root);
    await first.putSystem('snes', LaunchChoice(emulatorId: 'old'));
    await first.putSystem('snes', system);
    await first.putSystem('psx', psx);
    await first.putGame(
      'server-a',
      'chrono',
      LaunchChoice(emulatorId: 'old-game'),
    );
    await first.putGame('server-a', 'chrono', game);

    final loaded = await openLaunchStore(root).read();
    expect(
      loaded,
      LaunchOptions(
        systems: {'snes': system, 'psx': psx},
        games: {
          'server-a': {'chrono': game},
        },
      ),
    );
    expect(launchStoreFileName, 'launch.json');
    expect(File('${root.path}/launch.json').existsSync(), isTrue);
    expect(
      root.listSync().where((entity) => entity.path.endsWith('.tmp')),
      isEmpty,
    );
  });

  test('game choice beats system choice', () async {
    final store = openLaunchStore(root);
    final system = LaunchChoice(
      emulatorId: 'retroarch',
      corePath: '/cores/snes9x.dylib',
    );
    final game = LaunchChoice(emulatorId: 'snes9x');
    final otherServer = LaunchChoice(emulatorId: 'mgba');
    await store.putSystem('snes', system);
    await store.putGame('server-a', 'chrono', game);
    await store.putGame('server-b', 'chrono', otherServer);

    final options = await openLaunchStore(root).read();
    expect(options.resolve('snes', 'server-a', 'chrono'), game);
    expect(options.resolve('nes', 'server-a', 'chrono'), game);
    expect(options.resolve('snes', 'server-a', 'other'), system);
    expect(options.resolve('gb', 'server-b', 'chrono'), otherServer);
    expect(options.resolve('nes', 'server-c', 'missing'), isNull);
  });

  test('clear game falls back to the system choice', () async {
    final store = openLaunchStore(root);
    final system = LaunchChoice(emulatorId: 'retroarch');
    final game = LaunchChoice(emulatorId: 'snes9x');
    final other = LaunchChoice(emulatorId: 'mgba');
    await store.putSystem('snes', system);
    await store.putGame('server-a', 'chrono', game);
    await store.putGame('server-a', 'zelda', other);

    await store.removeGame('server-a', 'chrono');

    final options = await openLaunchStore(root).read();
    expect(options.resolve('snes', 'server-a', 'chrono'), system);
    expect(options.resolve('snes', 'server-a', 'zelda'), other);
  });

  test('custom without a command is rejected', () async {
    final store = openLaunchStore(root);
    final kept = LaunchChoice(emulatorId: 'retroarch');
    await store.putSystem('snes', kept);
    final before = await File('${root.path}/launch.json').readAsString();

    expect(() => LaunchChoice(emulatorId: 'custom'), throwsFormatException);
    expect(
      () => LaunchChoice(emulatorId: 'custom', customCommand: '   '),
      throwsFormatException,
    );
    expect(() => LaunchChoice(emulatorId: '   '), throwsFormatException);
    expect(
      () => store.putSystem('nes', LaunchChoice(emulatorId: 'custom')),
      throwsFormatException,
    );

    expect(await File('${root.path}/launch.json').readAsString(), before);
    expect((await store.read()).systems['snes'], kept);
    expect((await store.read()).systems.containsKey('nes'), isFalse);

    await File('${root.path}/launch.json')
        .writeAsString('{"systems":{"snes":{"emulatorId":"custom"}}}');
    expect(store.read(), throwsFormatException);
  });

  test('remove missing is success', () async {
    final store = openLaunchStore(root);
    await store.removeSystem('snes');
    await store.removeGame('server', 'game');
    expect(await store.read(), LaunchOptions());
    expect(File('${root.path}/launch.json').existsSync(), isFalse);

    final system = LaunchChoice(emulatorId: 'retroarch');
    await store.putSystem('snes', system);
    await store.removeSystem('nes');
    await store.removeGame('server', 'missing');
    expect((await store.read()).resolve('snes', 'server', 'missing'), system);
  });

  test('missing or empty file loads as empty options', () async {
    expect(await openLaunchStore(root).read(), LaunchOptions());

    final file = File('${root.path}/launch.json');
    await file.writeAsString(' \n\t');
    expect(await openLaunchStore(root).read(), LaunchOptions());

    await file.writeAsString('{}');
    expect(await openLaunchStore(root).read(), LaunchOptions());
  });

  test('a corrupt file is not treated as empty', () async {
    final file = File('${root.path}/launch.json');
    await file.writeAsString('{');
    expect(openLaunchStore(root).read(), throwsFormatException);
    expect(await file.readAsString(), '{');

    await file.writeAsString('[]');
    expect(openLaunchStore(root).read(), throwsFormatException);

    await file.writeAsString('{"systems":[]}');
    expect(openLaunchStore(root).read(), throwsFormatException);
  });

  test('a non-directory is rejected', () {
    expect(() => openLaunchStore('nope'), throwsArgumentError);
  });

  test('launch directory follows the install directory', () async {
    final container = ProviderContainer(
      overrides: [installDirectoryProvider.overrideWithValue(root)],
    );
    addTearDown(container.dispose);

    await container
        .read(launchOptionsProvider.notifier)
        .setSystem('snes', LaunchChoice(emulatorId: 'retroarch'));
    expect(File('${root.path}/launch.json').existsSync(), isTrue);
  });

  test(
    'launchOptionsProvider persists through an injected directory',
    () async {
      final container = ProviderContainer(
        overrides: [launchDirectoryProvider.overrideWithValue(root)],
      );
      addTearDown(container.dispose);

      expect(
        await container.read(launchOptionsProvider.future),
        LaunchOptions(),
      );

      final system = LaunchChoice(
        emulatorId: 'retroarch',
        corePath: '/cores/snes9x.dylib',
      );
      final game = LaunchChoice(
        emulatorId: 'custom',
        customCommand: 'snes9x "{rom}"',
      );
      final notifier = container.read(launchOptionsProvider.notifier);
      await notifier.setSystem('snes', system);
      await notifier.setGame('server-a', 'chrono', game);

      final current = container.read(launchOptionsProvider).requireValue;
      expect(current.resolve('snes', 'server-a', 'chrono'), game);
      expect(current.resolve('snes', 'server-a', 'other'), system);

      await notifier.clearGame('server-a', 'chrono');
      expect(
        container
            .read(launchOptionsProvider)
            .requireValue
            .resolve('snes', 'server-a', 'chrono'),
        system,
      );

      final again = ProviderContainer(
        overrides: [launchDirectoryProvider.overrideWithValue(root)],
      );
      addTearDown(again.dispose);
      final loaded = await again.read(launchOptionsProvider.future);
      expect(loaded.resolve('snes', 'server-a', 'chrono'), system);

      await again.read(launchOptionsProvider.notifier).clearSystem('snes');
      expect(
        again
            .read(launchOptionsProvider)
            .requireValue
            .resolve('snes', 'server-a', 'chrono'),
        isNull,
      );
    },
  );
}
