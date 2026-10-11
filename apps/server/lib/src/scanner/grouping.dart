/// Groups the files of one system folder into game units. Pure: works on an
/// in-memory list of discovered files (sheet contents already parsed).
library;

import 'package:path/path.dart' as p;
import 'package:rs_core/rs_core.dart';

import 'scan_models.dart';
import 'title_parser.dart';

/// A file found while walking a system folder.
class DiscoveredFile {
  DiscoveredFile({
    required this.relPath,
    required this.size,
    required this.modified,
    this.sheetEntries,
  });

  /// Rel path from the library root, `/`-separated.
  final String relPath;
  final int size;
  final DateTime modified;

  /// Raw references if this is a `.cue` / `.gdi` / `.m3u` the system accepts.
  final List<String>? sheetEntries;

  String get name {
    final i = relPath.lastIndexOf('/');
    return i < 0 ? relPath : relPath.substring(i + 1);
  }

  String get dir {
    final i = relPath.lastIndexOf('/');
    return i < 0 ? '' : relPath.substring(0, i);
  }

  /// Lowercase extension including the dot, or '' if none.
  String get extension {
    final n = name;
    final i = n.lastIndexOf('.');
    return i <= 0 ? '' : n.substring(i).toLowerCase();
  }

  @override
  String toString() => 'DiscoveredFile($relPath)';
}

/// A directory that is itself one game (`ps3/Game (USA).ps3/`).
class DiscoveredDirectory {
  DiscoveredDirectory({required this.relPath, required this.files});

  final String relPath;
  final List<DiscoveredFile> files;
}

/// A grouped game unit, before hashing.
class GameUnit {
  GameUnit({
    required this.systemId,
    required this.primaryRelPath,
    required this.title,
    required this.files,
    this.region,
    this.discCount = 1,
    this.isDirectory = false,
  });

  final String systemId;
  final String primaryRelPath;
  final String title;
  final String? region;

  /// Primary first (except directory units), then tracks / discs in order.
  final List<DiscoveredFile> files;
  final int discCount;
  final bool isDirectory;

  int get totalSize => files.fold(0, (s, f) => s + f.size);

  @override
  String toString() => 'GameUnit($primaryRelPath, ${files.length} files)';
}

/// Directory extensions that mark a directory as one game, for systems that
/// accept them (ES-DE convention).
const directoryGameExtensions = {'.ps3', '.psvita'};

class _Unit {
  _Unit(this.primary) : files = [primary];

  final DiscoveredFile primary;
  final List<DiscoveredFile> files;
  int discs = 1;
}

