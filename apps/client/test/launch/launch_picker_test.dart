import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rs_client/src/app/retro_steam_app.dart';
import 'package:rs_client/src/connection/connection_provider.dart';
import 'package:rs_client/src/connection/server_address.dart';
import 'package:rs_client/src/install/download_queue.dart';
import 'package:rs_client/src/install/install_models.dart';
import 'package:rs_client/src/install/install_store.dart';
import 'package:rs_client/src/launch/emulator_detector.dart';
import 'package:rs_client/src/launch/emulator_manifest.dart';
import 'package:rs_client/src/launch/game_launcher.dart';
import 'package:rs_client/src/launch/launch_models.dart';
import 'package:rs_client/src/launch/launch_store.dart';
import 'package:rs_client/src/platform/client_capabilities.dart';
import 'package:rs_client/src/routing/router.dart';
import 'package:rs_client/src/storage/credential_store.dart';
import 'package:rs_core/rs_core.dart';
import 'package:rs_ui/rs_ui.dart';

import '../support/fakes.dart';

const _session = StoredCredentials(
  serverId: 'server-1',
  deviceToken: 'dev',
  sessionToken: 'sess',
  user: adminUser,
);

const _snesCore = '/cores/snes9x_libretro.dylib';
const _gbaCore = '/cores/mgba_libretro.dylib';
const _onlyGbaCore = '/cores/only_gba_libretro.dylib';

const _customCommand = '/usr/local/bin/snes9x {rom}';

final _chrono = Game(
  id: 'chrono',
  systemId: 'snes',
  title: 'Chrono Trigger',
  rootId: 'root-1',
  files: const [GameFile(path: 'snes/Chrono Trigger.sfc', sizeBytes: 1024)],
  addedAt: DateTime.utc(2020, 6, 15),
);

final _snesChoice = LaunchChoice(emulatorId: 'snes9x');

final _coreChoice = LaunchChoice(emulatorId: 'retroarch', corePath: _snesCore);

final _detected = <DetectedEmulator>[
  DetectedEmulator(
    id: 'snes9x',
    name: 'Snes9x',
    kind: EmulatorKind.standalone,
    executable: '/Applications/Snes9x.app/Contents/MacOS/Snes9x',
    args: const ['{rom}'],
    systems: const ['snes'],
    cores: const [],
  ),
  DetectedEmulator(
    id: 'duckstation',
    name: 'DuckStation',
    kind: EmulatorKind.standalone,
    executable: '/Applications/DuckStation.app/Contents/MacOS/DuckStation',
    args: const ['{rom}'],
    systems: const ['psx'],
    cores: const [],
  ),
  DetectedEmulator(
    id: 'retroarch',
    name: 'RetroArch',
    kind: EmulatorKind.retroarch,
    executable: '/Applications/RetroArch.app/Contents/MacOS/RetroArch',
    args: const ['-L', '{core}', '{rom}'],
    systems: const ['snes', 'gba'],
    cores: [
      DetectedCore(
        path: _snesCore,
        match: 'snes9x_libretro',
        systems: const ['snes'],
      ),
      DetectedCore(
        path: _gbaCore,
        match: 'mgba_libretro',
        systems: const ['gba'],
      ),
    ],
  ),
  DetectedEmulator(
    id: 'retroarch-gba',
    name: 'RetroArch',
    kind: EmulatorKind.retroarch,
    executable: '/opt/retroarch',
    args: const ['-L', '{core}', '{rom}'],
    systems: const ['gba'],
    cores: [
      DetectedCore(
        path: _onlyGbaCore,
        match: 'mgba_libretro',
        systems: const ['gba'],
      ),
    ],
  ),
];

class _Api extends FakeApiClient {
  _Api() : super(info: serverInfo());

  @override
  Future<List<SystemSummary>> systems() async => const [
    SystemSummary(systemId: 'snes', name: 'Super Nintendo', gameCount: 1),
  ];

