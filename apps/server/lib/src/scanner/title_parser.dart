/// Turns ROM file names (No-Intro / Redump / GoodTools style) into display
/// titles, plus region and disc number.
library;

/// The parts parsed out of a ROM file name.
class ParsedTitle {
  const ParsedTitle({
    required this.title,
    this.region,
    this.disc,
    this.tags = const [],
  });

  /// Display title without extension and tags.
  final String title;

  /// Canonical region, e.g. `USA` or `USA, Europe`. Null if no region tag.
  final String? region;

  /// Disc number from `(Disc N)`, `(Disk N of M)`, `(CD N)`. Null if none.
  final int? disc;

  /// Raw content of every `(…)` and `[…]` tag, in order.
  final List<String> tags;
}

final _tagPattern = RegExp(r'\(([^()]*)\)|\[([^\[\]]*)\]');
final _discPattern = RegExp(
  r'^(?:disc|disk|cd)\s*(\d+)(?:\s*of\s*\d+)?$',
  caseSensitive: false,
);
final _goodToolsCode = RegExp(r'^[UEJWKBAFGSIC]{1,4}$');
final _extension = RegExp(r'\.[A-Za-z0-9]{1,6}$');
final _articleSuffix = RegExp(r'^(.*), (The|A|An)$');

const _regionNames = <String, String>{
  'usa': 'USA',
  'us': 'USA',
  'america': 'USA',
  'europe': 'Europe',
  'eu': 'Europe',
  'japan': 'Japan',
  'jp': 'Japan',
  'world': 'World',
  'korea': 'Korea',
  'china': 'China',
  'taiwan': 'Taiwan',
  'hong kong': 'Hong Kong',
  'asia': 'Asia',
  'australia': 'Australia',
  'brazil': 'Brazil',
  'canada': 'Canada',
  'france': 'France',
  'germany': 'Germany',
  'spain': 'Spain',
  'italy': 'Italy',
  'netherlands': 'Netherlands',
  'sweden': 'Sweden',
  'scandinavia': 'Scandinavia',
  'russia': 'Russia',
  'uk': 'UK',
  'united kingdom': 'UK',
  'latin america': 'Latin America',
  'greece': 'Greece',
  'portugal': 'Portugal',
  'poland': 'Poland',
  'denmark': 'Denmark',
  'finland': 'Finland',
  'norway': 'Norway',
  'mexico': 'Mexico',
  'india': 'India',
};

const _goodToolsRegions = <String, String>{
  'U': 'USA',
  'E': 'Europe',
  'J': 'Japan',
  'W': 'World',
  'K': 'Korea',
  'B': 'Brazil',
  'A': 'Australia',
  'F': 'France',
  'G': 'Germany',
  'S': 'Spain',
  'I': 'Italy',
  'C': 'China',
};

/// Strips a trailing file extension (`.sfc`, `.cue`, `.ps3`) if present.
String stripExtension(String name) => name.replaceFirst(_extension, '');

/// Parses a file (or directory) name. Set [hasExtension] to false when
/// [name] has no extension to strip.
ParsedTitle parseTitle(String name, {bool hasExtension = true}) {
  final base = hasExtension ? stripExtension(name) : name;
  final tags = <String>[];
  String? region;
  int? disc;

  for (final m in _tagPattern.allMatches(base)) {
    final tag = (m.group(1) ?? m.group(2) ?? '').trim();
    tags.add(tag);
    final isParen = m.group(1) != null;
    if (!isParen) continue;
    final discMatch = _discPattern.firstMatch(tag);
    if (discMatch != null) {
      disc ??= int.tryParse(discMatch.group(1)!);
      continue;
    }
    region ??= _parseRegion(tag);
  }

  var title = base.replaceAll(_tagPattern, ' ');
  if (!title.contains(' ') && title.contains('_')) {
    title = title.replaceAll('_', ' ');
  }
  title = title.replaceAll(RegExp(r'\s+'), ' ').trim();
  title = title.replaceFirst(RegExp(r'[\s\-_,.]+$'), '').trim();
  title = _moveArticle(title);
  if (title.isEmpty) title = base.trim().isEmpty ? name : base.trim();

  return ParsedTitle(title: title, region: region, disc: disc, tags: tags);
}

/// Name without extension and without its disc tag, lowercased: the key used
/// to group `(Disc N)` files of one game.
String discGroupKey(String name) {
  final base = stripExtension(name);
  final withoutDisc = base.replaceAllMapped(_tagPattern, (m) {
    final tag = (m.group(1) ?? '').trim();
    return m.group(1) != null && _discPattern.hasMatch(tag) ? ' ' : m[0]!;
  });
  return withoutDisc.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
}

String? _parseRegion(String tag) {
  final parts = tag.split(',').map((p) => p.trim().toLowerCase()).toList();
  final names = <String>[];
  for (final p in parts) {
    final n = _regionNames[p];
    if (n == null) {
      names.clear();
      break;
    }
    if (!names.contains(n)) names.add(n);
  }
  if (names.isNotEmpty) return names.join(', ');
  if (!_goodToolsCode.hasMatch(tag)) return null;
  for (final c in tag.split('')) {
    final n = _goodToolsRegions[c];
    if (n == null) return null;
    if (!names.contains(n)) names.add(n);
  }
  return names.join(', ');
}

/// `Legend of Zelda, The - A Link to the Past` →
/// `The Legend of Zelda - A Link to the Past`.
String _moveArticle(String title) {
  final dash = title.indexOf(' - ');
  final head = dash < 0 ? title : title.substring(0, dash);
  final rest = dash < 0 ? '' : title.substring(dash);
  final m = _articleSuffix.firstMatch(head);
  if (m == null) return title;
  return '${m.group(2)} ${m.group(1)}$rest';
}
