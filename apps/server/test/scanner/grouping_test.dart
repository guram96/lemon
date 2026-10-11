import 'package:rs_core/rs_core.dart';
import 'package:rs_server/src/scanner/scanner.dart';
import 'package:test/test.dart';

final _t = DateTime.utc(2024);

DiscoveredFile _f(String rel, [List<String>? sheet]) =>
    DiscoveredFile(relPath: rel, size: 10, modified: _t, sheetEntries: sheet);

List<String> _paths(GameUnit u) => [for (final f in u.files) f.relPath];

void main() {
  final psx = GameSystems.byId('psx')!;
  final dc = GameSystems.byId('dreamcast')!;
  final snes = GameSystems.byId('snes')!;

  test('cue + bins form one unit; unreferenced bins are ignored', () {
    final units = groupGameUnits(
      system: psx,
      systemDirRel: 'psx',
      files: [
        _f('psx/Game (USA).cue', [
          'Game (USA) (Track 1).bin',
          'game (usa) (track 2).BIN',
        ]),
        _f('psx/Game (USA) (Track 1).bin'),
        _f('psx/Game (USA) (Track 2).bin'),
        _f('psx/orphan.bin'),
        _f('psx/readme.txt'),
      ],
    );
    expect(units, hasLength(1));
    expect(units.single.primaryRelPath, 'psx/Game (USA).cue');
    expect(_paths(units.single), [
      'psx/Game (USA).cue',
      'psx/Game (USA) (Track 1).bin',
      'psx/Game (USA) (Track 2).bin',
    ]);
    expect(units.single.title, 'Game');
    expect(units.single.region, 'USA');
  });

  test('gdi + tracks form one unit', () {
    final units = groupGameUnits(
      system: dc,
      systemDirRel: 'dreamcast',
      files: [
        _f('dreamcast/Sonic/disc.gdi', [
          'track01.bin',
          'track02.raw',
          'track03.bin',
        ]),
        _f('dreamcast/Sonic/track01.bin'),
        _f('dreamcast/Sonic/track02.raw'),
        _f('dreamcast/Sonic/track03.bin'),
      ],
    );
    expect(units, hasLength(1));
    expect(units.single.files, hasLength(4));
  });

  test('m3u claims its discs and their tracks; discs are not listed twice', () {
    final warnings = <ScanWarning>[];
    final units = groupGameUnits(
      system: psx,
      systemDirRel: 'psx',
      onWarning: warnings.add,
      files: [
        _f('psx/FF7/FF7.m3u', [
          'FF7 (Disc 1).cue',
          r'discs\FF7 (Disc 2).cue',
          'FF7 (Disc 3).cue',
        ]),
        _f('psx/FF7/FF7 (Disc 1).cue', ['FF7 (Disc 1).bin']),
        _f('psx/FF7/FF7 (Disc 1).bin'),
        _f('psx/FF7/discs/FF7 (Disc 2).cue', ['FF7 (Disc 2).bin']),
        _f('psx/FF7/discs/FF7 (Disc 2).bin'),
      ],
    );
    expect(units, hasLength(1));
    final u = units.single;
    expect(u.primaryRelPath, 'psx/FF7/FF7.m3u');
    expect(u.discCount, 2);
    expect(u.files, hasLength(5));
    expect(warnings.single.kind, ScanWarningKind.missingReference);
  });

  test('(Disc N) sets without m3u merge into one unit', () {
    final units = groupGameUnits(
      system: psx,
      systemDirRel: 'psx',
      files: [
        _f('psx/Metal Gear Solid (USA) (Disc 2).chd'),
        _f('psx/Metal Gear Solid (USA) (Disc 1).chd'),
        _f('psx/Metal Gear Solid (Europe) (Disc 1).chd'),
        _f('psx/Crash (USA).chd'),
      ],
    );
    expect(units.map((u) => u.primaryRelPath), [
      'psx/Crash (USA).chd',
      'psx/Metal Gear Solid (Europe) (Disc 1).chd',
      'psx/Metal Gear Solid (USA) (Disc 1).chd',
    ]);
    final mgs = units.last;
    expect(mgs.discCount, 2);
    expect(_paths(mgs), [
      'psx/Metal Gear Solid (USA) (Disc 1).chd',
      'psx/Metal Gear Solid (USA) (Disc 2).chd',
    ]);
    expect(mgs.title, 'Metal Gear Solid');
  });

  test('(Disc N) cue sets merge with their tracks', () {
    final units = groupGameUnits(
      system: psx,
      systemDirRel: 'psx',
      files: [
        _f('psx/G (Disc 1).cue', ['G (Disc 1).bin']),
        _f('psx/G (Disc 1).bin'),
        _f('psx/G (Disc 2).cue', ['G (Disc 2).bin']),
        _f('psx/G (Disc 2).bin'),
      ],
    );
    expect(units, hasLength(1));
    expect(units.single.discCount, 2);
    expect(units.single.files, hasLength(4));
  });

  test('references outside the system folder are rejected', () {
    final warnings = <ScanWarning>[];
    final units = groupGameUnits(
      system: psx,
      systemDirRel: 'psx',
      onWarning: warnings.add,
      files: [
        _f('psx/a.cue', ['../snes/x.sfc', '/etc/passwd', r'C:\x.bin']),
      ],
    );
    expect(units.single.files, hasLength(1));
    expect(
      warnings.map((w) => w.kind),
      everyElement(ScanWarningKind.invalidReference),
    );
    expect(warnings, hasLength(3));
  });

  test('only accepted extensions become games (case-insensitive)', () {
    final units = groupGameUnits(
      system: snes,
      systemDirRel: 'snes',
      files: [
        _f('snes/A.SFC'),
        _f('snes/b.smc'),
        _f('snes/c.nes'),
        _f('snes/d.zip'),
      ],
    );
    expect(units.map((u) => u.primaryRelPath), [
      'snes/A.SFC',
      'snes/b.smc',
      'snes/d.zip',
    ]);
  });

  test('directory games', () {
    final ps3 = GameSystems.byId('ps3')!;
    final units = groupGameUnits(
      system: ps3,
      systemDirRel: 'ps3',
      files: const [],
      directoryGames: [
        DiscoveredDirectory(
          relPath: 'ps3/Demon\'s Souls (USA).ps3',
          files: [
            _f('ps3/Demon\'s Souls (USA).ps3/PS3_GAME/USRDIR/EBOOT.BIN'),
            _f('ps3/Demon\'s Souls (USA).ps3/PS3_DISC.SFB'),
          ],
        ),
      ],
    );
    expect(units.single.isDirectory, isTrue);
    expect(units.single.title, 'Demon\'s Souls');
    expect(units.single.files.first.relPath, endsWith('PS3_DISC.SFB'));
  });
}
