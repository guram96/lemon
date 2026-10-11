import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rs_core/rs_core.dart';
import 'package:rs_server/src/scrape/screenscraper/screenscraper_client.dart';
import 'package:rs_server/src/scrape/screenscraper/screenscraper_parse.dart';
import 'package:rs_server/src/scrape/screenscraper/screenscraper_systems.dart';
import 'package:test/test.dart';

const _creds = ScreenScraperCredentials(
  devId: 'dev',
  devPassword: 'dev-secret',
  username: 'user',
  password: 'user-secret',
);

void main() {
  test('system ids cover the common folders', () {
    expect(screenScraperSystemId('snes'), 4);
    expect(screenScraperSystemId('nes'), 3);
    expect(screenScraperSystemId('megadrive'), 1);
    expect(screenScraperSystemId('genesis'), 1);
    expect(screenScraperSystemId('not-a-system'), isNull);
  });

  test('parse prefers a US title and the flat box art', () {
    final game = parseJeuInfos({
      'header': {'success': 'true'},
      'response': {
        'jeu': {
          'noms': [
            {'region': 'jp', 'text': 'スーパーマリオ'},
            {'region': 'us', 'text': 'Super Mario World'},
          ],
          'synopsis': [
            {'langue': 'en', 'text': 'A plumber saves the dinosaur.'},
          ],
          'developpeur': {'text': 'Nintendo EAD'},
          'editeur': {'text': 'Nintendo'},
          'dates': [
            {'region': 'us', 'text': '1991-08-13'},
          ],
          'medias': [
            {
              'type': 'box-3D',
              'region': 'us',
              'url': 'https://example.test/box3d.png',
            },
            {
              'type': 'box-2D',
              'region': 'eu',
              'url': 'https://example.test/box2d.png',
            },
            {
              'type': 'box-2D',
              'region': 'us',
              'url': 'https://example.test/box-us.png',
            },
            {
              'type': 'wheel',
              'region': 'wor',
              'url': 'https://example.test/wheel.png',
            },
            {
              'type': 'fanart',
              'region': 'ss',
              'url': 'https://example.test/hero.jpg',
            },
            {'type': 'screen', 'url': 'http://insecure.test/shot.png'},
          ],
        },
      },
    });

    expect(game!.title, 'Super Mario World');
    expect(game.description, 'A plumber saves the dinosaur.');
    expect(game.developer, 'Nintendo EAD');
    expect(game.publisher, 'Nintendo');
    expect(game.releaseYear, 1991);
    expect(
      game.mediaUrls[ArtworkKind.cover],
      'https://example.test/box-us.png',
    );
    expect(game.mediaUrls[ArtworkKind.logo], 'https://example.test/wheel.png');
    expect(game.mediaUrls[ArtworkKind.hero], 'https://example.test/hero.jpg');
    expect(game.mediaUrls.containsKey(ArtworkKind.screenshot), isFalse);
  });

  test('an unknown ROM is a miss', () {
    expect(
      parseJeuInfos({
        'header': {'success': 'false'},
        'response': {'jeu': <String, Object?>{}},
      }),
      isNull,
    );
  });

  test('lookup sends the hash and retries without a system id', () async {
    final requests = <Uri>[];
    var calls = 0;
    final client = ScreenScraperClient(
      minInterval: Duration.zero,
      httpClient: MockClient((request) async {
        requests.add(request.url);
        calls++;
        if (calls == 1) {
          return http.Response(
            jsonEncode({
              'header': {'success': 'false'},
            }),
            200,
          );
        }
        return http.Response(
          jsonEncode({
            'response': {
              'jeu': {
                'noms': [
                  {'region': 'us', 'text': 'Super Mario Bros.'},
                ],
              },
            },
          }),
          200,
        );
      }),
    );
    addTearDown(client.close);

    final hit = await client.lookup(
      credentials: _creds,
      systemId: 'nes',
      crc32: 'abc',
      fileName: 'mario.nes',
    );
    expect(hit?.title, 'Super Mario Bros.');
    expect(requests, hasLength(2));
    expect(requests.first.queryParameters['systemeid'], '3');
    expect(requests.first.queryParameters['crc'], 'abc');
    expect(requests.first.queryParameters['devid'], 'dev');
    expect(requests.last.queryParameters.containsKey('systemeid'), isFalse);
  });

  test('a quota error is not treated as a miss', () async {
    final client = ScreenScraperClient(
      minInterval: Duration.zero,
      httpClient: MockClient((_) async => http.Response('quota', 429)),
    );
    addTearDown(client.close);
    expect(
      client.lookup(credentials: _creds, sha1: 'abc'),
      throwsA(
        isA<ScreenScraperException>().having(
          (e) => e.statusCode,
          'status',
          429,
        ),
      ),
    );
  });
}
