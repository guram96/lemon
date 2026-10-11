import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rs_client/src/app/retro_steam_app.dart';
import 'package:rs_client/src/connection/connection_provider.dart';
import 'package:rs_client/src/connection/server_address.dart';
import 'package:rs_client/src/downloads/downloads_page.dart';
import 'package:rs_client/src/game/game_page.dart';
import 'package:rs_client/src/home/home_page.dart';
import 'package:rs_client/src/install/download_queue.dart';
import 'package:rs_client/src/install/install_models.dart';
import 'package:rs_client/src/install/install_store.dart';
import 'package:rs_client/src/library/library_page.dart';
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

final _chrono = Game(
  id: 'chrono',
  systemId: 'snes',
  title: 'Chrono Trigger',
  rootId: 'root-1',
  files: const [GameFile(path: 'snes/Chrono Trigger.sfc', sizeBytes: 1024)],
  addedAt: DateTime.utc(2020, 6, 15),
);

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

class _QueueLog {
  final paused = <String>[];
  final resumed = <String>[];
  final cancelled = <String>[];
  final uninstalled = <String>[];
  final enqueued = <String>[];
}

class _FakeQueue extends DownloadQueueNotifier {
  _FakeQueue(this.log, this.initial);

  final _QueueLog log;
  final List<InstallRecord> initial;

  @override
  List<InstallRecord> build() => [...initial];

  @override
  Future<void> enqueue(Game game) async {
    log.enqueued.add(game.id);
    state = [
      ...state,
      InstallRecord(
        serverId: 'server-1',
        gameId: game.id,
        systemId: game.systemId,
        phase: InstallPhase.queued,
        receivedBytes: 0,
        totalBytes: game.sizeBytes,
      ),
    ];
  }

  @override
  Future<void> pause(String gameId) async {
    log.paused.add(gameId);
    _setPhase(gameId, InstallPhase.paused);
  }

  @override
  Future<void> resume(String gameId) async {
    log.resumed.add(gameId);
    _setPhase(gameId, InstallPhase.downloading);
  }

  @override
  Future<void> cancel(String gameId) async {
    log.cancelled.add(gameId);
    state = [
      for (final record in state)
        if (record.gameId != gameId) record,
    ];
  }

  @override
  Future<void> uninstallGame(String gameId) async {
    log.uninstalled.add(gameId);
    state = [
      for (final record in state)
        if (record.gameId != gameId) record,
    ];
  }

  void _setPhase(String gameId, InstallPhase phase) {
    state = [
      for (final record in state)
        if (record.gameId == gameId) record.copyWith(phase: phase) else record,
    ];
  }
}

class _FixedDestinations extends DestinationsNotifier {
  _FixedDestinations(this.destination);

  final InstallDestination destination;

  @override
  Future<InstallDestination> build() async => destination;
}

InstallRecord _record({
  required String gameId,
  required InstallPhase phase,
  int receivedBytes = 0,
  int totalBytes = 0,
  String? error,
}) => InstallRecord(
  serverId: 'server-1',
  gameId: gameId,
  systemId: 'snes',
  phase: phase,
  receivedBytes: receivedBytes,
  totalBytes: totalBytes,
  error: error,
);

