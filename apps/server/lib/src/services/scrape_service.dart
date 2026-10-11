import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:rs_core/rs_core.dart';

import '../artwork/artwork_files.dart';
import '../artwork/artwork_repo.dart';
import '../db/auth_repos.dart';
import '../db/game_repo.dart';
import '../scrape/screenscraper/screenscraper_client.dart';
import '../scrape/screenscraper/screenscraper_parse.dart';
import '../scrape/steamgriddb/steamgriddb_client.dart';
import 'event_hub.dart';
import 'scraper_settings.dart';

final _log = Logger('scrape');

/// Fills missing metadata and artwork after a scan.
///
/// One scrape runs at a time. A request that arrives while one is running
/// is remembered and runs when it finishes. Credentials are read at the
/// start of each pass; with none stored, the pass does nothing.
class ScrapeService {
  ScrapeService({
    required this._games,
    required this._artwork,
    required this._settings,
    required this._events,
    ScreenScraperClient? screenScraper,
    SteamGridDbClient? steamGrid,
    http.Client? httpClient,
  }) : _screenScraper = screenScraper ?? ScreenScraperClient(),
       _steamGrid = steamGrid ?? SteamGridDbClient(),
       _http = httpClient ?? http.Client(),
       _ownsHttp = httpClient == null;

  final GameRepo _games;
  final ArtworkRepo _artwork;
  final SettingsRepo _settings;
  final EventHub _events;
  final ScreenScraperClient _screenScraper;
  final SteamGridDbClient _steamGrid;
  final http.Client _http;
  final bool _ownsHttp;

  Future<void>? _running;
  var _again = false;
  var _stopping = false;

  /// Completes when the running scrape (if any) has finished, including a
  /// pass that was queued behind it.
  Future<void> get done => _running ?? Future<void>.value();

  /// Starts a scrape in the background. Returns `false` when one is already
  /// running; that pass is followed by another.
  bool start() {
    if (_stopping) return false;
    if (_running != null) {
      _again = true;
      return false;
    }
    _running = _run().whenComplete(() {
      _running = null;
      if (_again && !_stopping) {
        _again = false;
        start();
      }
    });
    return true;
  }

  /// Stops after the current game and waits for the pass to finish.
  Future<void> shutdown() async {
    _stopping = true;
    _again = false;
    await _running;
    _screenScraper.close();
    _steamGrid.close();
    if (_ownsHttp) _http.close();
  }

  Future<void> _run() async {
    final creds = ScraperCredentials.read(_settings);
    if (creds.screenScraper == null && creds.steamGridDbApiKey == null) {
      _log.fine('Scrape skipped: no credentials stored');
      return;
    }
    final games = _games.list().games;
    final art = _artwork.forGames(games.map((game) => game.id));
    var updated = 0;
    for (final game in games) {
      if (_stopping) break;
      final have = art[game.id] ?? const {};
      if (!_needs(game, have, creds)) continue;
      try {
        final changed = await _scrapeGame(game, have, creds);
        if (!changed) continue;
        updated++;
        _events.publish(ServerEvent.libraryChanged(updatedIds: [game.id]));
      } on ScreenScraperException catch (e) {
        _log.warning('ScreenScraper stopped the scrape: $e');
        break;
      } on SteamGridDbException catch (e) {
        _log.warning('SteamGridDB stopped the scrape: $e');
        break;
      } on Object catch (e, st) {
        _log.warning('Could not scrape "${game.title}"', e, st);
      }
    }
    _log.info('Scrape finished: $updated game(s) updated');
  }

  bool _needs(
    GameRecord game,
    Map<ArtworkKind, ArtworkRecord> have,
    ScraperCredentials creds,
  ) {
    if (creds.screenScraper != null) {
      if (_blank(game.description) ||
          _blank(game.developer) ||
          _blank(game.publisher) ||
          game.releaseYear == null) {
        return true;
      }
      for (final kind in _screenScraperKinds) {
        if (!have.containsKey(kind)) return true;
      }
    }
    if (creds.steamGridDbApiKey != null) {
      for (final kind in _steamGridKinds) {
        if (!have.containsKey(kind)) return true;
      }
    }
    return false;
  }

