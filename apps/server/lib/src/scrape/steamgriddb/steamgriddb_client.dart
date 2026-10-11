import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:rs_core/rs_core.dart';

import 'steamgriddb_parse.dart';

/// SteamGridDB refused the call (auth, quota, or a transport failure).
class SteamGridDbException implements Exception {
  const SteamGridDbException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'SteamGridDbException($statusCode): $message';
}

/// Looks up Steam-style artwork by game name.
///
/// Requests are serialized with [minInterval] between them. Only static
/// images are requested.
class SteamGridDbClient {
  SteamGridDbClient({
    http.Client? httpClient,
    this.minInterval = const Duration(milliseconds: 1200),
    Future<void> Function(Duration)? delay,
  }) : _http = httpClient ?? http.Client(),
       _ownsClient = httpClient == null,
       _delay = delay ?? Future<void>.delayed;

  static const _host = 'www.steamgriddb.com';

  final http.Client _http;
  final bool _ownsClient;
  final Duration minInterval;
  final Future<void> Function(Duration) _delay;

  Future<void> _tail = Future<void>.value();

  /// Closes the HTTP client when this object created it.
  void close() {
    if (_ownsClient) _http.close();
  }

  /// Artwork URLs keyed by kind. Empty when the name matches nothing.
  Future<Map<ArtworkKind, String>> lookup({
    required String apiKey,
    required String name,
  }) async {
    final trimmed = name.trim();
    if (apiKey.isEmpty) {
      throw const SteamGridDbException('SteamGridDB needs an API key.');
    }
    if (trimmed.isEmpty) return const {};

    final found = await _get(
      apiKey,
      Uri.https(
        _host,
        '/api/v2/search/autocomplete',
      ).replace(pathSegments: ['api', 'v2', 'search', 'autocomplete', trimmed]),
    );
    if (found == null) return const {};
    final id = parseSteamGridGameId(found, trimmed);
    if (id == null) return const {};

    final grids = await _get(
      apiKey,
      Uri.https(_host, '/api/v2/grids/game/$id', {
        'dimensions': '600x900,460x215',
        'types': 'static',
      }),
    );
    final heroes = await _get(
      apiKey,
      Uri.https(_host, '/api/v2/heroes/game/$id', {'types': 'static'}),
    );
    final logos = await _get(
      apiKey,
      Uri.https(_host, '/api/v2/logos/game/$id', {'types': 'static'}),
    );
    final icons = await _get(
      apiKey,
      Uri.https(_host, '/api/v2/icons/game/$id', {'types': 'static'}),
    );
    return parseSteamGridAssets(
      grids: grids ?? const [],
      heroes: heroes ?? const [],
      logos: logos ?? const [],
      icons: icons ?? const [],
    );
  }

  /// `null` when the resource does not exist.
  Future<List<dynamic>?> _get(String apiKey, Uri uri) {
    return _paced(() async {
      final http.Response response;
      try {
        response = await _http.get(
          uri,
          headers: {'authorization': 'Bearer $apiKey'},
        );
      } on Object catch (e) {
        throw SteamGridDbException('Could not reach SteamGridDB: $e');
      }
      if (response.statusCode == 404) return null;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw SteamGridDbException(
          'SteamGridDB answered ${response.statusCode}.',
          statusCode: response.statusCode,
        );
      }
      final Object? decoded;
      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        throw const SteamGridDbException('SteamGridDB did not return JSON.');
      }
      if (decoded is! Map) return const [];
      final data = decoded['data'];
      if (data is! List) return const [];
      return data;
    });
  }

  Future<T> _paced<T>(Future<T> Function() action) {
    final run = _tail.then((_) async {
      final result = await action();
      if (minInterval > Duration.zero) await _delay(minInterval);
      return result;
    });
    _tail = run.then((_) {}, onError: (_, _) {});
    return run;
  }
}
