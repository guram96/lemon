import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rs_client/src/app/retro_steam_app.dart';
import 'package:rs_client/src/app/theme_settings_provider.dart';
import 'package:rs_client/src/connection/connection_provider.dart';
import 'package:rs_client/src/connection/server_address.dart';
import 'package:rs_client/src/home/home_page.dart';
import 'package:rs_client/src/install/download_queue.dart';
import 'package:rs_client/src/install/install_models.dart';
import 'package:rs_client/src/install/install_store.dart';
import 'package:rs_client/src/launch/emulator_detector.dart';
import 'package:rs_client/src/launch/emulator_manifest.dart';
import 'package:rs_client/src/launch/launch_models.dart';
import 'package:rs_client/src/launch/launch_store.dart';
import 'package:rs_client/src/platform/client_capabilities.dart';
import 'package:rs_client/src/routing/router.dart';
import 'package:rs_client/src/settings/client_settings.dart';
import 'package:rs_client/src/settings/settings_page.dart';
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
];

class _Api extends FakeApiClient {
  _Api() : super(info: serverInfo());

  @override
  Future<List<SystemSummary>> systems() async => const [];

  @override
  Future<GamePage> games({
    String? system,
    String? query,
    String sort = GameSort.title,
  }) async => const GamePage(games: [], total: 0);

  @override
  Future<List<LibraryRoot>> roots() async => const [];

  @override
  Future<BrowseResult> browse(String? path) async =>
      const BrowseResult(path: '/Users/test/snes');
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

class _RecordingDestinations extends DestinationsNotifier {
  _RecordingDestinations(this.current);

  InstallDestination current;

  @override
  Future<InstallDestination> build() async => current;

  @override
  Future<void> save(InstallDestination destinations) async {
    current = destinations;
    state = AsyncData(destinations);
  }
}

class _Queue extends DownloadQueueNotifier {
  _Queue(this.initial);

  final List<InstallRecord> initial;