  Future<bool> _scrapeGame(
    GameRecord game,
    Map<ArtworkKind, ArtworkRecord> have,
    ScraperCredentials creds,
  ) async {
    final fromScreenScraper = <ArtworkKind, String>{};
    final fromSteamGrid = <ArtworkKind, String>{};
    var changed = false;
    final login = creds.screenScraper;
    if (login != null && _needsScreenScraper(game, have)) {
      final hit = await _lookupScreenScraper(login, game);
      if (hit != null) {
        changed = _fillMetadata(game, hit) || changed;
        fromScreenScraper.addAll(hit.mediaUrls);
      }
    }
    final apiKey = creds.steamGridDbApiKey;
    if (apiKey != null && _missing(_steamGridKinds, have, fromScreenScraper)) {
      fromSteamGrid.addAll(
        await _steamGrid.lookup(apiKey: apiKey, name: game.title),
      );
    }
    for (final kind in _scrapeKinds) {
      if (have.containsKey(kind)) continue;
      final scraped = fromScreenScraper[kind];
      if (scraped != null) {
        if (await _store(game.id, kind, ArtworkSource.screenScraper, scraped)) {
          changed = true;
        }
        continue;
      }
      final grid = fromSteamGrid[kind];
      if (grid == null) continue;
      if (await _store(game.id, kind, ArtworkSource.steamGridDb, grid)) {
        changed = true;
      }
    }
    return changed;
  }

  bool _needsScreenScraper(
    GameRecord game,
    Map<ArtworkKind, ArtworkRecord> have,
  ) =>
      _blank(game.description) ||
      _blank(game.developer) ||
      _blank(game.publisher) ||
      game.releaseYear == null ||
      _screenScraperKinds.any((kind) => !have.containsKey(kind));

  Future<ScrapedGame?> _lookupScreenScraper(
    ScreenScraperCredentials login,
    GameRecord game,
  ) {
    final file = game.files.isEmpty ? null : game.files.first;
    if (file == null ||
        (file.crc32 == null && file.md5 == null && file.sha1 == null)) {
      return Future<ScrapedGame?>.value();
    }
    return _screenScraper.lookup(
      credentials: login,
      systemId: game.systemId,
      crc32: file.crc32,
      md5: file.md5,
      sha1: file.sha1,
      fileName: _fileName(game.primaryRelPath),
    );
  }

  bool _fillMetadata(GameRecord game, ScrapedGame hit) {
    final description = _blank(game.description)
        ? _text(hit.description)
        : null;
    final developer = _blank(game.developer) ? _text(hit.developer) : null;
    final publisher = _blank(game.publisher) ? _text(hit.publisher) : null;
    final year = game.releaseYear == null ? hit.releaseYear : null;
    if (description == null &&
        developer == null &&
        publisher == null &&
        year == null) {
      return false;
    }
    _games.updateMetadata(
      game.id,
      description: description,
      developer: developer,
      publisher: publisher,
      releaseYear: year,
    );
    return true;
  }

  Future<bool> _store(
    String gameId,
    ArtworkKind kind,
    ArtworkSource source,
    String url,
  ) async {
    final bytes = await _download(url);
    if (bytes == null) return false;
    try {
      return _artwork.putScraped(
            gameId: gameId,
            kind: kind,
            source: source,
            bytes: bytes,
          ) !=
          null;
    } on ArtworkException catch (e) {
      _log.fine('Rejected $kind for $gameId: $e');
      return false;
    }
  }

  Future<List<int>?> _download(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https') return null;
    final http.Response response;
    try {
      response = await _http.get(uri);
    } on Object catch (e) {
      _log.fine('Artwork download failed: $e');
      return null;
    }
    if (response.statusCode != 200) return null;
    final declared = response.contentLength;
    if (declared != null && declared > ArtworkFiles.maxBytes) return null;
    if (response.bodyBytes.length > ArtworkFiles.maxBytes) return null;
    return response.bodyBytes;
  }

  static bool _missing(
    List<ArtworkKind> kinds,
    Map<ArtworkKind, ArtworkRecord> have,
    Map<ArtworkKind, String> found,
  ) => kinds.any((kind) => !have.containsKey(kind) && !found.containsKey(kind));

  static bool _blank(String? value) => value == null || value.trim().isEmpty;

  static String? _text(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  static String _fileName(String relPath) {
    final slash = relPath.lastIndexOf('/');
    return slash < 0 ? relPath : relPath.substring(slash + 1);
  }
}

const _scrapeKinds = [
  ArtworkKind.cover,
  ArtworkKind.hero,
  ArtworkKind.logo,
  ArtworkKind.screenshot,
  ArtworkKind.capsule,
  ArtworkKind.icon,
];

const _screenScraperKinds = [
  ArtworkKind.cover,
  ArtworkKind.hero,
  ArtworkKind.logo,
  ArtworkKind.screenshot,
];

const _steamGridKinds = [
  ArtworkKind.cover,
  ArtworkKind.hero,
  ArtworkKind.logo,
  ArtworkKind.capsule,
  ArtworkKind.icon,
];
