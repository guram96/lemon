import 'package:meta/meta.dart';

/// A game platform, identified by its EmulationStation (ES-DE) folder name.
///
/// [id] is exactly the folder name used inside a library root
/// (`<root>/snes/`, `<root>/psx/`, …). This is the only EmulationStation
/// compatibility: Retro Steam never reads or writes ES files.
@immutable
class GameSystem {
  const GameSystem({
    required this.id,
    required this.name,
    required this.manufacturer,
    required this.extensions,
  });

  final String id;
  final String name;
  final String manufacturer;

  /// Lowercase file extensions including the dot, for example `.sfc`.
  final Set<String> extensions;

  bool acceptsFile(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot < 0) return false;
    return extensions.contains(fileName.substring(dot).toLowerCase());
  }

  @override
  bool operator ==(Object other) => other is GameSystem && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'GameSystem($id)';
}

const _archives = {'.zip', '.7z'};
const _disc = {'.chd', '.cue', '.iso', '.m3u'};

/// Built-in catalog of supported systems, keyed by ES-DE folder name.
abstract final class GameSystems {
  static final List<GameSystem> all = List.unmodifiable(<GameSystem>[
    // Nintendo
    const GameSystem(
      id: 'nes',
      name: 'Nintendo Entertainment System',
      manufacturer: 'Nintendo',
      extensions: {'.nes', '.unf', ..._archives},
    ),
    const GameSystem(
      id: 'fds',
      name: 'Famicom Disk System',
      manufacturer: 'Nintendo',
      extensions: {'.fds', ..._archives},
    ),
    const GameSystem(
      id: 'snes',
      name: 'Super Nintendo',
      manufacturer: 'Nintendo',
      extensions: {'.sfc', '.smc', ..._archives},
    ),
    const GameSystem(
      id: 'n64',
      name: 'Nintendo 64',
      manufacturer: 'Nintendo',
      extensions: {'.n64', '.z64', '.v64', ..._archives},
    ),
    const GameSystem(
      id: 'gc',
      name: 'GameCube',
      manufacturer: 'Nintendo',
      extensions: {'.iso', '.rvz', '.gcz', '.ciso'},
    ),
    const GameSystem(
      id: 'wii',
      name: 'Wii',
      manufacturer: 'Nintendo',
      extensions: {'.iso', '.rvz', '.wbfs'},
    ),
    const GameSystem(
      id: 'wiiu',
      name: 'Wii U',
      manufacturer: 'Nintendo',
      extensions: {'.wua', '.wux', '.rpx'},
    ),
    const GameSystem(
      id: 'switch',
      name: 'Nintendo Switch',
      manufacturer: 'Nintendo',
      extensions: {'.nsp', '.xci'},
    ),
    const GameSystem(
      id: 'virtualboy',
      name: 'Virtual Boy',
      manufacturer: 'Nintendo',
      extensions: {'.vb', ..._archives},
    ),
    const GameSystem(
      id: 'gb',
      name: 'Game Boy',
      manufacturer: 'Nintendo',
      extensions: {'.gb', ..._archives},
    ),
    const GameSystem(
      id: 'gbc',
      name: 'Game Boy Color',
      manufacturer: 'Nintendo',
      extensions: {'.gbc', ..._archives},
    ),
    const GameSystem(
      id: 'gba',
      name: 'Game Boy Advance',
      manufacturer: 'Nintendo',
      extensions: {'.gba', ..._archives},
    ),
    const GameSystem(
      id: 'nds',
      name: 'Nintendo DS',
      manufacturer: 'Nintendo',
      extensions: {'.nds', ..._archives},
    ),
    const GameSystem(
      id: 'n3ds',
      name: 'Nintendo 3DS',
      manufacturer: 'Nintendo',
      extensions: {'.3ds', '.cia', '.cci', '.cxi'},
    ),
    // Sega
    const GameSystem(
      id: 'mastersystem',
      name: 'Master System',
      manufacturer: 'Sega',
      extensions: {'.sms', ..._archives},
    ),
    const GameSystem(
      id: 'megadrive',
      name: 'Mega Drive',
      manufacturer: 'Sega',
      extensions: {'.md', '.gen', '.smd', '.bin', ..._archives},
    ),
    const GameSystem(
      id: 'genesis',
      name: 'Genesis',
      manufacturer: 'Sega',
      extensions: {'.md', '.gen', '.smd', '.bin', ..._archives},
    ),
    const GameSystem(
      id: 'segacd',
      name: 'Sega CD',
      manufacturer: 'Sega',
      extensions: _disc,
    ),
    const GameSystem(
      id: 'sega32x',
      name: 'Sega 32X',
      manufacturer: 'Sega',
      extensions: {'.32x', ..._archives},
    ),
    const GameSystem(
      id: 'saturn',
      name: 'Saturn',
      manufacturer: 'Sega',
      extensions: _disc,
    ),
    const GameSystem(
      id: 'dreamcast',
      name: 'Dreamcast',
      manufacturer: 'Sega',
      extensions: {'.cdi', '.gdi', ..._disc},
    ),
    const GameSystem(
      id: 'gamegear',
      name: 'Game Gear',
      manufacturer: 'Sega',
      extensions: {'.gg', ..._archives},
    ),
    // Sony
    const GameSystem(
      id: 'psx',
      name: 'PlayStation',
      manufacturer: 'Sony',
      extensions: {'.pbp', ..._disc},
    ),
    const GameSystem(
      id: 'ps2',
      name: 'PlayStation 2',
      manufacturer: 'Sony',
      extensions: {'.cso', ..._disc},
    ),
    const GameSystem(
      id: 'ps3',
      name: 'PlayStation 3',
      manufacturer: 'Sony',
      extensions: {'.ps3', '.iso'},
    ),
    const GameSystem(
      id: 'psp',
      name: 'PlayStation Portable',
      manufacturer: 'Sony',
      extensions: {'.iso', '.cso', '.pbp', '.chd'},
    ),
    const GameSystem(
      id: 'psvita',
      name: 'PlayStation Vita',
      manufacturer: 'Sony',
      extensions: {'.vpk', '.psvita'},
    ),
    // Microsoft
    const GameSystem(
      id: 'xbox',
      name: 'Xbox',
      manufacturer: 'Microsoft',
      extensions: {'.iso', '.xiso'},
    ),
    // NEC / SNK / Bandai
    const GameSystem(
      id: 'pcengine',
      name: 'PC Engine',
      manufacturer: 'NEC',
      extensions: {'.pce', ..._disc, ..._archives},
    ),
    const GameSystem(
      id: 'neogeo',
      name: 'Neo Geo',
      manufacturer: 'SNK',
      extensions: _archives,
    ),
    const GameSystem(
      id: 'ngp',
      name: 'Neo Geo Pocket',
      manufacturer: 'SNK',
      extensions: {'.ngp', ..._archives},
    ),
    const GameSystem(
      id: 'ngpc',
      name: 'Neo Geo Pocket Color',
      manufacturer: 'SNK',
      extensions: {'.ngc', '.ngpc', ..._archives},
    ),
    const GameSystem(
      id: 'wonderswan',
      name: 'WonderSwan',
      manufacturer: 'Bandai',
      extensions: {'.ws', ..._archives},
    ),
    const GameSystem(
      id: 'wonderswancolor',
      name: 'WonderSwan Color',
      manufacturer: 'Bandai',
      extensions: {'.wsc', ..._archives},
    ),
    // Atari
    const GameSystem(
      id: 'atari2600',
      name: 'Atari 2600',
      manufacturer: 'Atari',
      extensions: {'.a26', '.bin', ..._archives},
    ),
    const GameSystem(
      id: 'atari7800',
      name: 'Atari 7800',
      manufacturer: 'Atari',
      extensions: {'.a78', '.bin', ..._archives},
    ),
    const GameSystem(
      id: 'atarilynx',
      name: 'Atari Lynx',
      manufacturer: 'Atari',
      extensions: {'.lnx', ..._archives},
    ),
    const GameSystem(
      id: 'atarijaguar',
      name: 'Atari Jaguar',
      manufacturer: 'Atari',
      extensions: {'.j64', '.jag', ..._archives},
    ),
    // Other
    const GameSystem(
      id: '3do',
      name: '3DO',
      manufacturer: 'Panasonic',
      extensions: _disc,
    ),
    const GameSystem(
      id: 'colecovision',
      name: 'ColecoVision',
      manufacturer: 'Coleco',
      extensions: {'.col', ..._archives},
    ),
    const GameSystem(
      id: 'intellivision',
      name: 'Intellivision',
      manufacturer: 'Mattel',
      extensions: {'.int', ..._archives},
    ),
    const GameSystem(
      id: 'msx',
      name: 'MSX',
      manufacturer: 'Microsoft',
      extensions: {'.rom', '.mx1', '.mx2', '.dsk', ..._archives},
    ),
    const GameSystem(
      id: 'c64',
      name: 'Commodore 64',
      manufacturer: 'Commodore',
      extensions: {'.d64', '.t64', '.prg', '.crt', ..._archives},
    ),
    const GameSystem(
      id: 'amiga',
      name: 'Amiga',
      manufacturer: 'Commodore',
      extensions: {'.adf', '.hdf', '.lha', ..._archives},
    ),
    // Arcade
    const GameSystem(
      id: 'arcade',
      name: 'Arcade',
      manufacturer: 'Various',
      extensions: _archives,
    ),
    const GameSystem(
      id: 'mame',
      name: 'MAME',
      manufacturer: 'Various',
      extensions: _archives,
    ),
    const GameSystem(
      id: 'fbneo',
      name: 'FinalBurn Neo',
      manufacturer: 'Various',
      extensions: _archives,
    ),
  ]);

  static final Map<String, GameSystem> _byId = {for (final s in all) s.id: s};

  /// Looks up a system by its folder name. Case-insensitive, because folder
  /// names may come from case-insensitive filesystems.
  static GameSystem? byId(String id) => _byId[id.toLowerCase()];
}
