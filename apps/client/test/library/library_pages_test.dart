import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rs_client/src/app/retro_steam_app.dart';
import 'package:rs_client/src/auth/login_page.dart';
import 'package:rs_client/src/connection/connection_provider.dart';
import 'package:rs_client/src/connection/server_address.dart';
import 'package:rs_client/src/events/library_revision_provider.dart';
import 'package:rs_client/src/game/game_page.dart';
import 'package:rs_client/src/home/home_page.dart';
import 'package:rs_client/src/install/download_queue.dart';
import 'package:rs_client/src/install/install_models.dart';
import 'package:rs_client/src/install/install_store.dart';
import 'package:rs_client/src/library/format.dart';
import 'package:rs_client/src/library/library_page.dart';
import 'package:rs_client/src/library/library_status.dart';
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

DateTime _added(int year) => DateTime.utc(year, 6, 15, 12);

final _chrono = Game(
  id: 'chrono',
  systemId: 'snes',
  title: 'Chrono Trigger',
  rootId: 'root-1',
  files: const [
    GameFile(path: 'snes/Chrono Trigger.sfc', sizeBytes: 4 * 1024 * 1024),
    GameFile(path: 'snes/Chrono Trigger.cue', sizeBytes: 512),
  ],
  addedAt: _added(2020),
  description: 'A trip through time.',
  developer: 'Square',
  publisher: 'Squaresoft',
  releaseYear: 1995,
);

final _mario = Game(
  id: 'mario',
  systemId: 'snes',
  title: 'Super Mario World',
  rootId: 'root-1',
  files: const [
    GameFile(path: 'snes/Super Mario World.sfc', sizeBytes: 512 * 1024),
  ],
  addedAt: _added(2024),
);

final _zelda = Game(
  id: 'zelda',
  systemId: 'nes',
  title: 'The Legend of Zelda',
  rootId: 'root-1',
  files: const [
    GameFile(path: 'nes/The Legend of Zelda.nes', sizeBytes: 256 * 1024),
  ],
  addedAt: _added(2022),
);

const _systems = [
  SystemSummary(
    systemId: 'nes',
    name: 'Nintendo Entertainment System',
    gameCount: 1,
  ),
  SystemSummary(systemId: 'snes', name: 'Super Nintendo', gameCount: 2),
];

class LibraryApi extends FakeApiClient {
  LibraryApi({List<Game>? games, List<SystemSummary>? systems})
    : catalog = List<Game>.of(games ?? [_chrono, _mario, _zelda]),
      systemsList = List<SystemSummary>.of(systems ?? _systems),
      super(info: serverInfo());

  List<Game> catalog;
  List<SystemSummary> systemsList;
  Object? gamesError;
  Completer<void>? holdGames;

  @override
  Future<List<SystemSummary>> systems() async => systemsList;

  @override
  Future<GamePage> games({
    String? system,
    String? query,
    String sort = GameSort.title,
  }) async {
    final hold = holdGames;
    if (hold != null) await hold.future;
    if (gamesError case final error?) throw error;
    return GamePage(games: [...catalog], total: catalog.length);
  }

  @override
  Future<Game> game(String id) async {
    for (final game in catalog) {
      if (game.id == id) return game;
    }
    throw apiError(404, ApiErrorCodes.notFound);
  }

  @override
  Future<List<LibraryRoot>> roots() async => const [];
}