  @override
  Future<GamePage> games({
    String? system,
    String? query,
    String sort = GameSort.title,
  }) async => GamePage(games: [_chrono], total: 1);

  @override
  Future<Game> game(String id) async {
    if (id == _chrono.id) return _chrono;
    throw apiError(404, ApiErrorCodes.notFound);
  }

  @override
  Future<List<LibraryRoot>> roots() async => const [];
}

class _FakeQueue extends DownloadQueueNotifier {
  _FakeQueue(this.initial);

  final List<InstallRecord> initial;

  @override
  List<InstallRecord> build() => [...initial];

  @override
  Future<void> enqueue(Game game) async {}

  @override
  Future<void> uninstallGame(String gameId) async {
    state = [
      for (final record in state)
        if (record.gameId != gameId) record,
    ];
  }
}

class _FixedDestinations extends DestinationsNotifier {
  _FixedDestinations(this.destination);

  final InstallDestination destination;

  @override
  Future<InstallDestination> build() async => destination;
}

class _MemoryLaunchStore implements LaunchStore {
  _MemoryLaunchStore([LaunchOptions? initial])
    : options = initial ?? LaunchOptions();

  LaunchOptions options;

  @override
  Future<LaunchOptions> read() async => options;

  @override
  Future<void> putSystem(String systemId, LaunchChoice choice) async {
    options = options.withSystem(systemId, choice);
  }

  @override
  Future<void> removeSystem(String systemId) async {
    options = options.withoutSystem(systemId);
  }

  @override
  Future<void> putGame(
    String serverId,
    String gameId,
    LaunchChoice choice,
  ) async {
    options = options.withGame(serverId, gameId, choice);
  }

  @override
  Future<void> removeGame(String serverId, String gameId) async {
    options = options.withoutGame(serverId, gameId);
  }
}

class _ThrowingStarter implements ProcessStarter {
  int starts = 0;

  @override
  Future<int> start(String executable, List<String> args) async {
    starts++;
    throw StateError('emulator failed to start');
  }
}

class _LauncherProbe extends GameLauncher {
  _LauncherProbe(this.probe) : super(starter: probe);

  final _ThrowingStarter probe;
  int calls = 0;

  @override
  Future<LaunchResult> launch({
    required String platform,
    required Game game,
    required InstallRecord? record,
    required String? folder,
    required LaunchChoice? choice,
    required List<DetectedEmulator> detected,
  }) {
    calls++;
    return super.launch(
      platform: platform,
      game: game,
      record: record,
      folder: folder,
      choice: choice,
      detected: detected,
    );
  }
}

class _HungOptions extends LaunchOptionsNotifier {
  @override
  Future<LaunchOptions> build() => Completer<LaunchOptions>().future;
}

InstallRecord _installed() => InstallRecord(
  serverId: 'server-1',
  gameId: 'chrono',
  systemId: 'snes',
  phase: InstallPhase.installed,
  receivedBytes: 1024,
  totalBytes: 1024,
);

