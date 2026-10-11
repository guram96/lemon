import 'dart:io';

import 'package:rs_server/src/watch/library_watcher.dart';
import 'package:test/test.dart';

void main() {
  late Directory root;
  late LibraryWatcher watcher;

  setUp(() {
    root = Directory.systemTemp.createTempSync('rs-watch-');
    watcher = LibraryWatcher(quiet: const Duration(milliseconds: 50));
  });

  tearDown(() async {
    await watcher.close();
    root.deleteSync(recursive: true);
  });

  Future<void> until(bool Function() ready) async {
    final deadline = DateTime.now().add(const Duration(seconds: 2));
    while (!ready() && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  }

  test('a burst of writes becomes one change', () async {
    watcher.watch(rootId: 'roms', path: root.path);
    final events = <RootLibraryChange>[];
    final sub = watcher.changes.listen(events.add);
    addTearDown(sub.cancel);

    final folder = Directory('${root.path}/snes')..createSync();
    for (var i = 0; i < 5; i++) {
      File('${folder.path}/game$i.sfc').writeAsStringSync('x');
    }
    await until(() => events.isNotEmpty);
    await Future<void>.delayed(const Duration(milliseconds: 120));

    expect(events.map((e) => e.rootId).toList(), ['roms']);
  });

  test('hidden names and media folders are ignored', () async {
    watcher.watch(rootId: 'roms', path: root.path);
    final events = <RootLibraryChange>[];
    final sub = watcher.changes.listen(events.add);
    addTearDown(sub.cancel);

    File('${root.path}/.DS_Store').writeAsStringSync('x');
    Directory('${root.path}/.retrosteam').createSync();
    final media = Directory('${root.path}/media')..createSync();
    File('${media.path}/box.png').writeAsStringSync('x');
    File('${root.path}/Images/shot.png').createSync(recursive: true);
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(events, isEmpty);

    File('${root.path}/nes/mario.nes').createSync(recursive: true);
    await until(() => events.isNotEmpty);
    expect(events.single.rootId, 'roms');
  });
}