/// Groups [files] (all under [systemDirRel], the system folder's rel path
/// such as `psx`) into game units for [system].
///
/// - `.m3u` + listed discs (and their `.cue`/`.gdi` tracks) form one unit.
/// - `.cue` / `.gdi` + their tracks form one unit; tracks need not have an
///   extension the system accepts (`.bin`, `.raw`).
/// - Remaining accepted files are one unit each, except `(Disc N)` files with
///   the same base name, extension and folder, which merge into one unit.
/// - Files without an accepted extension that no sheet references are ignored.
List<GameUnit> groupGameUnits({
  required GameSystem system,
  required String systemDirRel,
  required List<DiscoveredFile> files,
  List<DiscoveredDirectory> directoryGames = const [],
  void Function(ScanWarning warning)? onWarning,
}) {
  final sorted = [...files]..sort((a, b) => _compareRel(a.relPath, b.relPath));
  final exact = <String, DiscoveredFile>{};
  final folded = <String, DiscoveredFile>{};
  for (final f in sorted) {
    exact[f.relPath] = f;
    folded.putIfAbsent(f.relPath.toLowerCase(), () => f);
  }
  final claimed = <String>{};

  DiscoveredFile? resolve(DiscoveredFile sheet, String entry) {
    final ref = entry.replaceAll(r'\', '/').trim();
    if (ref.startsWith('/') || RegExp(r'^[A-Za-z]:').hasMatch(ref)) {
      onWarning?.call(
        ScanWarning(
          ScanWarningKind.invalidReference,
          sheet.relPath,
          'Absolute path "$entry" is not allowed',
        ),
      );
      return null;
    }
    final joined = p.posix.normalize(
      sheet.dir.isEmpty ? ref : '${sheet.dir}/$ref',
    );
    if (!joined.toLowerCase().startsWith('${systemDirRel.toLowerCase()}/')) {
      onWarning?.call(
        ScanWarning(
          ScanWarningKind.invalidReference,
          sheet.relPath,
          '"$entry" points outside the system folder',
        ),
      );
      return null;
    }
    final found = exact[joined] ?? folded[joined.toLowerCase()];
    if (found == null) {
      onWarning?.call(
        ScanWarning(
          ScanWarningKind.missingReference,
          sheet.relPath,
          'Referenced file "$entry" not found',
        ),
      );
    }
    return found;
  }

  void addTracks(_Unit unit, DiscoveredFile sheet) {
    for (final entry in sheet.sheetEntries ?? const <String>[]) {
      final track = resolve(sheet, entry);
      if (track == null || claimed.contains(track.relPath)) continue;
      if (track.relPath == sheet.relPath) continue;
      claimed.add(track.relPath);
      unit.files.add(track);
    }
  }

  bool accepted(DiscoveredFile f) => system.acceptsFile(f.name);

  final playlists = <_Unit>[];
  final singles = <_Unit>[];

  // 1. Playlists: .m3u + discs (+ the discs' own tracks).
  for (final f in sorted) {
    if (f.extension != '.m3u' || !accepted(f)) continue;
    if (claimed.contains(f.relPath)) continue;
    claimed.add(f.relPath);
    final unit = _Unit(f);
    var discs = 0;
    for (final entry in f.sheetEntries ?? const <String>[]) {
      final disc = resolve(f, entry);
      if (disc == null || claimed.contains(disc.relPath)) continue;
      claimed.add(disc.relPath);
      unit.files.add(disc);
      discs++;
      if (disc.extension == '.cue' || disc.extension == '.gdi') {
        addTracks(unit, disc);
      }
    }
    unit.discs = discs < 1 ? 1 : discs;
    playlists.add(unit);
  }

  // 2. Cue / gdi sheets + tracks.
  for (final f in sorted) {
    if (f.extension != '.cue' && f.extension != '.gdi') continue;
    if (!accepted(f) || claimed.contains(f.relPath)) continue;
    claimed.add(f.relPath);
    final unit = _Unit(f);
    addTracks(unit, f);
    singles.add(unit);
  }

  // 3. Everything else with an accepted extension.
  for (final f in sorted) {
    if (!accepted(f) || claimed.contains(f.relPath)) continue;
    claimed.add(f.relPath);
    singles.add(_Unit(f));
  }

  // 4. Merge (Disc N) sets that have no playlist.
  final merged = <_Unit>[];
  final discSets = <String, List<(int, _Unit)>>{};
  for (final u in singles) {
    final disc = parseTitle(u.primary.name).disc;
    if (disc == null) {
      merged.add(u);
      continue;
    }
    final key =
        '${u.primary.dir.toLowerCase()}\u0000${u.primary.extension}'
        '\u0000${discGroupKey(u.primary.name)}';
    (discSets[key] ??= []).add((disc, u));
  }
  for (final set in discSets.values) {
    set.sort((a, b) {
      final c = a.$1.compareTo(b.$1);
      return c != 0
          ? c
          : _compareRel(a.$2.primary.relPath, b.$2.primary.relPath);
    });
    final first = set.first.$2;
    final unit = _Unit(first.primary)
      ..files.clear()
      ..discs = set.length;
    for (final (_, u) in set) {
      unit.files.addAll(u.files);
    }
    merged.add(unit);
  }

  final out = <GameUnit>[
    for (final u in [...playlists, ...merged]) _toGameUnit(system.id, u),
    for (final d in directoryGames) _directoryUnit(system.id, d),
  ]..sort((a, b) => _compareRel(a.primaryRelPath, b.primaryRelPath));
  return out;
}

GameUnit _toGameUnit(String systemId, _Unit u) {
  final parsed = parseTitle(u.primary.name);
  return GameUnit(
    systemId: systemId,
    primaryRelPath: u.primary.relPath,
    title: parsed.title,
    region: parsed.region,
    files: List.unmodifiable(u.files),
    discCount: u.discs,
  );
}

GameUnit _directoryUnit(String systemId, DiscoveredDirectory d) {
  final i = d.relPath.lastIndexOf('/');
  final name = i < 0 ? d.relPath : d.relPath.substring(i + 1);
  final parsed = parseTitle(name);
  final files = [...d.files]..sort((a, b) => _compareRel(a.relPath, b.relPath));
  return GameUnit(
    systemId: systemId,
    primaryRelPath: d.relPath,
    title: parsed.title,
    region: parsed.region,
    files: List.unmodifiable(files),
    isDirectory: true,
  );
}

int _compareRel(String a, String b) {
  final c = a.toLowerCase().compareTo(b.toLowerCase());
  return c != 0 ? c : a.compareTo(b);
}
