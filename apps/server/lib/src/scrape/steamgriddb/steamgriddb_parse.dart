import 'package:rs_core/rs_core.dart';

/// Picks static HTTPS images out of SteamGridDB asset lists.
///
/// Grids of 600×900 become [ArtworkKind.cover] and 460×215 become
/// [ArtworkKind.capsule]. Heroes, logos, and icons map straight across.
/// The first usable image of each kind wins.
Map<ArtworkKind, String> parseSteamGridAssets({
  required List<dynamic> grids,
  required List<dynamic> heroes,
  required List<dynamic> logos,
  required List<dynamic> icons,
}) {
  final urls = <ArtworkKind, String>{};
  for (final item in grids) {
    if (item is! Map) continue;
    final kind = switch ((item['width'], item['height'])) {
      (600, 900) => ArtworkKind.cover,
      (460, 215) => ArtworkKind.capsule,
      _ => null,
    };
    final url = _imageUrl(item);
    if (kind == null || url == null || urls.containsKey(kind)) continue;
    urls[kind] = url;
  }
  _first(urls, ArtworkKind.hero, heroes);
  _first(urls, ArtworkKind.logo, logos);
  _first(urls, ArtworkKind.icon, icons);
  return urls;
}

/// The game id from an autocomplete payload, preferring an exact name.
int? parseSteamGridGameId(List<dynamic> games, String name) {
  final wanted = name.trim().toLowerCase();
  int? first;
  for (final item in games) {
    if (item is! Map) continue;
    final id = item['id'];
    if (id is! int) continue;
    first ??= id;
    final label = item['name'];
    if (label is String && label.trim().toLowerCase() == wanted) return id;
  }
  return first;
}

void _first(
  Map<ArtworkKind, String> urls,
  ArtworkKind kind,
  List<dynamic> items,
) {
  if (urls.containsKey(kind)) return;
  for (final item in items) {
    if (item is! Map) continue;
    final url = _imageUrl(item);
    if (url == null) continue;
    urls[kind] = url;
    return;
  }
}

String? _imageUrl(Map<dynamic, dynamic> item) {
  final mime = item['mime'];
  if (mime is String && !mime.startsWith('image/')) return null;
  final url = item['url'];
  if (url is! String || !url.startsWith('https://')) return null;
  return url;
}
