import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:rs_core/rs_core.dart';
import 'package:rs_server/src/artwork/artwork_files.dart';
import 'package:rs_server/src/artwork/artwork_repo.dart';
import 'package:rs_server/src/db/db.dart';
import 'package:test/test.dart';

void main() {
  late Directory root;
  late ArtworkFiles files;

  setUp(() {
    root = Directory.systemTemp.createTempSync('rs-art-');
    files = ArtworkFiles(
      artworkDir: '${root.path}/artwork',
      cacheDir: '${root.path}/cache',
    );
  });

  tearDown(() => root.deleteSync(recursive: true));

  List<int> png({int w = 8, int h = 4, bool alpha = false}) {
    final image = img.Image(width: w, height: h, numChannels: alpha ? 4 : 3);
    img.fill(image, color: img.ColorRgb8(180, 20, 40));
    if (alpha) image.getPixel(0, 0).a = 10;
    return img.encodePng(image);
  }

  test('saves a jpeg and resizes it once', () {
    final stored = files.save('box', Uint8List.fromList(png()));
    expect(stored.relPath, 'box.jpg');
    expect(stored.width, 8);
    expect(stored.height, 4);
    expect(stored.hasAlpha, isFalse);

    final small = files.variant(stored.relPath, width: 4);
    final decoded = img.decodeImage(small)!;
    expect(decoded.width, 4);
    expect(File('${root.path}/cache/box/w4.jpg').existsSync(), isTrue);

    final again = files.variant(stored.relPath, width: 4);
    expect(again, small);
    expect(files.variant(stored.relPath, width: 8), isNotEmpty);
  });

  test('keeps a transparent image as png', () {
    final stored = files.save('logo', Uint8List.fromList(png(alpha: true)));
    expect(stored.relPath, 'logo.png');
    expect(stored.hasAlpha, isTrue);
    expect(files.contentType(stored.relPath), 'image/png');
  });

  test('rejects a non-image and an unsafe id', () {
    expect(
      () => files.save('nope', Uint8List.fromList([1, 2, 3, 4])),
      throwsA(isA<ArtworkException>()),
    );
    expect(
      () => files.save('../etc', Uint8List.fromList(png())),
      throwsA(isA<ArtworkException>()),
    );
  });

  test('repo keeps an override and replaces a scrape', () {
    final db = RsDatabase.inMemory();
    addTearDown(db.close);
    RootRepo(db).upsert(
      id: 'root',
      label: 'ROMs',
      lastPath: '/roms',
      status: LibraryRootStatus.online,
    );
    final diff = GameRepo(db).upsertScanned('root', [
      ScannedGameInput(
        systemId: 'snes',
        primaryRelPath: 'snes/game.sfc',
        title: 'Game',
        files: [
          GameFileRecord(
            relPath: 'snes/game.sfc',
            size: 10,
            mtime: DateTime.utc(2026),
          ),
        ],
      ),
    ]);
    final gameId = diff.added.single;
    final repo = ArtworkRepo(db, files);

    final first = repo.putScraped(
      gameId: gameId,
      kind: ArtworkKind.cover,
      source: ArtworkSource.screenScraper,
      bytes: png(),
    )!;
    final second = repo.putScraped(
      gameId: gameId,
      kind: ArtworkKind.cover,
      source: ArtworkSource.steamGridDb,
      bytes: png(w: 6, h: 4),
    )!;
    expect(second.id, isNot(first.id));
    expect(File('${root.path}/artwork/${first.relPath}').existsSync(), isFalse);

    db.db.execute('UPDATE artwork SET is_override = 1 WHERE id = ?', [
      second.id,
    ]);
    expect(
      repo.putScraped(
        gameId: gameId,
        kind: ArtworkKind.cover,
        source: ArtworkSource.screenScraper,
        bytes: png(),
      ),
      isNull,
    );
    final selected = repo.forGames([gameId])[gameId]![ArtworkKind.cover]!;
    expect(selected.id, second.id);
    expect(selected.isOverride, isTrue);
    expect(selected.toDto().source, ArtworkSource.steamGridDb);
  });
}
