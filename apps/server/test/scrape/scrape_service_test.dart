import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image/image.dart' as img;
import 'package:rs_core/rs_core.dart';
import 'package:rs_server/src/artwork/artwork_files.dart';
import 'package:rs_server/src/artwork/artwork_repo.dart';
import 'package:rs_server/src/db/db.dart';
import 'package:rs_server/src/scrape/screenscraper/screenscraper_client.dart';
import 'package:rs_server/src/scrape/steamgriddb/steamgriddb_client.dart';
import 'package:rs_server/src/services/event_hub.dart';
import 'package:rs_server/src/services/scrape_service.dart';
import 'package:rs_server/src/services/scraper_settings.dart';
import 'package:test/test.dart';

void main() {
  late Directory root;
  late RsDatabase db;
  late ArtworkRepo artwork;
  late SettingsRepo settings;
  late EventHub events;
  late List<ServerEvent> published;

  setUp(() {
    root = Directory.systemTemp.createTempSync('rs-scrape-');
    db = RsDatabase.inMemory();
    artwork = ArtworkRepo(
      db,
      ArtworkFiles(
        artworkDir: '${root.path}/artwork',
        cacheDir: '${root.path}/cache',
      ),
    );
    settings = SettingsRepo(db);
    events = EventHub();
    published = [];
    events.stream.listen(published.add);
    RootRepo(db).upsert(
      id: 'root',
      label: 'ROMs',
      lastPath: '/roms',
      status: LibraryRootStatus.online,
    );
  });

  tearDown(() async {
    db.close();
    root.deleteSync(recursive: true);
  });

  String addGame({String title = 'Game', String crc32 = 'abc'}) {
    return GameRepo(db)
        .upsertScanned('root', [
          ScannedGameInput(
            systemId: 'snes',
            primaryRelPath: 'snes/game.sfc',
            title: title,
            files: [
              GameFileRecord(
                relPath: 'snes/game.sfc',
                size: 10,
                mtime: DateTime.utc(2026),
                crc32: crc32,
              ),
            ],
          ),
        ])
        .added
        .single;
  }

  Uint8List png() {
    final image = img.Image(width: 4, height: 4, numChannels: 3);
    img.fill(image, color: img.ColorRgb8(10, 20, 30));
    return img.encodePng(image);
  }

  ScrapeService service({
    required MockClientHandler screenScraper,
    MockClientHandler? steamGrid,
    required MockClientHandler download,
  }) {
    final scrape = ScrapeService(
      games: GameRepo(db),
      artwork: artwork,
      settings: settings,
      events: events,
      screenScraper: ScreenScraperClient(
        minInterval: Duration.zero,
        httpClient: MockClient(screenScraper),
      ),
      steamGrid: SteamGridDbClient(
        minInterval: Duration.zero,
        httpClient: MockClient(
          steamGrid ??
              (_) async => http.Response(jsonEncode({'data': <Object>[]}), 200),
        ),
      ),
      httpClient: MockClient(download),
    );
    addTearDown(scrape.shutdown);
    return scrape;
  }

  test('no credentials leaves the library alone', () async {
    addGame();
    var calls = 0;
    final scrape = service(
      screenScraper: (_) async {
        calls++;
        return http.Response('no', 500);
      },
      download: (_) async {
        calls++;
        return http.Response('no', 500);
      },
    );
    expect(scrape.start(), isTrue);
    await scrape.done;
    expect(calls, 0);
    expect(published, isEmpty);
  });

  test('fills empty metadata and art, then skips a complete game', () async {
    final gameId = addGame(title: 'Super Mario World');
    final downloads = <String>[];
    var lookups = 0;
    final scrape = service(
      screenScraper: (_) async {
        lookups++;
        return http.Response(jsonEncode(_jeu()), 200);
      },
      download: (request) async {
        downloads.add(request.url.toString());
        return http.Response.bytes(png(), 200);
      },
    );
    ScraperCredentials.apply(
      settings,
      const ScraperSettingsUpdate(
        screenScraper: ScreenScraperLogin(
          devId: 'dev',
          devPassword: 'dev-secret',
          username: 'user',
          password: 'user-secret',
        ),
      ),
    );

    expect(scrape.start(), isTrue);
    await scrape.done;

    final game = GameRepo(db).byId(gameId)!;
    expect(game.description, 'A plumber saves the dinosaur.');
    expect(game.developer, 'Nintendo');
    expect(game.releaseYear, 1991);
    final art = artwork.forGames([gameId])[gameId]!;
    expect(art[ArtworkKind.cover]?.source, ArtworkSource.screenScraper);
    expect(art.keys, containsAll(_screenKinds));
    expect(downloads, hasLength(_screenKinds.length));
    await Future<void>.delayed(Duration.zero);
    expect(published.whereType<LibraryChangedEvent>(), hasLength(1));

    final lookupsAfter = lookups;
    expect(scrape.start(), isTrue);
    await scrape.done;
    expect(lookups, lookupsAfter);
  });

  test('an override is left in place', () async {
    final gameId = addGame();
    final existing = artwork.putScraped(
      gameId: gameId,
      kind: ArtworkKind.cover,
      source: ArtworkSource.upload,
      bytes: png(),
    )!;
    db.db.execute('UPDATE artwork SET is_override = 1 WHERE id = ?', [
      existing.id,
    ]);
    final downloads = <String>[];
    final scrape = service(
      screenScraper: (_) async => http.Response(
        jsonEncode({
          'response': {
            'jeu': {
              'synopsis': [
                {'langue': 'en', 'text': 'Saved.'},
              ],
              'medias': [
                {
                  'type': 'box-2D',
                  'region': 'us',
                  'url': 'https://images.test/cover.png',
                },
              ],
            },
          },
        }),
        200,
      ),
      download: (request) async {
        downloads.add(request.url.path);
        return http.Response.bytes(png(), 200);
      },
    );
    ScraperCredentials.apply(
      settings,
      const ScraperSettingsUpdate(
        screenScraper: ScreenScraperLogin(
          devId: 'dev',
          devPassword: 'secret',
          username: 'user',
          password: 'secret',
        ),
      ),
    );
    expect(scrape.start(), isTrue);
    await scrape.done;

    expect(GameRepo(db).byId(gameId)!.description, 'Saved.');
    expect(
      artwork.forGames([gameId])[gameId]![ArtworkKind.cover]!.id,
      existing.id,
    );
    expect(downloads, isEmpty);
  });

  test('SteamGridDB fills the kinds ScreenScraper does not have', () async {
    final gameId = addGame(title: 'Celeste');
    final scrape = service(
      screenScraper: (_) async => http.Response('unused', 500),
      steamGrid: (request) async {
        if (request.url.path.contains('autocomplete')) {
          return http.Response(
            jsonEncode({
              'data': [
                {'id': 9, 'name': 'Celeste'},
              ],
            }),
            200,
          );
        }
        if (request.url.path.contains('/grids/')) {
          return http.Response(
            jsonEncode({
              'data': [
                {
                  'width': 460,
                  'height': 215,
                  'mime': 'image/png',
                  'url': 'https://cdn.test/capsule.png',
                },
              ],
            }),
            200,
          );
        }
        if (request.url.path.contains('/icons/')) {
          return http.Response(
            jsonEncode({
              'data': [
                {'mime': 'image/png', 'url': 'https://cdn.test/icon.png'},
              ],
            }),
            200,
          );
        }
        return http.Response(jsonEncode({'data': <Object>[]}), 200);
      },
      download: (_) async => http.Response.bytes(png(), 200),
    );
    ScraperCredentials.apply(
      settings,
      const ScraperSettingsUpdate(steamGridDbApiKey: 'secret'),
    );
    expect(scrape.start(), isTrue);
    await scrape.done;
    final art = artwork.forGames([gameId])[gameId]!;
    expect(art[ArtworkKind.capsule]?.source, ArtworkSource.steamGridDb);
    expect(art[ArtworkKind.icon]?.source, ArtworkSource.steamGridDb);
    expect(art.containsKey(ArtworkKind.cover), isFalse);
  });

  test(
    'empty credentials clear a provider and a partial login is rejected',
    () {
      const login = ScreenScraperLogin(
        devId: 'dev',
        devPassword: 'secret',
        username: 'user',
        password: 'secret',
      );
      ScraperCredentials.apply(
        settings,
        const ScraperSettingsUpdate(
          screenScraper: login,
          steamGridDbApiKey: 'grid',
        ),
      );
      expect(ScraperCredentials.read(settings).status.screenScraper, isTrue);
      expect(ScraperCredentials.read(settings).status.steamGridDb, isTrue);

      ScraperCredentials.apply(
        settings,
        const ScraperSettingsUpdate(steamGridDbApiKey: ''),
      );
      expect(ScraperCredentials.read(settings).steamGridDbApiKey, isNull);

      expect(
        () => ScraperCredentials.apply(
          settings,
          const ScraperSettingsUpdate(
            screenScraper: ScreenScraperLogin(
              devId: 'dev',
              devPassword: '',
              username: 'user',
              password: 'secret',
            ),
          ),
        ),
        throwsA(isA<ScraperSettingsException>()),
      );
      expect(ScraperCredentials.read(settings).screenScraper?.devId, 'dev');
    },
  );
}

const _screenKinds = [
  ArtworkKind.cover,
  ArtworkKind.hero,
  ArtworkKind.logo,
  ArtworkKind.screenshot,
];

Map<String, Object?> _jeu() => {
  'response': {
    'jeu': {
      'synopsis': [
        {'langue': 'en', 'text': 'A plumber saves the dinosaur.'},
      ],
      'developpeur': {'text': 'Nintendo'},
      'editeur': {'text': 'Nintendo'},
      'dates': [
        {'region': 'us', 'text': '1991'},
      ],
      'medias': [
        {
          'type': 'box-2D',
          'region': 'us',
          'url': 'https://images.test/cover.png',
        },
        {
          'type': 'fanart',
          'region': 'us',
          'url': 'https://images.test/hero.jpg',
        },
        {
          'type': 'wheel',
          'region': 'wor',
          'url': 'https://images.test/logo.png',
        },
        {
          'type': 'screen',
          'region': 'us',
          'url': 'https://images.test/shot.png',
        },
      ],
    },
  },
};
