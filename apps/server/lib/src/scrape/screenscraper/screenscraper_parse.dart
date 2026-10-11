import 'package:rs_core/rs_core.dart';

/// What ScreenScraper knows about one ROM.
class ScrapedGame {
  const ScrapedGame({
    this.title,
    this.description,
    this.developer,
    this.publisher,
    this.releaseYear,
    this.mediaUrls = const {},
  });

  final String? title;
  final String? description;
  final String? developer;
  final String? publisher;
  final int? releaseYear;

  /// Best media URL for each artwork kind ScreenScraper covers.
  final Map<ArtworkKind, String> mediaUrls;

  bool get isEmpty =>
      title == null &&
      description == null &&
      developer == null &&
      publisher == null &&
      releaseYear == null &&
      mediaUrls.isEmpty;
}

/// Parses a `jeuInfos.php?output=json` body. Returns `null` when the ROM
/// is unknown or the document is not a successful game payload.
ScrapedGame? parseJeuInfos(Map<String, dynamic> json) {
  final header = json['header'];
  if (header is Map &&
      header['success'] != null &&
      !_truthy(header['success'])) {
    return null;
  }
  final response = json['response'];
  if (response is! Map) return null;
  final jeu = response['jeu'];
  if (jeu is! Map) return null;

  final title = _localized(jeu['noms'], regionKey: 'region');
  final description = _localized(jeu['synopsis'], regionKey: 'langue');
  final developer = _text(jeu['developpeur']);
  final publisher = _text(jeu['editeur']);
  final year = _year(jeu['dates']);
  final media = _media(jeu['medias']);
  final game = ScrapedGame(
    title: title,
    description: description,
    developer: developer,
    publisher: publisher,
    releaseYear: year,
    mediaUrls: media,
  );
  return game.isEmpty ? null : game;
}

bool _truthy(Object? value) => value == true || value == 'true' || value == 1;

/// Region order for titles (`region`) and descriptions (`langue`).
const _regions = ['us', 'wor', 'en', 'eu', 'jp', 'ss'];

String? _localized(Object? raw, {required String regionKey}) {
  final items = _asList(raw);
  if (items.isEmpty) return _text(raw);
  String? fallback;
  final ranked = <String, String>{};
  for (final item in items) {
    final text = _text(item);
    if (text == null) continue;
    fallback ??= text;
    if (item is Map) {
      final region = item[regionKey]?.toString().toLowerCase();
      if (region != null) ranked.putIfAbsent(region, () => text);
    }
  }
  for (final region in _regions) {
    final text = ranked[region];
    if (text != null) return text;
  }
  return fallback;
}

String? _text(Object? raw) {
  if (raw is String) {
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
  if (raw is Map && raw['text'] != null) return _text(raw['text']);
  return null;
}

int? _year(Object? raw) {
  final items = _asList(raw);
  final texts = [
    for (final item in items.isEmpty ? [raw] : items) _text(item),
  ].whereType<String>();
  for (final region in _regions) {
    for (final item in items) {
      if (item is! Map) continue;
      if (item['region']?.toString().toLowerCase() != region) continue;
      final year = _yearOf(_text(item));
      if (year != null) return year;
    }
  }
  for (final text in texts) {
    final year = _yearOf(text);
    if (year != null) return year;
  }
  return null;
}

int? _yearOf(String? text) {
  if (text == null) return null;
  final match = RegExp(r'(19|20)\d{2}').firstMatch(text);
  return match == null ? null : int.tryParse(match.group(0)!);
}

const _mediaRank = <String, ArtworkKind>{
  'box-2d': ArtworkKind.cover,
  'box-3d': ArtworkKind.cover,
  'fanart': ArtworkKind.hero,
  'wheel-hd': ArtworkKind.logo,
  'wheel': ArtworkKind.logo,
  'screen': ArtworkKind.screenshot,
};

Map<ArtworkKind, String> _media(Object? raw) {
  final best = <ArtworkKind, ({int score, String url})>{};
  for (final item in _asList(raw)) {
    if (item is! Map) continue;
    final type = item['type']?.toString().toLowerCase();
    final kind = type == null ? null : _mediaRank[type];
    final url = item['url']?.toString();
    if (kind == null || url == null || !url.startsWith('https://')) continue;
    final region = item['region']?.toString().toLowerCase();
    final regionScore = switch (region) {
      'us' => 0,
      'wor' => 1,
      'eu' => 2,
      'jp' => 3,
      'ss' => 4,
      _ => 5,
    };
    // box-2D beats box-3D, wheel-hd beats wheel, at the same region.
    final typeScore = switch (type) {
      'box-2d' || 'wheel-hd' => 0,
      _ => 1,
    };
    final score = regionScore * 10 + typeScore;
    final current = best[kind];
    if (current == null || score < current.score) {
      best[kind] = (score: score, url: url);
    }
  }
  return {for (final e in best.entries) e.key: e.value.url};
}

List<Object?> _asList(Object? raw) {
  if (raw is List) return raw;
  if (raw is Map) return [raw];
  return const [];
}
