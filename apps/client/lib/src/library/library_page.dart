import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rs_core/rs_core.dart';
import 'package:rs_theme/rs_theme.dart';
import 'package:rs_ui/rs_ui.dart';

import '../events/scan_status_provider.dart';
import '../library/library_game_card.dart';
import '../library/library_providers.dart';
import '../library/library_status.dart';
import '../library/library_widgets.dart';
import '../routing/app_routes.dart';

/// All games, filtered by system tab and sorted by title or date added.
///
/// Sits below the top bar; the shell does not draw this page behind it.
class LibraryPage extends ConsumerWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamesAsync = ref.watch(gamesProvider(GamesQuery.all));
    final systemsAsync = ref.watch(systemsProvider);
    final view = ref.watch(libraryViewProvider);
    final scan = ref.watch(scanStatusProvider);

    final placeholder = libraryPlaceholder(gamesAsync);
    if (placeholder != null) return placeholder;

    final games = gamesAsync.value!.games;
    final systems = systemsAsync.value ?? const <SystemSummary>[];
    final known = systems.any((s) => s.systemId == view.systemId);
    final systemId = known ? view.systemId : null;
    final selected = systemId == null
        ? 0
        : systems.indexWhere((s) => s.systemId == systemId) + 1;
    final visible = sortGames(
      systemId == null ? games : games.where((g) => g.systemId == systemId),
      view.sort,
    );
    final t = context.rsTokens;
    final bar = libraryScanBar(scan, systems);
    final sortLabel = view.sort == GameSort.recent ? 'Recently added' : 'Title';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RsTabs(
          tabs: [
            RsTab(label: 'All', count: games.length),
            for (final system in systems)
              RsTab(
                label: system.name,
                count: games.where((g) => g.systemId == system.systemId).length,
              ),
          ],
          selectedIndex: selected,
          onChanged: (index) {
            final id = index == 0 ? null : systems[index - 1].systemId;
            ref.read(libraryViewProvider.notifier).selectSystem(id);
          },
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            context.rsPageGutter,
            t.spacing.sm,
            context.rsPageGutter,
            t.spacing.sm,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: RsButton(
              label: sortLabel,
              icon: Icons.sort_rounded,
              onPressed: () =>
                  ref.read(libraryViewProvider.notifier).toggleSort(),
            ),
          ),
        ),
        if (bar != null)
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.rsPageGutter,
              0,
              context.rsPageGutter,
              t.spacing.md,
            ),
            child: bar,
          ),
        Expanded(
          child: RsGrid(
            itemCount: visible.length,
            empty: _EmptyGrid(systemId: systemId, systems: systems, scan: scan),
            itemBuilder: (context, i) {
              final game = visible[i];
              return LibraryGameCard(
                key: ValueKey(game.id),
                game: game,
                systems: systems,
                onPressed: () {
                  unawaited(context.push(AppRoutes.game(game.id)));
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _EmptyGrid extends StatelessWidget {
  const _EmptyGrid({
    required this.systemId,
    required this.systems,
    required this.scan,
  });

  final String? systemId;
  final List<SystemSummary> systems;
  final ScanStatus scan;

  @override
  Widget build(BuildContext context) {
    if (systemId == null) {
      return LibraryMessage(
        icon: Icons.sports_esports_outlined,
        title: scanningLibraryMessage,
        content: libraryScanBar(scan, systems),
      );
    }
    return LibraryMessage(
      icon: Icons.sports_esports_outlined,
      title: 'No games',
      body: 'No games for ${systemName(systemId!, systems)}.',
    );
  }
}
