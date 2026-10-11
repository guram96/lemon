import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rs_client/src/install/install_models.dart';
import 'package:rs_client/src/install/install_store.dart';

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('rs_install_');
  });

  tearDown(() async {
    if (root.existsSync()) await root.delete(recursive: true);
  });

  test('saves and reloads destinations and records', () async {
    final destination = InstallDestination(
      globalFolder: '/roms',
      foldersBySystem: const {'psx': '/psx', 'snes': '/snes'},
    );
    final downloading = InstallRecord(
      serverId: 'server-a',
      gameId: 'chrono',
      systemId: 'snes',
      phase: InstallPhase.downloading,
      receivedBytes: 10,
      totalBytes: 50,
      files: const [
        InstallFileProgress(
          index: 0,
          path: 'chrono.sfc',
          receivedBytes: 10,
          sizeBytes: 50,
          complete: false,
        ),
      ],
    );
    final failed = InstallRecord(
      serverId: 'server-a',
      gameId: 'ff7',
      systemId: 'psx',
      phase: InstallPhase.failed,
      receivedBytes: 3,
      totalBytes: 9,
      error: 'disk full',
      files: const [
        InstallFileProgress(
          index: 1,
          path: 'disc1/game.bin',
          receivedBytes: 3,
          sizeBytes: 4,
          complete: false,
        ),
        InstallFileProgress(
          index: 0,
          path: 'disc1/game.cue',
          receivedBytes: 0,
          sizeBytes: 5,
          complete: true,
        ),
      ],
    );
    final otherServer = record(serverId: 'server-b', gameId: 'sonic');

    final first = openInstallStore(root);
    await first.writeDestinations(destination);
    await first.put(failed);
    await first.put(downloading);
    await first.put(otherServer);

    final second = openInstallStore(root);
    expect(await second.readDestinations(), destination);
    expect(await second.installs('server-a'), [downloading, failed]);
    expect(await second.installs('server-b'), [otherServer]);
    expect(File('${root.path}/$installStoreFileName').existsSync(), isTrue);
    expect(
      root.listSync().where((entity) => entity.path.endsWith('.tmp')),
      isEmpty,
    );
  });

  test('per-system folder overrides the global folder', () {
    final destination = InstallDestination(
      globalFolder: '/roms',
      foldersBySystem: const {'snes': '/snes-only'},
    );
    expect(destination.folderFor('snes'), '/snes-only');
    expect(destination.folderFor('psx'), '/roms');
    expect(InstallDestination().folderFor('snes'), isNull);
    expect(
      InstallDestination(foldersBySystem: const {'snes': '/snes-only'})
          .folderFor('nes'),
      isNull,
    );
    expect(
      destination.withSystemFolder('snes', null).folderFor('snes'),
      '/roms',
    );
  });

  test('installs returns one server ordered by game id', () async {
    final store = openInstallStore(root);
    await store.put(record(serverId: 's1', gameId: 'b'));
    await store.put(record(serverId: 's2', gameId: 'a'));
    await store.put(record(serverId: 's1', gameId: 'c'));
    await store.put(record(serverId: 's1', gameId: 'a'));

    expect((await store.installs('s1')).map((item) => item.gameId), [
      'a',
      'b',
      'c',
    ]);
    expect(await store.installs('s2'), [record(serverId: 's2', gameId: 'a')]);
    expect(await store.installs('other'), isEmpty);
  });

  test('put replaces the record with the same server and game', () async {
    final store = openInstallStore(root);
    await store.put(record(phase: InstallPhase.queued));
    await store.put(
      record(phase: InstallPhase.installed, files: [progress('game.sfc')]),
    );

    final saved = await store.installs('server-1');
    expect(saved, hasLength(1));
    expect(saved.single.phase, InstallPhase.installed);
    expect(saved.single.files.single.path, 'game.sfc');

    await store.remove('server-1', 'game-1');
    expect(await store.installs('server-1'), isEmpty);
  });

  test('uninstall deletes a file inside the folder', () async {
    final dest = Directory('${root.path}/dest');
    final rom = File('${dest.path}/snes/chrono.sfc');
    await rom.parent.create(recursive: true);
    await rom.writeAsString('rom');

    final store = openInstallStore(root);
    await store.writeDestinations(InstallDestination(globalFolder: dest.path));
    final installed = record(
      files: [progress('chrono.sfc'), progress('missing.sfc', index: 1)],
    );
    await store.put(installed);

    expect(await store.uninstall(installed), isEmpty);
    expect(rom.existsSync(), isFalse);
    expect(await store.installs('server-1'), isEmpty);
  });

  test('uninstall does not delete a .. path and reports it', () async {
    final dest = Directory('${root.path}/dest');
    final keep = File('${dest.path}/snes/keep.sfc');
    final inside = File('${dest.path}/snes/game.sfc');
    final secret = File('${root.path}/secret.txt');
    await keep.parent.create(recursive: true);
    await keep.writeAsString('keep');
    await inside.writeAsString('inside');
    await secret.writeAsString('secret');

    final store = openInstallStore(root);
    await store.writeDestinations(InstallDestination(globalFolder: dest.path));
    final installed = record(
      files: [
        progress('keep.sfc'),
        progress('nested/../game.sfc', index: 1),
        progress('../../secret.txt', index: 2),
      ],
    );
    await store.put(installed);

    expect(await store.uninstall(installed), [
      'nested/../game.sfc',
      '../../secret.txt',
    ]);
    expect(keep.existsSync(), isFalse);
    expect(inside.existsSync(), isTrue);
    expect(await inside.readAsString(), 'inside');
    expect(secret.existsSync(), isTrue);
    expect(await secret.readAsString(), 'secret');
    expect(await store.installs('server-1'), isEmpty);
  });

  test('uninstall uses the per-system folder', () async {
    final global = Directory('${root.path}/global');
    final snes = Directory('${root.path}/snes-only');
    final rom = File('${snes.path}/snes/game.sfc');
    final decoy = File('${global.path}/snes/game.sfc');
    await rom.parent.create(recursive: true);
    await decoy.parent.create(recursive: true);
    await rom.writeAsString('real');
    await decoy.writeAsString('decoy');

    final store = openInstallStore(root);
    await store.writeDestinations(
      InstallDestination(
        globalFolder: global.path,
        foldersBySystem: {'snes': snes.path},
      ),
    );
    final installed = record(files: [progress('game.sfc')]);
    await store.put(installed);

    expect(await store.uninstall(installed), isEmpty);
    expect(rom.existsSync(), isFalse);
    expect(decoy.existsSync(), isTrue);
    expect(await decoy.readAsString(), 'decoy');
  });

  test('uninstall skips every file when no folder is set', () async {
    final dest = Directory('${root.path}/dest');
    final rom = File('${dest.path}/snes/game.sfc');
    await rom.parent.create(recursive: true);
    await rom.writeAsString('rom');

    final store = openInstallStore(root);
    final installed = record(files: [progress('game.sfc')]);
    await store.put(installed);

    expect(await store.uninstall(installed), ['game.sfc']);
    expect(rom.existsSync(), isTrue);
    expect(await store.installs('server-1'), isEmpty);
  });

  test('uninstall does not delete a path with an empty segment', () async {
    final dest = Directory('${root.path}/dest');
    final rom = File('${dest.path}/snes/sub/game.sfc');
    await rom.parent.create(recursive: true);
    await rom.writeAsString('rom');

    final store = openInstallStore(root);
    await store.writeDestinations(InstallDestination(globalFolder: dest.path));
    final installed = record(files: [progress('sub//game.sfc')]);
    await store.put(installed);

    expect(await store.uninstall(installed), ['sub//game.sfc']);
    expect(await rom.readAsString(), 'rom');
  });

  test('uninstall leaves an absolute path on disk and reports it', () async {
    final dest = Directory('${root.path}/dest');
    await dest.create();
    final secret = File('${root.path}/absolute.txt');
    await secret.writeAsString('keep');

    final store = openInstallStore(root);
    await store.writeDestinations(InstallDestination(globalFolder: dest.path));
    final installed = record(files: [progress(secret.path)]);
    await store.put(installed);

    expect(await store.uninstall(installed), [secret.path]);
    expect(await secret.readAsString(), 'keep');
  });

  test('a corrupt file is not treated as empty', () async {
    await File('${root.path}/$installStoreFileName').writeAsString('{');
    final store = openInstallStore(root);
    expect(store.readDestinations(), throwsFormatException);
  });

  test('destinationsProvider persists through an injected directory', () async {
    final container = ProviderContainer(
      overrides: [installDirectoryProvider.overrideWithValue(root)],
    );
    addTearDown(container.dispose);

    expect(
      await container.read(destinationsProvider.future),
      InstallDestination(),
    );

    await container
        .read(destinationsProvider.notifier)
        .setGlobalFolder('${root.path}/roms');
    await container
        .read(destinationsProvider.notifier)
        .setSystemFolder('snes', '${root.path}/snes');

    final current = container.read(destinationsProvider).requireValue;
    expect(current.folderFor('snes'), '${root.path}/snes');
    expect(current.folderFor('nes'), '${root.path}/roms');

    final again = ProviderContainer(
      overrides: [installDirectoryProvider.overrideWithValue(root)],
    );
    addTearDown(again.dispose);
    final loaded = await again.read(destinationsProvider.future);
    expect(loaded.folderFor('snes'), '${root.path}/snes');
    expect(loaded.folderFor('nes'), '${root.path}/roms');
  });
}

InstallRecord record({
  String serverId = 'server-1',
  String gameId = 'game-1',
  String systemId = 'snes',
  InstallPhase phase = InstallPhase.installed,
  List<InstallFileProgress> files = const [],
}) {
  return InstallRecord(
    serverId: serverId,
    gameId: gameId,
    systemId: systemId,
    phase: phase,
    receivedBytes: 4,
    totalBytes: 4,
    files: files,
  );
}

InstallFileProgress progress(String path, {int index = 0}) {
  return InstallFileProgress(
    index: index,
    path: path,
    receivedBytes: 4,
    sizeBytes: 4,
    complete: true,
  );
}