  @override
  List<InstallRecord> build() => [...initial];
}

void main() {
  Future<ProviderContainer> pump(
    WidgetTester tester, {
    Size size = const Size(1280, 1100),
    ClientCapabilities? capabilities,
    InMemoryClientSettingsStore? settings,
    _MemoryLaunchStore? launchStore,
    List<DetectedEmulator>? detected,
    InstallDestination? destination,
    List<InstallRecord> records = const [],
  }) async {
    await tester.binding.setSurfaceSize(size);
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
        clientSettingsStoreProvider.overrideWithValue(
          settings ?? InMemoryClientSettingsStore(),
        ),
        launchStoreProvider.overrideWithValue(
          launchStore ?? _MemoryLaunchStore(),
        ),
        detectedEmulatorsProvider.overrideWithValue(
          detected ?? const <DetectedEmulator>[],
        ),
        destinationsProvider.overrideWith(
          () => _RecordingDestinations(destination ?? InstallDestination()),
        ),
        downloadQueueProvider.overrideWith(() => _Queue(records)),
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

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> openSettings(
    WidgetTester tester,
    ProviderContainer container,
  ) async {
    container.read(routerProvider).go(AppRoutes.settings);
    await tester.pumpAndSettle();
  }

  testWidgets('gear opens settings and categories show their rows', (
    tester,
  ) async {
    try {
      await pump(tester);

      expect(find.byIcon(Icons.settings), findsOneWidget);
      await tap(tester, find.byIcon(Icons.settings));

      expect(find.byType(SettingsPage), findsOneWidget);
      expect(tester.widget<RsTopBar>(find.byType(RsTopBar)).selectedIndex, -1);
      expect(find.widgetWithText(RsListRow, 'Display'), findsOneWidget);
      expect(find.widgetWithText(RsListRow, 'Accent'), findsOneWidget);

      await tap(tester, find.text('Audio'));
      expect(find.widgetWithText(RsListRow, 'UI sounds'), findsOneWidget);
      expect(find.widgetWithText(RsListRow, 'Display'), findsNothing);

      await tap(tester, find.text('Emulators'));
      expect(find.text('No emulators found.'), findsOneWidget);
      expect(find.widgetWithText(RsListRow, 'Super Nintendo'), findsNothing);

      await tap(tester, find.text('Account'));
      expect(find.widgetWithText(RsListRow, 'admin'), findsOneWidget);
      expect(find.widgetWithText(RsButton, 'Sign out'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(SettingsPage), findsNothing);
      expect(tester.widget<RsTopBar>(find.byType(RsTopBar)).selectedIndex, 0);
    } finally {
      await unmount(tester);
    }
  });

  testWidgets('narrow layout stacks categories and the open category', (
    tester,
  ) async {
    try {
      final container = await pump(tester, size: const Size(400, 800));
      await openSettings(tester, container);
      expect(find.text('Interface'), findsWidgets);
      expect(find.widgetWithText(RsListRow, 'Display'), findsOneWidget);
      expect(find.text('Audio'), findsOneWidget);
    } finally {
      await unmount(tester);
    }
  });

  testWidgets('display mode updates the theme and a reloaded store', (
    tester,
  ) async {
    final store = InMemoryClientSettingsStore();
    try {
      final container = await pump(tester, settings: store);
      await openSettings(tester, container);
      await tap(tester, find.widgetWithText(RsListRow, 'Display'));
      await tap(tester, find.text('Light'));

      expect(container.read(themeSettingsProvider).mode, ThemeMode.light);
      expect(
        tester
            .widget<RsListRow>(find.widgetWithText(RsListRow, 'Display'))
            .value,
        'Light',
      );
      expect((await store.load()).theme.mode, ThemeMode.light);

      final again = ProviderContainer(
        overrides: [clientSettingsStoreProvider.overrideWithValue(store)],
      );
      addTearDown(again.dispose);
      await again.read(clientSettingsProvider.notifier).ready;
      expect(again.read(themeSettingsProvider).mode, ThemeMode.light);
    } finally {
      await unmount(tester);
    }
  });

  testWidgets('UI sounds switch round-trips through the store', (tester) async {
    final store = InMemoryClientSettingsStore();
    try {
      final container = await pump(tester, settings: store);
      await openSettings(tester, container);
      await tap(tester, find.text('Audio'));

      final before = tester.widget<RsListRow>(
        find.widgetWithText(RsListRow, 'UI sounds'),
      );
      expect(before.switchValue, isTrue);

      await tap(tester, find.widgetWithText(RsListRow, 'UI sounds'));
      await container.read(clientSettingsProvider.notifier).persisted;
      await tester.pumpAndSettle();

      final after = tester.widget<RsListRow>(
        find.widgetWithText(RsListRow, 'UI sounds'),
      );
      expect(after.switchValue, isFalse);
      expect((await store.load()).uiSounds, isFalse);

      final again = ProviderContainer(
        overrides: [clientSettingsStoreProvider.overrideWithValue(store)],
      );
      addTearDown(again.dispose);
      await again.read(clientSettingsProvider.notifier).ready;
      expect(again.read(uiSoundsProvider), isFalse);
    } finally {
      await unmount(tester);
    }
  });

  testWidgets('choosing an emulator writes only that system', (tester) async {
    final launchStore = _MemoryLaunchStore(
      LaunchOptions(systems: {'psx': LaunchChoice(emulatorId: 'duckstation')}),
    );
    try {
      final container = await pump(
        tester,
        launchStore: launchStore,
        detected: _detected,
      );
      await openSettings(tester, container);
      await tap(tester, find.text('Emulators'));

      expect(find.widgetWithText(RsListRow, 'Super Nintendo'), findsOneWidget);
      expect(find.text('Ask when playing'), findsOneWidget);
      expect(find.text('DuckStation'), findsOneWidget);

      await tap(tester, find.widgetWithText(RsListRow, 'Super Nintendo'));
      await tap(tester, find.text('Snes9x'));
      await tap(tester, find.widgetWithText(RsButton, 'Save'));

      final options = container.read(launchOptionsProvider).requireValue;
      expect(options.systems['snes']?.emulatorId, 'snes9x');
      expect(options.systems['snes']?.corePath, isNull);
      expect(options.systems['psx']?.emulatorId, 'duckstation');
      expect(options.systems.length, 2);
      expect(launchStore.options.systems['snes']?.emulatorId, 'snes9x');
      expect(launchStore.options.systems['psx']?.emulatorId, 'duckstation');
    } finally {
      await unmount(tester);
    }
  });

  testWidgets('setting the snes folder does not change the global folder', (
    tester,
  ) async {
    try {
      final container = await pump(
        tester,
        destination: InstallDestination(globalFolder: '/roms'),
        records: [
          InstallRecord(
            serverId: 'server-1',
            gameId: 'chrono',
            systemId: 'snes',
            phase: InstallPhase.installed,
            receivedBytes: 1024,
            totalBytes: 1024,
          ),
        ],
      );
      await openSettings(tester, container);
      await tap(tester, find.text('Storage'));
      expect(find.text('/roms'), findsWidgets);
      await tap(tester, find.widgetWithText(RsListRow, 'Super Nintendo'));
      await tap(tester, find.widgetWithText(RsButton, 'Choose folder'));
      await tap(tester, find.widgetWithText(RsButton, 'Use this folder'));

      final destination = container.read(destinationsProvider).requireValue;
      expect(destination.globalFolder, '/roms');
      expect(destination.foldersBySystem['snes'], '/Users/test/snes');
      expect(destination.folderFor('nes'), '/roms');
    } finally {
      await unmount(tester);
    }
  });

  testWidgets('web hides storage and still shows a saved emulator choice', (
    tester,
  ) async {
    final launchStore = _MemoryLaunchStore(
      LaunchOptions(systems: {'snes': LaunchChoice(emulatorId: 'snes9x')}),
    );
    try {
      final container = await pump(
        tester,
        capabilities: ClientCapabilities.web(),
        launchStore: launchStore,
      );
      await openSettings(tester, container);

      expect(find.text('Storage'), findsNothing);
      await tap(tester, find.text('Emulators'));
      expect(find.text('This device does not start games.'), findsOneWidget);
      expect(find.widgetWithText(RsListRow, 'Super Nintendo'), findsOneWidget);
      expect(find.text('snes9x'), findsOneWidget);
      expect(find.text('No emulators found.'), findsNothing);
    } finally {
      await unmount(tester);
    }
  });
}
