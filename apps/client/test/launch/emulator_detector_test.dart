import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rs_client/src/launch/emulator_detector.dart';
import 'package:rs_client/src/launch/emulator_manifest.dart';
import 'package:rs_client/src/launch/emulator_manifest_data.dart';
import 'package:rs_client/src/launch/emulator_probe.dart';
import 'package:rs_client/src/platform/client_capabilities.dart';
import 'package:rs_core/rs_core.dart';

void main() {
  group('EmulatorManifest', () {
    test('parses retroarch, standalones, and real core stems', () {
      final manifest = EmulatorManifest.parse(emulatorManifestJson);
      expect(manifest.entries.map((entry) => entry.id), [
        'retroarch',
        'snes9x',
        'mgba',
        'duckstation',
        'pcsx2',
        'dolphin',
        'ppsspp',
        'melonds',
        'flycast',
        'azahar',
        'rpcs3',
      ]);

      final retroarch = manifest.entries.first;
      expect(retroarch.kind, EmulatorKind.retroarch);
      expect(
        retroarch.cores.map((core) => core.match),
        containsAll(const [
          'nestopia_libretro',
          'fceumm_libretro',
          'snes9x_libretro',
          'mupen64plus_next_libretro',
          'gambatte_libretro',
          'mgba_libretro',
          'melonds_libretro',
          'genesis_plus_gx_libretro',
          'swanstation_libretro',
          'mednafen_psx_hw_libretro',
          'pcsx2_libretro',
          'dolphin_libretro',
          'ppsspp_libretro',
          'flycast_libretro',
          'fbneo_libretro',
          'mame_libretro',
        ]),
      );
      expect(
        {for (final core in retroarch.cores) ...core.systems},
        containsAll(const [
          'nes',
          'snes',
          'n64',
          'gb',
          'gbc',
          'gba',
          'nds',
          'megadrive',
          'genesis',
          'psx',
          'ps2',
          'gc',
          'wii',
          'psp',
          'dreamcast',
          'fbneo',
          'mame',
          'arcade',
        ]),
      );

      final macos = retroarch.platforms['macos']!;
      final linux = retroarch.platforms['linux']!;
      final windows = retroarch.platforms['windows']!;
      expect(macos.executables.map((candidate) => candidate.path), [
        '/Applications/RetroArch.app',
        '~/Applications/RetroArch.app',
      ]);
      expect(macos.coresDirectories, [
        '~/Library/Application Support/RetroArch/cores',
      ]);
      expect(macos.coreExtension, '.dylib');
      expect(linux.executables.map((candidate) => candidate.findOnPath), [
        'retroarch',
        null,
      ]);
      expect(linux.executables.last.path, '/usr/bin/retroarch');
      expect(linux.coresDirectories, ['~/.config/retroarch/cores']);
      expect(linux.coreExtension, '.so');
      expect(windows.executables.map((candidate) => candidate.path), [
        'C:/Program Files/RetroArch/retroarch.exe',
        'C:/RetroArch-Win64/retroarch.exe',
        '~/RetroArch-Win64/retroarch.exe',
      ]);
      expect(windows.coresDirectories, ['~/AppData/Roaming/RetroArch/cores']);
      expect(windows.coreExtension, '.dll');
      for (final platform in retroarch.platforms.values) {
        expect(platform.args, ['-L', '{core}', '{rom}']);
      }

      const systems = {
        'snes9x': ['snes'],
        'mgba': ['gb', 'gbc', 'gba'],
        'duckstation': ['psx'],
        'pcsx2': ['ps2'],
        'dolphin': ['gc', 'wii'],
        'ppsspp': ['psp'],
        'melonds': ['nds'],
        'flycast': ['dreamcast'],
        'azahar': ['n3ds'],
        'rpcs3': ['ps3'],
      };
      for (final entry in manifest.entries.skip(1)) {
        expect(entry.kind, EmulatorKind.standalone);
        expect(entry.systems, systems[entry.id]);
        expect(entry.platforms.keys, ['macos', 'linux', 'windows']);
        expectKnownSystems(entry.systems);
        for (final core in entry.cores) {
          expectKnownSystems(core.systems);
        }
        for (final platform in entry.platforms.values) {
          expect(platform.args, ['{rom}']);
          expect(platform.executables, isNotEmpty);
        }
        expect(entry.platforms['macos']!.executables.every(_isAppPath), isTrue);
        expect(
          entry.platforms['linux']!.executables.any(
            (candidate) => candidate.findOnPath != null,
          ),
          isTrue,
        );
        expect(
          entry.platforms['windows']!.executables.any(_isProgramFiles),
          isTrue,
        );
        expect(
          entry.platforms['windows']!.executables.any(_isHomePath),
          isTrue,
        );
      }
      for (final core in retroarch.cores) {
        expectKnownSystems(core.systems);
      }
    });
  });

  group('EmulatorDetector', () {
    const home = '/Users/ada';
    const retroarchApp = '$home/Applications/RetroArch.app';
    const coresDir = '$home/Library/Application Support/RetroArch/cores';

    test('finds RetroArch cores and one standalone', () {
      final probe = FakeProbe(
        home: home,
        existing: const {
          retroarchApp,
          '$retroarchApp/Contents/MacOS/RetroArch',
          '/Applications/Snes9x.app',
          '/Applications/Snes9x.app/Contents/MacOS/Snes9x',
        },
        files: const {
          coresDir: [
            'snes9x_libretro.dylib',
            'not_a_core.dylib',
            'mgba_libretro.so',
            'mgba_libretro.dylib',
            'readme.txt',
          ],
        },
      );

      final found = detectorFor(probe).detect('macos');

      expect(found.map((emulator) => emulator.id), ['retroarch', 'snes9x']);
      final retroarch = found.first;
      expect(retroarch.name, 'RetroArch');
      expect(retroarch.kind, EmulatorKind.retroarch);
      expect(retroarch.executable, '$retroarchApp/Contents/MacOS/RetroArch');
      expect(retroarch.args, ['-L', '{core}', '{rom}']);
      expect(retroarch.cores.map((core) => core.match), [
        'snes9x_libretro',
        'mgba_libretro',
      ]);
      expect(retroarch.cores.map((core) => core.path), [
        '$coresDir/snes9x_libretro.dylib',
        '$coresDir/mgba_libretro.dylib',
      ]);
      expect(retroarch.cores.first.systems, ['snes']);
      expect(retroarch.cores.last.systems, ['gb', 'gbc', 'gba']);
      expect(retroarch.systems, ['snes', 'gb', 'gbc', 'gba']);

      final snes9x = found.last;
      expect(snes9x.name, 'Snes9x');
      expect(snes9x.kind, EmulatorKind.standalone);
      expect(
        snes9x.executable,
        '/Applications/Snes9x.app/Contents/MacOS/Snes9x',
      );
      expect(snes9x.args, ['{rom}']);
      expect(snes9x.systems, ['snes']);
      expect(snes9x.cores, isEmpty);
      expect(found.where((emulator) => emulator.id == 'mgba'), isEmpty);
    });

    test('android, ios, and web detect nothing', () {
      final probe = FakeProbe(
        home: home,
        existing: const {
          '/Applications/RetroArch.app',
          '/Applications/Snes9x.app',
        },
      );
      final detector = detectorFor(probe);
      expect(detector.detect('android'), isEmpty);
      expect(detector.detect('ios'), isEmpty);
      expect(detector.detect('web'), isEmpty);
    });

    test('retroarch without a matching core still reports the bundle', () {
      final probe = FakeProbe(
        home: home,
        existing: const {'/Applications/RetroArch.app'},
        files: const {
          coresDir: ['not_a_core.dylib'],
        },
      );
      final found = detectorFor(probe).detect('macos');
      expect(found, hasLength(1));
      expect(found.single.id, 'retroarch');
      expect(found.single.executable, '/Applications/RetroArch.app');
      expect(found.single.cores, isEmpty);
      expect(found.single.systems, isEmpty);
    });

    test('a leading ~ expands once', () {
      const source = r'''
{
  "emulators": [
    {
      "id": "retroarch",
      "name": "RetroArch",
      "kind": "retroarch",
      "cores": [{"match": "snes9x_libretro", "systems": ["snes"]}],
      "platforms": {
        "linux": {
          "executables": [{"path": "~/bin/~/retroarch"}],
          "args": ["-L", "{core}", "{rom}"],
          "coresDirectories": ["~/cores"],
          "coreExtension": ".so"
        }
      }
    }
  ]
}
''';
      final probe = FakeProbe(
        home: '/home/ada',
        existing: const {'/home/ada/bin/~/retroarch'},
        files: const {
          '/home/ada/cores': ['snes9x_libretro.so'],
        },
      );
      final found = EmulatorDetector(
        manifest: EmulatorManifest.parse(source),
        probe: probe,
      ).detect('linux');
      expect(found.single.executable, '/home/ada/bin/~/retroarch');
      expect(
        found.single.cores.single.path,
        '/home/ada/cores/snes9x_libretro.so',
      );
    });

    test('linux prefers PATH and then /usr/bin/retroarch', () {
      final onPath = FakeProbe(
        home: '/home/ada',
        onPath: const {'retroarch': '/opt/retroarch'},
        files: const {
          '/home/ada/.config/retroarch/cores': ['ppsspp_libretro.so'],
        },
      );
      final fromPath = detectorFor(onPath)
          .detect('linux')
          .singleWhere((emulator) => emulator.id == 'retroarch');
      expect(fromPath.executable, '/opt/retroarch');
      expect(fromPath.cores.single.match, 'ppsspp_libretro');
      expect(fromPath.systems, ['psp']);

      final fallback = FakeProbe(
        home: '/home/ada',
        existing: const {'/usr/bin/retroarch'},
      );
      final fromDisk = detectorFor(fallback)
          .detect('linux')
          .singleWhere((emulator) => emulator.id == 'retroarch');
      expect(fromDisk.executable, '/usr/bin/retroarch');
      expect(fromDisk.cores, isEmpty);
    });

    test('windows expands ~ in the cores directory', () {
      const windowsHome = r'C:\Users\ada';
      const cores = r'C:\Users\ada\AppData\Roaming\RetroArch\cores';
      final probe = FakeProbe(
        home: windowsHome,
        existing: const {'C:/Program Files/RetroArch/retroarch.exe'},
        files: const {
          cores: ['nestopia_libretro.dll', 'mystery.dll'],
        },
      );
      final found = detectorFor(probe).detect('windows');
      expect(found.map((emulator) => emulator.id), ['retroarch']);
      expect(
        found.single.executable,
        'C:/Program Files/RetroArch/retroarch.exe',
      );
      expect(found.single.cores.single.path, '$cores\\nestopia_libretro.dll');
      expect(found.single.cores.single.match, 'nestopia_libretro');
      expect(found.single.systems, ['nes']);
    });
  });

  group('providers', () {
    test('detectedEmulatorsProvider is empty when launch is unsupported', () {
      final container = ProviderContainer(
        overrides: [
          clientCapabilitiesProvider.overrideWithValue(
            const ClientCapabilities(
              canInstallGames: false,
              canLaunchGames: false,
              platform: 'web',
              deviceName: 'Web browser',
            ),
          ),
          emulatorProbeProvider.overrideWithValue(const _ThrowingProbe()),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(detectedEmulatorsProvider), isEmpty);
    });

    test('detectedEmulatorsProvider is empty on android', () {
      final container = ProviderContainer(
        overrides: [
          clientCapabilitiesProvider.overrideWithValue(
            const ClientCapabilities(
              canInstallGames: true,
              canLaunchGames: true,
              platform: 'android',
              deviceName: 'Phone',
            ),
          ),
          emulatorProbeProvider.overrideWithValue(const _ThrowingProbe()),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(detectedEmulatorsProvider), isEmpty);
    });
  });
}

EmulatorDetector detectorFor(EmulatorProbe probe) => EmulatorDetector(
  manifest: EmulatorManifest.parse(emulatorManifestJson),
  probe: probe,
);

void expectKnownSystems(List<String> systems) {
  for (final id in systems) {
    expect(GameSystems.byId(id), isNotNull, reason: id);
  }
}

bool _isAppPath(EmulatorCandidate candidate) {
  final path = candidate.path;
  return path != null && path.endsWith('.app');
}

bool _isProgramFiles(EmulatorCandidate candidate) {
  final path = candidate.path;
  return path != null && path.startsWith('C:/Program Files/');
}

bool _isHomePath(EmulatorCandidate candidate) {
  final path = candidate.path;
  return path != null && path.startsWith('~/');
}

final class FakeProbe implements EmulatorProbe {
  FakeProbe({
    required this.home,
    this.existing = const {},
    this.files = const {},
    this.onPath = const {},
  });

  @override
  final String home;

  final Set<String> existing;
  final Map<String, List<String>> files;
  final Map<String, String> onPath;

  @override
  bool exists(String path) => existing.contains(path);

  @override
  List<String> listFiles(String directory) => files[directory] ?? const [];

  @override
  String? findOnPath(String name) => onPath[name];
}

final class _ThrowingProbe implements EmulatorProbe {
  const _ThrowingProbe();

  @override
  String get home => throw StateError('probe should not be read');

  @override
  bool exists(String path) => throw StateError('probe should not be read');

  @override
  List<String> listFiles(String directory) =>
      throw StateError('probe should not be read');

  @override
  String? findOnPath(String name) =>
      throw StateError('probe should not be read');
}