void main() {
  final roms = InstallDestination(globalFolder: '/roms');

  Future<ProviderContainer> pump(
    WidgetTester tester, {
    List<InstallRecord> records = const [],
    InstallDestination? destination,
    ClientCapabilities? capabilities,
    _MemoryLaunchStore? launchStore,
    LaunchOptionsNotifier Function()? launchOptions,
    List<DetectedEmulator>? detected,
    GameLauncher? launcher,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1280, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final container = ProviderContainer(
      overrides: [
        apiClientFactoryProvider.overrideWithValue((_) => _Api()),
        credentialStoreProvider.overrideWithValue(
          InMemoryCredentialStore(
            _session.copyWith(serverUri: defaultLocalServerUri),
          ),
        ),
        clientCapabilitiesProvider.overrideWithValue(
          capabilities ??
              ClientCapabilities.full(
                platform: 'macos',
                deviceName: 'Test Mac',
              ),
        ),
        downloadQueueProvider.overrideWith(() => _FakeQueue(records)),
        destinationsProvider.overrideWith(
          () => _FixedDestinations(destination ?? InstallDestination()),
        ),
        if (launchOptions != null)
          launchOptionsProvider.overrideWith(launchOptions)
        else
          launchStoreProvider.overrideWithValue(
            launchStore ?? _MemoryLaunchStore(),
          ),
        detectedEmulatorsProvider.overrideWithValue(
          detected ?? const <DetectedEmulator>[],
        ),
        gameLauncherProvider.overrideWithValue(
          launcher ?? GameLauncher(starter: _ThrowingStarter()),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const RetroSteamApp(),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> unmount(WidgetTester tester) =>
      tester.pumpWidget(const SizedBox.shrink());

  Future<void> openGame(
    WidgetTester tester,
    ProviderContainer container,
  ) async {
    container.read(routerProvider).go(AppRoutes.game('chrono'));
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  RsButton button(WidgetTester tester, String label) =>
      tester.widget<RsButton>(find.widgetWithText(RsButton, label));

  testWidgets('an installed game shows Play, Emulator, and Uninstall', (
    tester,
  ) async {
    try {
      final container = await pump(
        tester,
        records: [_installed()],
        destination: roms,
      );
      await openGame(tester, container);

      expect(find.widgetWithText(RsButton, 'Play'), findsOneWidget);
      expect(find.widgetWithText(RsButton, 'Emulator'), findsOneWidget);
      expect(find.widgetWithText(RsButton, 'Uninstall'), findsOneWidget);
      expect(find.widgetWithText(RsButton, 'Install'), findsNothing);
      expect(button(tester, 'Play').variant, RsButtonVariant.primary);
      expect(button(tester, 'Play').icon, Icons.play_arrow_rounded);
      expect(button(tester, 'Emulator').variant, RsButtonVariant.standard);
      expect(button(tester, 'Uninstall').variant, RsButtonVariant.danger);

      final play = tester.getTopLeft(find.widgetWithText(RsButton, 'Play')).dx;
      final uninstall = tester
          .getTopLeft(find.widgetWithText(RsButton, 'Uninstall'))
          .dx;
      final emulator = tester
          .getTopLeft(find.widgetWithText(RsButton, 'Emulator'))
          .dx;
      expect(play, lessThan(uninstall));
      expect(uninstall, lessThan(emulator));
    } finally {
      await unmount(tester);
    }
  });

  testWidgets('a game that is not installed keeps Install and hides Play', (
    tester,
  ) async {
    try {
      final container = await pump(tester, destination: roms);
      await openGame(tester, container);

      expect(find.widgetWithText(RsButton, 'Install'), findsOneWidget);
      expect(button(tester, 'Install').onPressed, isNotNull);
      expect(find.widgetWithText(RsButton, 'Play'), findsNothing);
      expect(find.widgetWithText(RsButton, 'Emulator'), findsNothing);
    } finally {
      await unmount(tester);
    }
  });

  testWidgets('Play and Emulator are hidden when launching is unavailable', (
    tester,
  ) async {
    try {
      final container = await pump(
        tester,
        records: [_installed()],
        destination: roms,
        capabilities: const ClientCapabilities(
          canInstallGames: true,
          canLaunchGames: false,
          platform: 'android',
          deviceName: 'Phone',
        ),
      );
      await openGame(tester, container);

      expect(find.widgetWithText(RsButton, 'Uninstall'), findsOneWidget);
      expect(find.widgetWithText(RsButton, 'Play'), findsNothing);
      expect(find.widgetWithText(RsButton, 'Emulator'), findsNothing);
    } finally {
      await unmount(tester);
    }
  });

  testWidgets('Play stays disabled while launch options are loading', (
    tester,
  ) async {
    try {
      final container = await pump(
        tester,
        records: [_installed()],
        destination: roms,
        launchOptions: _HungOptions.new,
      );
      await openGame(tester, container);

      expect(button(tester, 'Play').onPressed, isNull);
      expect(button(tester, 'Emulator').onPressed, isNotNull);
    } finally {
      await unmount(tester);
    }
  });

  testWidgets('Play opens the picker when nothing is saved', (tester) async {
    final probe = _LauncherProbe(_ThrowingStarter());
    try {
      final container = await pump(
        tester,
        records: [_installed()],
        destination: roms,
        detected: _detected,
        launcher: probe,
      );
      await openGame(tester, container);

      await tap(tester, find.widgetWithText(RsButton, 'Play'));

      expect(find.byType(RsDialog), findsOneWidget);
      expect(tester.widget<RsDialog>(find.byType(RsDialog)).title, 'Emulator');
      expect(probe.calls, 0);
      expect(probe.probe.starts, 0);
    } finally {
      await unmount(tester);
    }
  });

  testWidgets('the picker lists emulators and cores for this system', (
    tester,
  ) async {
    try {
      final container = await pump(
        tester,
        records: [_installed()],
        destination: roms,
        detected: _detected,
      );
      await openGame(tester, container);
      await tap(tester, find.widgetWithText(RsButton, 'Emulator'));

      expect(find.widgetWithText(RsListRow, 'Snes9x'), findsOneWidget);
      expect(find.text('DuckStation'), findsNothing);
      expect(find.text('snes9x_libretro.dylib'), findsOneWidget);
      expect(find.text('mgba_libretro.dylib'), findsNothing);
      expect(find.text('only_gba_libretro.dylib'), findsNothing);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is RsListRow &&
              widget.title == 'RetroArch' &&
              widget.subtitle == null,
        ),
        findsNothing,
      );
      expect(
        tester
            .widget<RsListRow>(
              find.byWidgetPredicate(
                (widget) =>
                    widget is RsListRow &&
                    widget.subtitle == 'snes9x_libretro.dylib',
              ),
            )
            .title,
        'RetroArch',
      );
      expect(button(tester, 'Use for this system').onPressed, isNull);
      expect(button(tester, 'Only this game').onPressed, isNull);

      final field = tester.widget<RsTextField>(find.byType(RsTextField));
      expect(field.label, 'Custom command');
      expect(field.hint, 'path and {rom}');
    } finally {
      await unmount(tester);
    }
  });

  testWidgets('Use for this system stores the core and closes', (tester) async {
    final store = _MemoryLaunchStore();
    try {
      final container = await pump(
        tester,
        records: [_installed()],
        destination: roms,
        detected: _detected,
        launchStore: store,
      );
      await openGame(tester, container);
      await tap(tester, find.widgetWithText(RsButton, 'Play'));
      await tap(tester, find.text('snes9x_libretro.dylib'));

      expect(
        tester
            .widget<RsListRow>(
              find.byWidgetPredicate(
                (widget) =>
                    widget is RsListRow &&
                    widget.subtitle == 'snes9x_libretro.dylib',
              ),
            )
            .value,
        'Selected',
      );

      await tap(tester, find.widgetWithText(RsButton, 'Use for this system'));

      expect(find.byType(RsDialog), findsNothing);
      expect(
        container.read(launchOptionsProvider).requireValue.systems['snes'],
        _coreChoice,
      );
      expect(store.options.systems['snes'], _coreChoice);
      expect(store.options.games, isEmpty);
    } finally {
      await unmount(tester);
    }
  });

  testWidgets('Only this game stores a game choice and keeps the system one', (
    tester,
  ) async {
    final store = _MemoryLaunchStore(
      LaunchOptions(systems: {'snes': _snesChoice}),
    );
    try {
      final container = await pump(
        tester,
        records: [_installed()],
        destination: roms,
        detected: _detected,
        launchStore: store,
      );
      await openGame(tester, container);
      await tap(tester, find.widgetWithText(RsButton, 'Emulator'));
      await tap(tester, find.text('snes9x_libretro.dylib'));
      await tap(tester, find.widgetWithText(RsButton, 'Only this game'));

      expect(find.byType(RsDialog), findsNothing);
      final options = container.read(launchOptionsProvider).requireValue;
      expect(options.systems['snes'], _snesChoice);
      expect(options.games['server-1']?['chrono'], _coreChoice);
      expect(store.options.systems['snes'], _snesChoice);
      expect(store.options.games['server-1']?['chrono'], _coreChoice);
    } finally {
      await unmount(tester);
    }
  });

  testWidgets('Play with a saved choice shows a launch failure on the page', (
    tester,
  ) async {
    final probe = _LauncherProbe(_ThrowingStarter());
    final store = _MemoryLaunchStore(
      LaunchOptions(systems: {'snes': _snesChoice}),
    );
    try {
      final container = await pump(
        tester,
        records: [_installed()],
        destination: roms,
        detected: _detected,
        launchStore: store,
        launcher: probe,
      );
      await openGame(tester, container);
      await tap(tester, find.widgetWithText(RsButton, 'Play'));

      expect(probe.calls, 1);
      expect(probe.probe.starts, 1);
      expect(find.text('Bad state: emulator failed to start'), findsOneWidget);
      expect(find.byType(RsDialog), findsNothing);

      await tap(tester, find.widgetWithText(RsButton, 'Emulator'));
      expect(tester.widget<RsDialog>(find.byType(RsDialog)).title, 'Emulator');
    } finally {
      await unmount(tester);
    }
  });

  testWidgets('a custom command is stored for the system', (tester) async {
    final store = _MemoryLaunchStore();
    try {
      final container = await pump(
        tester,
        records: [_installed()],
        destination: roms,
        detected: _detected,
        launchStore: store,
      );
      await openGame(tester, container);
      await tap(tester, find.widgetWithText(RsButton, 'Emulator'));

      final field = find.descendant(
        of: find.byType(RsDialog),
        matching: find.byType(EditableText),
      );
      await tester.enterText(field, '   ');
      await tester.pump();
      expect(button(tester, 'Use for this system').onPressed, isNull);

      await tap(tester, find.widgetWithText(RsListRow, 'Snes9x'));
      expect(
        tester
            .widget<RsListRow>(find.widgetWithText(RsListRow, 'Snes9x'))
            .value,
        'Selected',
      );

      await tester.enterText(field, _customCommand);
      await tester.pump();
      expect(
        tester
            .widget<RsListRow>(find.widgetWithText(RsListRow, 'Snes9x'))
            .value,
        isNull,
      );

      await tap(tester, find.widgetWithText(RsButton, 'Use for this system'));

      expect(find.byType(RsDialog), findsNothing);
      expect(
        store.options.systems['snes'],
        LaunchChoice(
          emulatorId: customEmulatorId,
          customCommand: _customCommand,
        ),
      );
    } finally {
      await unmount(tester);
    }
  });

  testWidgets('an unsupported platform shows a note and does not start', (
    tester,
  ) async {
    final probe = _LauncherProbe(_ThrowingStarter());
    final store = _MemoryLaunchStore(
      LaunchOptions(systems: {'snes': _snesChoice}),
    );
    try {
      final container = await pump(
        tester,
        records: [_installed()],
        destination: roms,
        detected: _detected,
        launchStore: store,
        launcher: probe,
        capabilities: const ClientCapabilities(
          canInstallGames: true,
          canLaunchGames: true,
          platform: 'android',
          deviceName: 'Phone',
        ),
      );
      await openGame(tester, container);
      await tap(tester, find.widgetWithText(RsButton, 'Play'));

      expect(probe.calls, 1);
      expect(probe.probe.starts, 0);
      expect(find.text("This device can't start an emulator."), findsOneWidget);
      expect(find.byType(RsDialog), findsNothing);
    } finally {
      await unmount(tester);
    }
  });
}