void main() {
  Future<ProviderContainer> pumpLibrary(
    WidgetTester tester,
    LibraryApi api, {
    ClientCapabilities? capabilities,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final container = ProviderContainer(
      overrides: [
        apiClientFactoryProvider.overrideWithValue((_) => api),
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
        downloadQueueProvider.overrideWith(_EmptyQueue.new),
        destinationsProvider.overrideWith(_NoFolder.new),
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

  List<String> cardTitles(WidgetTester tester) => [
    for (final card in tester.widgetList<RsGameCard>(find.byType(RsGameCard)))
      card.title,
  ];

  testWidgets('home shows recent and per-system shelves and opens a game', (
    tester,
  ) async {
    final api = LibraryApi();
    try {
      await pumpLibrary(tester, api);

      expect(find.byType(HomePage), findsOneWidget);
      expect(find.text('Recently added'), findsOneWidget);
      expect(find.text('Super Nintendo'), findsOneWidget);
      expect(find.text('Nintendo Entertainment System'), findsOneWidget);
      expect(find.text('Chrono Trigger'), findsWidgets);
      expect(find.text('Super Mario World'), findsWidgets);
      expect(find.byType(RsSpinner), findsNothing);
      expect(find.byKey(const ValueKey<String>('chrono')), findsWidgets);

      await tester.tap(
        find
            .byWidgetPredicate(
              (widget) =>
                  widget is RsGameCard && widget.title == 'Super Mario World',
            )
            .first,
      );
      await tester.pumpAndSettle();

      expect(find.byType(GameDetailPage), findsOneWidget);
      expect(find.text('Super Mario World'), findsWidgets);
    } finally {
      await unmount(tester);
    }
  });

  testWidgets('empty library explains that games appear while scanning', (
    tester,
  ) async {
    final api = LibraryApi(games: const [], systems: const []);
    api.scan = const ScanStatus(
      phase: ScanPhase.hashing,
      processed: 4,
      total: 10,
      currentSystemId: 'snes',
    );
    try {
      await pumpLibrary(tester, api);

      expect(find.text(scanningLibraryMessage), findsOneWidget);
      expect(find.text('Scanning Super Nintendo'), findsOneWidget);
      expect(find.text('4 / 10'), findsOneWidget);
      final bar = tester.widget<RsProgressBar>(find.byType(RsProgressBar));
      expect(bar.value, closeTo(0.4, 0.001));
      expect(find.byType(RsSpinner), findsNothing);
      expect(find.byType(RsGameCard), findsNothing);
    } finally {
      await unmount(tester);
    }
  });

  testWidgets('settled empty library has no repeating progress', (
    tester,
  ) async {
    final api = LibraryApi(games: const [], systems: const []);
    try {
      await pumpLibrary(tester, api);
      expect(find.text(scanningLibraryMessage), findsOneWidget);
      expect(find.byType(RsProgressBar), findsNothing);
      expect(find.byType(RsSpinner), findsNothing);
    } finally {
      await unmount(tester);
    }
  });

  testWidgets('a failed library load is an error, not a spinner', (
    tester,
  ) async {
    final api = LibraryApi()
      ..gamesError = apiError(500, ApiErrorCodes.internal);
    try {
      await pumpLibrary(tester, api);
      expect(find.text("Couldn't load the library"), findsOneWidget);
      expect(find.text('internal'), findsWidgets);
      expect(find.byType(RsSpinner), findsNothing);
      expect(find.byType(RsProgressBar), findsNothing);
    } finally {
      await unmount(tester);
    }
  });

  testWidgets('a 401 leaves the generic error to the session', (tester) async {
    final api = LibraryApi()
      ..gamesError = apiError(401, ApiErrorCodes.unauthorized);
    try {
      await pumpLibrary(tester, api);
      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.text("Couldn't load the library"), findsNothing);
    } finally {
      await unmount(tester);
    }
  });

  testWidgets('a library revision keeps the current games on screen', (
    tester,
  ) async {
    final api = LibraryApi();
    try {
      final container = await pumpLibrary(tester, api);
      expect(find.byKey(const ValueKey<String>('chrono')), findsWidgets);
      expect(find.text('Super Metroid'), findsNothing);

      final hold = Completer<void>();
      api.holdGames = hold;
      api.catalog = [
        ...api.catalog,
        Game(
          id: 'metroid',
          systemId: 'snes',
          title: 'Super Metroid',
          rootId: 'root-1',
          files: const [
            GameFile(path: 'snes/Super Metroid.sfc', sizeBytes: 1024),
          ],
          addedAt: _added(2025),
        ),
      ];
      container.read(libraryRevisionProvider.notifier).bump();
      await tester.pump();

      expect(find.text('Loading your library'), findsNothing);
      expect(find.byKey(const ValueKey<String>('chrono')), findsWidgets);
      expect(find.text('Super Metroid'), findsNothing);

      hold.complete();
      api.holdGames = null;
      await tester.pumpAndSettle();

      expect(find.text('Super Metroid'), findsWidgets);
      expect(find.byKey(const ValueKey<String>('chrono')), findsWidgets);
    } finally {
      await unmount(tester);
    }
  });

  testWidgets('library tabs filter the grid and sort changes the order', (
    tester,
  ) async {
    final api = LibraryApi();
    try {
      final container = await pumpLibrary(tester, api);
      container.read(routerProvider).go(AppRoutes.library);
      await tester.pumpAndSettle();

      expect(find.byType(LibraryPage), findsOneWidget);
      expect(
        find.descendant(of: find.byType(RsTabs), matching: find.text('ALL')),
        findsOneWidget,
      );
      expect(cardTitles(tester), [
        'Chrono Trigger',
        'Super Mario World',
        'The Legend of Zelda',
      ]);

      await tester.tap(
        find.descendant(
          of: find.byType(RsTabs),
          matching: find.text('SUPER NINTENDO'),
        ),
      );
      await tester.pumpAndSettle();
      expect(cardTitles(tester), ['Chrono Trigger', 'Super Mario World']);

      await tester.tap(
        find.descendant(of: find.byType(RsTabs), matching: find.text('ALL')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(RsButton, 'Title'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(RsButton, 'Recently added'), findsOneWidget);
      expect(cardTitles(tester), [
        'Super Mario World',
        'The Legend of Zelda',
        'Chrono Trigger',
      ]);
    } finally {
      await unmount(tester);
    }
  });

  testWidgets('a system tab with no games shows an empty grid', (tester) async {
    final api = LibraryApi()
      ..systemsList = [
        ..._systems,
        const SystemSummary(systemId: 'genesis', name: 'Genesis', gameCount: 0),
      ];
    try {
      final container = await pumpLibrary(tester, api);
      container.read(routerProvider).go(AppRoutes.library);
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.byType(RsTabs),
          matching: find.text('GENESIS'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(RsGameCard), findsNothing);
      expect(find.text('No games'), findsOneWidget);
      expect(find.text('No games for Genesis.'), findsOneWidget);
    } finally {
      await unmount(tester);
    }
  });

  testWidgets(
    'game page shows the hero and keeps install disabled without a folder',
    (tester) async {
      final api = LibraryApi();
      try {
        final container = await pumpLibrary(tester, api);
        container.read(routerProvider).go(AppRoutes.game('chrono'));
        await tester.pumpAndSettle();

        expect(find.byType(GameDetailPage), findsOneWidget);
        expect(find.byType(RsHero), findsOneWidget);
        expect(find.text('Chrono Trigger'), findsWidgets);
        expect(find.text('Super Nintendo'), findsWidgets);
        expect(find.text(formatBytes(_chrono.sizeBytes)), findsWidgets);
        expect(find.text('Chrono Trigger.sfc'), findsOneWidget);
        expect(find.text(formatBytes(512)), findsOneWidget);
        expect(find.text('A trip through time.'), findsOneWidget);
        expect(find.text('Square'), findsOneWidget);
        expect(find.text('Squaresoft'), findsOneWidget);
        expect(find.text('1995'), findsOneWidget);
        expect(find.text(formatDate(_chrono.addedAt)), findsOneWidget);

        final install = tester.widget<RsButton>(
          find.widgetWithText(RsButton, 'Install'),
        );
        expect(install.variant, RsButtonVariant.primary);
        expect(install.onPressed, isNull);
        expect(find.text('Pick a folder in Settings.'), findsOneWidget);
      } finally {
        await unmount(tester);
      }
    },
  );

  testWidgets('web hides the install row', (tester) async {
    final api = LibraryApi();
    try {
      final container = await pumpLibrary(
        tester,
        api,
        capabilities: ClientCapabilities.web(),
      );
      container.read(routerProvider).go(AppRoutes.game('chrono'));
      await tester.pumpAndSettle();

      expect(find.text('Chrono Trigger'), findsWidgets);
      expect(find.widgetWithText(RsButton, 'Install'), findsNothing);
      expect(find.text('Pick a folder in Settings.'), findsNothing);
    } finally {
      await unmount(tester);
    }
  });

  testWidgets('a missing game is a not-found message', (tester) async {
    final api = LibraryApi();
    try {
      final container = await pumpLibrary(tester, api);
      container.read(routerProvider).go(AppRoutes.game('missing'));
      await tester.pumpAndSettle();

      expect(find.byType(GameDetailPage), findsOneWidget);
      expect(find.text('Game not found'), findsOneWidget);
      expect(
        find.text('It may have been removed from the library.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    } finally {
      await unmount(tester);
    }
  });
}

class _EmptyQueue extends DownloadQueueNotifier {
  @override
  List<InstallRecord> build() => const [];
}

class _NoFolder extends DestinationsNotifier {
  @override
  Future<InstallDestination> build() async => InstallDestination();
}
