import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:rs_core/rs_core.dart';
import 'package:rs_server/rs_server.dart';
import 'package:test/test.dart';

void main() {
  late Directory tmp;
  setUp(() async => tmp = await Directory.systemTemp.createTemp('rs_cfg'));
  tearDown(() => tmp.delete(recursive: true));

  test('creates a config with a stable server ID on first load', () async {
    final file = File(p.join(tmp.path, 'nested', 'server.json'));
    final first = await BootstrapConfig.loadOrCreate(file);
    final second = await BootstrapConfig.loadOrCreate(file);

    expect(await file.exists(), isTrue);
    expect(first.serverId, isNotEmpty);
    expect(second.serverId, first.serverId);
    expect(first.port, Discovery.defaultPort);
    expect(first.isConfigured, isFalse);
  });

  test('persists the data directory', () async {
    final file = File(p.join(tmp.path, 'server.json'));
    await BootstrapConfig(
      serverId: 'x',
      dataDir: '/mnt/ssd/retrosteam',
    ).save(file);
    final loaded = await BootstrapConfig.loadOrCreate(file);
    expect(loaded.dataDir, '/mnt/ssd/retrosteam');
    expect(loaded.isConfigured, isTrue);
  });
}
