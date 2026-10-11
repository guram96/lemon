import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rs_core/rs_core.dart';
import 'package:rs_theme/rs_theme.dart';
import 'package:rs_ui/rs_ui.dart';

import '../connection/connection_provider.dart';
import '../events/scan_status_provider.dart';
import '../library/format.dart';
import '../library/game_art.dart';
import '../library/library_game_card.dart';
import '../library/library_providers.dart';
import '../library/library_status.dart';
import '../library/library_widgets.dart';
import '../routing/app_routes.dart';

/// Big Picture home. The backdrop draws behind the top bar; the shelves are
/// padded below it.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  String? _focusedId;

  void _onFocus(Game game, bool focused) {
    if (!focused || _focusedId == game.id) return;
    setState(() => _focusedId = game.id);
  }

  Game? _backdropGame(List<Game> recent, List<Game> ordered) {
    final id = _focusedId;
    if (id != null) {
      for (final game in ordered) {
        if (game.id == id) return game;
      }
    }
    if (recent.isNotEmpty) return recent.first;
    if (ordered.isNotEmpty) return ordered.first;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final gamesAsync = ref.watch(gamesProvider(GamesQuery.all));
    final recentAsync = ref.watch(recentGamesProvider);
    final systems = ref.watch(systemsProvider).value ?? const <SystemSummary>[];
    final scan = ref.watch(scanStatusProvider);

    final placeholder = libraryPlaceholder(gamesAsync);
    if (placeholder != null) {
      return Padding(
        padding: EdgeInsets.only(top: context.rsTokens.sizes.topBar),
        child: placeholder,
      );
    }

    final page = gamesAsync.value!;
    if (page.games.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(top: context.rsTokens.sizes.topBar),
        child: _EmptyLibrary(scan: scan, systems: systems),
      );
    }

    final ordered = sortGames(page.games, GameSort.title);
    final recent =
        recentAsync.value ??
        sortGames(
          page.games,
          GameSort.recent,
        ).take(recentGamesLimit).toList(growable: false);
    final backdrop = _backdropGame(recent, ordered);
    final groups = groupBySystem(ordered, systems);
    final t = context.rsTokens;
    final bar = libraryScanBar(scan, systems);

    return Stack(
      fit: StackFit.expand,
      children: [
        if (backdrop != null)
          Positioned.fill(
            child: _HomeBackdrop(game: backdrop, systems: systems),
          ),
        const Positioned.fill(child: _HomeScrim()),
        Positioned.fill(
          child: ListView(
            padding: EdgeInsets.only(
              top: t.sizes.topBar + t.spacing.lg,
              bottom: t.spacing.xxl,
            ),
            children: [
              if (bar != null)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    context.rsPageGutter,
                    0,
                    context.rsPageGutter,
                    t.spacing.lg,
                  ),
                  child: bar,
                ),
              if (recent.isNotEmpty)
                RsShelf(
                  key: const ValueKey('recent'),
                  title: 'Recently added',
                  subtitle: formatGameCount(recent.length),
                  itemCount: recent.length,
                  itemAspectRatio: RsArtLayout.wide.aspectRatio!,
                  itemBuilder: (context, i) => _card(
                    context,
                    recent[i],
                    systems,
                    layout: RsArtLayout.wide,
                    showSystemBadge: true,
                    autofocus: i == 0,
                  ),
                ),
              for (final (systemId, group) in groups)
                RsShelf(
                  key: ValueKey('system-$systemId'),
                  title: systemName(systemId, systems),
                  subtitle: formatGameCount(group.length),
                  itemCount: group.length,
                  itemBuilder: (context, i) => _card(
                    context,
                    group[i],
                    systems,
                    layout: RsArtLayout.cover,
                    showSystemBadge: false,
                    autofocus: false,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _card(
    BuildContext context,
    Game game,
    List<SystemSummary> systems, {
    required RsArtLayout layout,
    required bool showSystemBadge,
    required bool autofocus,
  }) {
    return LibraryGameCard(
      key: ValueKey(game.id),
      game: game,
      systems: systems,
      layout: layout,
      showSystemBadge: showSystemBadge,
      autofocus: autofocus,
      onFocusChanged: (focused) => _onFocus(game, focused),
      onPressed: () {
        unawaited(context.push(AppRoutes.game(game.id)));
      },
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary({required this.scan, required this.systems});

  final ScanStatus scan;
  final List<SystemSummary> systems;

  @override
  Widget build(BuildContext context) {
    final discovering = scan.isRunning && scan.total <= 0;
    final id = scan.currentSystemId;
    return LibraryMessage(
      icon: Icons.sports_esports_outlined,
      title: scanningLibraryMessage,
      body: discovering && id != null
          ? 'Scanning ${systemName(id, systems)}'
          : null,
      content: libraryScanBar(scan, systems),
    );
  }
}

class _HomeBackdrop extends ConsumerWidget {
  const _HomeBackdrop({required this.game, required this.systems});

  final Game game;
  final List<SystemSummary> systems;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.rsTokens;
    final api = ref.watch(apiClientProvider);
    return AnimatedSwitcher(
      duration: t.motion.slow,
      switchInCurve: t.motion.curve,
      switchOutCurve: t.motion.exitCurve,
      child: SizedBox.expand(
        key: ValueKey(game.id),
        child: RsGameArt(
          title: game.title,
          systemId: game.systemId,
          systemName: systemName(game.systemId, systems),
          image: gameArtwork(api, game, ArtKinds.background),
          layout: RsArtLayout.background,
        ),
      ),
    );
  }
}

class _HomeScrim extends StatelessWidget {
  const _HomeScrim();

  @override
  Widget build(BuildContext context) {
    final t = context.rsTokens;
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0, 0.45, 1],
            colors: [
              t.background.withValues(alpha: 0.2),
              t.background.withValues(alpha: 0.72),
              t.background,
            ],
          ),
        ),
      ),
    );
  }
}
