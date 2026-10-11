import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'screenscraper_parse.dart';
import 'screenscraper_systems.dart';

/// Developer and user login for the ScreenScraper API.
class ScreenScraperCredentials {
  const ScreenScraperCredentials({
    required this.devId,
    required this.devPassword,
    required this.username,
    required this.password,
  });

  final String devId;
  final String devPassword;
  final String username;
  final String password;
}

/// The API refused the call (quota, auth, or a transport failure).
class ScreenScraperException implements Exception {
  const ScreenScraperException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'ScreenScraperException($statusCode): $message';
}

/// Looks games up on ScreenScraper by ROM hash.
///
/// Requests are serialized with [minInterval] between them so a library
/// scrape cannot burst the account quota.
class ScreenScraperClient {
  ScreenScraperClient({
    http.Client? httpClient,
    this.minInterval = const Duration(milliseconds: 1200),
    this.softName = 'retrosteam',
    Future<void> Function(Duration)? delay,
  }) : _http = httpClient ?? http.Client(),
       _ownsClient = httpClient == null,
       _delay = delay ?? Future<void>.delayed;

  static final _endpoint = Uri.https(
    'www.screenscraper.fr',
    '/api2/jeuInfos.php',
  );

  final http.Client _http;
  final bool _ownsClient;
  final Duration minInterval;
  final String softName;
  final Future<void> Function(Duration) _delay;

  Future<void> _tail = Future<void>.value();

  /// Closes the HTTP client when this object created it.
  void close() {
    if (_ownsClient) _http.close();
  }

  /// One ROM. [systemId] is an EmulationStation folder name. Returns `null`
  /// when ScreenScraper does not know the hash.
  Future<ScrapedGame?> lookup({
    required ScreenScraperCredentials credentials,
    String? systemId,
    String? crc32,
    String? md5,
    String? sha1,
    String? fileName,
  }) {
    if (crc32 == null && md5 == null && sha1 == null) {
      throw const ScreenScraperException('A lookup needs a ROM hash.');
    }
    return _paced(() async {
      final systemeid = systemId == null
          ? null
          : screenScraperSystemId(systemId);
      final hit = await _fetch(
        credentials,
        crc32: crc32,
        md5: md5,
        sha1: sha1,
        fileName: fileName,
        systemeid: systemeid,
      );
      if (hit != null || systemeid == null) return hit;
      return _fetch(
        credentials,
        crc32: crc32,
        md5: md5,
        sha1: sha1,
        fileName: fileName,
      );
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

  Future<ScrapedGame?> _fetch(
    ScreenScraperCredentials credentials, {
    String? crc32,
    String? md5,
    String? sha1,
    String? fileName,
    int? systemeid,
  }) async {
    final uri = _endpoint.replace(
      queryParameters: {
        'devid': credentials.devId,
        'devpassword': credentials.devPassword,
        'softname': softName,
        'output': 'json',
        'ssid': credentials.username,
        'sspassword': credentials.password,
        'crc': ?crc32,
        'md5': ?md5,
        'sha1': ?sha1,
        if (systemeid != null) 'systemeid': '$systemeid',
        'romnom': ?fileName,
        'romtype': 'rom',
      },
    );
    final http.Response response;
    try {
      response = await _http.get(uri);
    } on Object catch (e) {
      throw ScreenScraperException('Could not reach ScreenScraper: $e');
    }
    if (response.statusCode == 404) return null;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ScreenScraperException(
        'ScreenScraper answered ${response.statusCode}.',
        statusCode: response.statusCode,
      );
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const ScreenScraperException('ScreenScraper did not return JSON.');
    }
    if (decoded is! Map) return null;
    return parseJeuInfos(Map<String, dynamic>.from(decoded));
  }
}
