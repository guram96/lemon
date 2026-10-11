import 'dart:convert';

import 'package:rs_core/rs_core.dart';
import 'package:test/test.dart';

void main() {
  test('Game round-trips through JSON', () {
    const game = Game(
      id: 'g1',
      systemId: 'psx',
      title: 'Final Fantasy VII',
      rootId: 'r1',
      files: [
        GameFile(path: 'ff7/disc1.chd', sizeBytes: 100),
        GameFile(path: 'ff7/disc2.chd', sizeBytes: 50),
      ],
      artwork: {
        ArtworkKind.cover: Artwork(
          id: 'a1',
          kind: ArtworkKind.cover,
          source: ArtworkSource.steamGridDb,
        ),
      },
    );

    final json = _deepJson(game.toJson());
    expect(Game.fromJson(json), game);
    expect(game.sizeBytes, 150);
  });

  test('ServerInfo round-trips through JSON', () {
    const info = ServerInfo(
      serverId: 's1',
      name: 'Desk',
      version: '0.1.0',
      apiVersion: ApiRoutes.version,
      setupState: ServerSetupState.unconfigured,
    );
    expect(ServerInfo.fromJson(_deepJson(info.toJson())), info);
  });
}

/// Encodes to a JSON string and back, exactly as the HTTP layer does.
Map<String, Object?> _deepJson(Map<String, Object?> json) =>
    jsonDecode(jsonEncode(json)) as Map<String, Object?>;
