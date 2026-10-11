import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rs_core/rs_core.dart';
import 'package:rs_server/src/scrape/steamgriddb/steamgriddb_client.dart';
import 'package:rs_server/src/scrape/steamgriddb/steamgriddb_parse.dart';
import 'package:test/test.dart';

void main() {
  test('parse keeps static images and the exact name', () {
    expect(
      parseSteamGridGameId([
        {'id': 1, 'name': 'Super Mario Bros.'},
        {'id': 2, 'name': 'Super Mario World'},
      ], 'super mario world'),
      2,
    );
    final urls = parseSteamGridAssets(
      grids: [
        {
          'width': 600,
          'height': 900,
          'mime': 'image/jpeg',
          'url': 'https://cdn.test/cover.jpg',
        },
        {
          'width': 460,
          'height': 215,
          'mime': 'image/png',
          'url': 'https://cdn.test/capsule.png',
        },
        {
          'width': 600,
          'height': 900,
          'mime': 'image/jpeg',
          'url': 'https://cdn.test/later.jpg',
        },
        {
          'width': 512,
          'height': 512,
          'mime': 'image/png',
          'url': 'https://cdn.test/square.png',
        },
      ],
      heroes: [
        {'mime': 'video/webm', 'url': 'https://cdn.test/move.webm'},
        {'mime': 'image/jpeg', 'url': 'http://cdn.test/hero.jpg'},
        {'mime': 'image/jpeg', 'url': 'https://cdn.test/hero.jpg'},
      ],
      logos: [
        {'mime': 'image/png', 'url': 'https://cdn.test/logo.png'},
      ],
      icons: [
        {'url': 'https://cdn.test/icon.png'},
      ],
    );
    expect(urls, {
      ArtworkKind.cover: 'https://cdn.test/cover.jpg',
      ArtworkKind.capsule: 'https://cdn.test/capsule.png',
      ArtworkKind.hero: 'https://cdn.test/hero.jpg',
      ArtworkKind.logo: 'https://cdn.test/logo.png',
      ArtworkKind.icon: 'https://cdn.test/icon.png',
    });
  });

  test('lookup searches by name and asks for static assets', () async {
    final requests = <http.Request>[];
    final client = SteamGridDbClient(
      minInterval: Duration.zero,
      httpClient: MockClient((request) async {
        requests.add(request);
        if (request.url.path.contains('autocomplete')) {
          return http.Response(
            jsonEncode({
              'success': true,
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
                  'width': 600,
                  'height': 900,
                  'mime': 'image/png',
                  'url': 'https://cdn.test/box.png',
                },
              ],
            }),
            200,
          );
        }
        return http.Response(jsonEncode({'data': <Object>[]}), 200);
      }),
    );
    addTearDown(client.close);

    final urls = await client.lookup(apiKey: 'secret', name: 'Celeste');
    expect(urls[ArtworkKind.cover], 'https://cdn.test/box.png');
    expect(requests, hasLength(5));
    expect(requests.first.headers['authorization'], 'Bearer secret');
    expect(requests.first.url.path, endsWith('/search/autocomplete/Celeste'));
    expect(requests[1].url.queryParameters['types'], 'static');
    expect(requests[1].url.queryParameters['dimensions'], '600x900,460x215');
  });

  test('an unknown name is a miss and a quota error is not', () async {
    final missing = SteamGridDbClient(
      minInterval: Duration.zero,
      httpClient: MockClient((_) async => http.Response('nope', 404)),
    );
    addTearDown(missing.close);
    expect(await missing.lookup(apiKey: 'secret', name: 'Nope'), isEmpty);

    final limited = SteamGridDbClient(
      minInterval: Duration.zero,
      httpClient: MockClient((_) async => http.Response('quota', 429)),
    );
    addTearDown(limited.close);
    expect(
      limited.lookup(apiKey: 'secret', name: 'Celeste'),
      throwsA(
        isA<SteamGridDbException>().having((e) => e.statusCode, 'status', 429),
      ),
    );
  });
}