void main() {
  final noFolder = InstallDestination();

  Future<ProviderContainer> pump(
    WidgetTester tester, {
    List<InstallRecord> records = const [],
    InstallDestination? destination,
    ClientCapabilities? capabilities,
    _QueueLog? log,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1280, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final queueLog = log ?? _QueueLog();
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
        downloadQueueProvider.overrideWith(() => _FakeQueue(queueLog, records)),
        destinationsProvider.overrideWith(
          () => _FixedDestinations(destination ?? noFolder),
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

  Future<void> go(ProviderContainer container, String location) async {
    container.read(routerProvider).go(location);
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Finder rowButton(String gameId, String label) => find.descendant(
    of: find.byKey(ValueKey<String>('server-1/$gameId')),
    matching: find.widgetWithText(RsButton, label),
  );

  int selected(WidgetTester tester) =>
      tester.widget<RsTopBar>(find.byType(RsTopBar)).selectedIndex;

  List<String> labels(WidgetTester tester) => [
    for (final item in tester.widget<RsTopBar>(find.byType(RsTopBar)).items)
      item.label,
  ];

  testWidgets('a download shows its title, phase, and progress', (
    tester,
  ) async {
    final log = _QueueLog();
    try {
      final container = await pump(
        tester,
        log: log,
        records: [
          _record(
            gameId: 'chrono',
            phase: InstallPhase.downloading,
            receivedBytes: 512,
            totalBytes: 1024,
          ),
        ],
      );
      await go(container, AppRoutes.downloads);
      await tester.pumpAndSettle();

      expect(find.byType(DownloadsPage), findsOneWidget);
      expect(find.text('Chrono Trigger'), findsOneWidget);
      expect(find.text('Downloading'), findsOneWidget);
      final bar = tester.widget<RsProgressBar>(find.byType(RsProgressBar));
      expect(bar.value, 0.5);
      expect(bar.trailing, '512 B / 1 KB');

      await tap(tester, find.widgetWithText(RsButton, 'Pause'));
      expect(log.paused, ['chrono']);
      expect(find.text('Paused'), findsOneWidget);
      expect(find.widgetWithText(RsButton, 'Pause'), findsNothing);
      expect(find.widgetWithText(RsButton, 'Resume'), findsOneWidget);

      await tap(tester, find.widgetWithText(RsButton, 'Resume'));
      expect(log.resumed, ['chrono']);
      expect(find.text('Downloading'), findsOneWidget);
      expect(find.widgetWithText(RsButton, 'Pause'), findsOneWidget);
    } finally {
      await unmount(tester);
    }
  });

  testWidgets('remove, resume, and uninstall update the queue', (tester) async {
    final log = _QueueLog();
    try {
      final container = await pump(
        tester,
        log: log,
        records: [
          _record(gameId: 'mystery', phase: InstallPhase.queued),
          _record(
            gameId: 'failed-game',
            phase: InstallPhase.failed,
            error: 'Disk full',
          ),
          _record(gameId: 'chrono', phase: InstallPhase.installed),
        ],
      );
      await go(container, AppRoutes.downloads);
      await tester.pumpAndSettle();

      expect(find.text('mystery'), findsOneWidget);
      expect(find.text('Queued'), findsOneWidget);
      expect(find.text('failed-game'), findsOneWidget);
      expect(find.text('Failed'), findsOneWidget);
      expect(find.text('Disk full'), findsOneWidget);
      expect(find.text('Chrono Trigger'), findsOneWidget);
      expect(find.text('Installed'), findsOneWidget);
      expect(find.byType(RsProgressBar), findsNothing);
      expect(rowButton('mystery', 'Pause'), findsNothing);
      expect(rowButton('chrono', 'Uninstall'), findsOneWidget);
      expect(rowButton('failed-game', 'Resume'), findsOneWidget);

      await tap(tester, rowButton('failed-game', 'Resume'));
      expect(log.resumed, ['failed-game']);
      expect(find.text('Downloading'), findsOneWidget);

      await tap(tester, rowButton('mystery', 'Remove'));
      expect(log.cancelled, ['mystery']);
      expect(find.text('mystery'), findsNothing);

      await tap(tester, rowButton('chrono', 'Uninstall'));
      expect(log.uninstalled, ['chrono']);
      expect(find.text('Chrono Trigger'), findsNothing);

      await tap(tester, rowButton('failed-game', 'Remove'));
      expect(log.cancelled, ['mystery', 'failed-game']);
      expect(
        find.text('No games are installed or downloading.'),
        findsOneWidget,
      );
    } finally {
      await unmount(tester);
    }
  });

  testWidgets('an empty queue does not show an install folder', (tester) async {
    try {
      final container = await pump(
        tester,
        destination: InstallDestination(globalFolder: '/roms/games'),
      );
      await go(container, AppRoutes.downloads);
      await tester.pumpAndSettle();

      expect(find.text('/roms/games'), findsNothing);
      expect(find.text('Install folder'), findsNothing);
      expect(find.widgetWithText(RsButton, 'Change folder'), findsNothing);
      expect(find.widgetWithText(RsButton, 'Choose folder'), findsNothing);
      expect(
        find.text('No games are installed or downloading.'),
        findsOneWidget,
      );
      expect(find.widgetWithText(RsButton, 'Pause'), findsNothing);
      expect(find.widgetWithText(RsButton, 'Uninstall'), findsNothing);
    } finally {
      await unmount(tester);
    }
  });

  testWidgets('nav selects Home, Library, and Downloads', (tester) async {
    try {
      final container = await pump(tester);

      expect(labels(tester), ['Home', 'Library', 'Downloads']);
      expect(selected(tester), 0);

      await tap(tester, find.text('Downloads'));
      expect(find.byType(DownloadsPage), findsOneWidget);
      expect(selected(tester), 2);

      await go(container, AppRoutes.library);
      await tester.pumpAndSettle();
      expect(find.byType(LibraryPage), findsOneWidget);
      expect(selected(tester), 1);

      await go(container, AppRoutes.game('chrono'));
      await tester.pumpAndSettle();
      expect(find.byType(GameDetailPage), findsOneWidget);
      expect(selected(tester), 0);

      await go(container, AppRoutes.downloads);
      await tester.pumpAndSettle();
      expect(selected(tester), 2);

      await tap(tester, find.text('Home'));
      expect(find.byType(HomePage), findsOneWidget);
      expect(selected(tester), 0);
    } finally {
      await unmount(tester);
    }
  });

  testWidgets('web omits Downloads and keeps Library at index 1', (
    tester,
  ) async {
    try {
      final container = await pump(
        tester,
        capabilities: ClientCapabilities.web(),
      );

      expect(labels(tester), ['Home', 'Library']);
      expect(find.text('Downloads'), findsNothing);
      expect(selected(tester), 0);

      await go(container, AppRoutes.library);
      await tester.pumpAndSettle();
      expect(selected(tester), 1);

      await go(container, AppRoutes.game('chrono'));
      await tester.pumpAndSettle();
      expect(selected(tester), 0);
      expect(find.widgetWithText(RsButton, 'Install'), findsNothing);
    } finally {
      await unmount(tester);
    }
  });

  testWidgets('Install starts a job when the system folder is set', (
    tester,
  ) async {
    final log = _QueueLog();
    try {
      final container = await pump(
        tester,
        log: log,
        destination: InstallDestination(
          foldersBySystem: {'snes': '/roms/snes'},
        ),
      );
      await go(container, AppRoutes.game('chrono'));
      await tester.pumpAndSettle();

      final install = tester.widget<RsButton>(
        find.widgetWithText(RsButton, 'Install'),
      );
      expect(install.onPressed, isNotNull);
      expect(find.text('Pick a folder in Settings.'), findsNothing);

      await tap(tester, find.widgetWithText(RsButton, 'Install'));
      expect(log.enqueued, ['chrono']);
      expect(find.text('Queued'), findsOneWidget);
      expect(find.widgetWithText(RsButton, 'Install'), findsNothing);
    } finally {
      await unmount(tester);
    }
  });

  testWidgets('a downloading or paused game is not enqueued again', (
    tester,
  ) async {
    try {
      final container = await pump(
        tester,
        destination: InstallDestination(globalFolder: '/roms'),
        records: [
          _record(
            gameId: 'chrono',
            phase: InstallPhase.downloading,
            receivedBytes: 1,
            totalBytes: 4,
          ),
        ],
      );
      await go(container, AppRoutes.game('chrono'));
      await tester.pumpAndSettle();

      expect(find.text('Downloading'), findsOneWidget);
      expect(find.widgetWithText(RsButton, 'Install'), findsNothing);
      expect(find.widgetWithText(RsButton, 'Uninstall'), findsNothing);
    } finally {
      await unmount(tester);
    }
  });

  testWidgets('a paused game shows its phase', (tester) async {
    try {
      final container = await pump(
        tester,
        destination: InstallDestination(globalFolder: '/roms'),
        records: [_record(gameId: 'chrono', phase: InstallPhase.paused)],
      );
      await go(container, AppRoutes.game('chrono'));
      await tester.pumpAndSettle();

      expect(find.text('Paused'), findsOneWidget);
      expect(find.widgetWithText(RsButton, 'Install'), findsNothing);
    } finally {
      await unmount(tester);
    }
  });

  testWidgets('an installed game uninstalls from the game page', (
    tester,
  ) async {
    final log = _QueueLog();
    try {
      final container = await pump(
        tester,
        log: log,
        destination: InstallDestination(globalFolder: '/roms'),
        records: [_record(gameId: 'chrono', phase: InstallPhase.installed)],
      );
      await go(container, AppRoutes.game('chrono'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(RsButton, 'Install'), findsNothing);
      await tap(tester, find.widgetWithText(RsButton, 'Uninstall'));
      expect(log.uninstalled, ['chrono']);

      final install = tester.widget<RsButton>(
        find.widgetWithText(RsButton, 'Install'),
      );
      expect(install.onPressed, isNotNull);
    } finally {
      await unmount(tester);
    }
  });
}
