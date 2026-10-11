import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rs_core/rs_core.dart';

import '../connection/connection_provider.dart';
import '../events/library_revision_provider.dart';
import '../session/session_provider.dart';

/// Filter of a game listing (`GET /library/games`).
@immutable
class GamesQuery {
  const GamesQuery({this.systemId, this.query, this.sort = GameSort.title});

  /// Every game, sorted by title.
  static const all = GamesQuery();

  /// EmulationStation system ID, `null` for every system.
  final String? systemId;

  /// Free-text search, `null` or empty for none.
  final String? query;

  /// [GameSort.title] or [GameSort.recent].
  final String sort;

  @override
  bool operator ==(Object other) =>
      other is GamesQuery &&
      other.systemId == systemId &&
      other.query == query &&
      other.sort == sort;

  @override
  int get hashCode => Object.hash(systemId, query, sort);

  @override
  String toString() => 'GamesQuery($systemId, $query, $sort)';
}

// Every library provider watches [libraryRevisionProvider], so it refetches
// when the server reports changes. Riverpod keeps the previous value while
// refetching (`AsyncValue.hasValue` stays true): screens read `.value` and
// only show a spinner when there is no data yet, so live updates never
// flash.

/// Systems with at least one game, as the server orders them.
final systemsProvider = FutureProvider<List<SystemSummary>>((ref) {
  ref.watch(libraryRevisionProvider);
  return ref.watch(apiClientProvider).systems();
});

/// Games matching a [GamesQuery].
final gamesProvider = FutureProvider.family<GamePage, GamesQuery>((
  ref,
  query,
) {
  ref.watch(libraryRevisionProvider);
  return ref
      .watch(apiClientProvider)
      .games(system: query.systemId, query: query.query, sort: query.sort);
});

/// How many games the "Recently added" shelf shows.
const recentGamesLimit = 20;

/// Newest games first, at most [recentGamesLimit].
///
/// Derived from the full listing ([GamesQuery.all]) that the home page loads
/// anyway, so it never costs a second request.
final recentGamesProvider = FutureProvider<List<Game>>((ref) async {
  final page = await ref.watch(gamesProvider(GamesQuery.all).future);
  return sortGames(
    page.games,
    GameSort.recent,
  ).take(recentGamesLimit).toList(growable: false);
});

/// One game, for the game page.
final gameProvider = FutureProvider.autoDispose.family<Game, String>((ref, id) {
  ref.watch(libraryRevisionProvider);
  return ref.watch(apiClientProvider).game(id);
});

/// Library folders of the server, for the empty-library help. Admin only;
/// empty for regular users.
final libraryRootsProvider = FutureProvider.autoDispose<List<LibraryRoot>>((
  ref,
) async {
  ref.watch(libraryRevisionProvider);
  final admin = ref.watch(
    sessionProvider.select((u) => u?.role == UserRole.admin),
  );
  if (!admin) return const [];
  return ref.watch(apiClientProvider).roots();
});

/// Display name of a system: from [systems] when listed, otherwise the
/// built-in catalog, otherwise the ID itself.
String systemName(String systemId, [Iterable<SystemSummary> systems = const []]) {
  for (final s in systems) {
    if (s.systemId == systemId) return s.name;
  }
  return GameSystems.byId(systemId)?.name ?? systemId;
}

/// Sorts locally the same way the server does: case-insensitive title, or
/// newest first. Lets screens switch order and filter without a refetch.
List<Game> sortGames(Iterable<Game> games, String sort) {
  final list = games.toList();
  int byTitle(Game a, Game b) {
    final c = a.title.toLowerCase().compareTo(b.title.toLowerCase());
    return c != 0 ? c : a.id.compareTo(b.id);
  }

  if (sort == GameSort.recent) {
    list.sort((a, b) {
      final c = b.addedAt.compareTo(a.addedAt);
      return c != 0 ? c : byTitle(a, b);
    });
  } else {
    list.sort(byTitle);
  }
  return list;
}

/// Groups [games] by system, in the order of [systems] (systems that are
/// not listed yet, for example while a scan streams in, come last by name).
/// Each group keeps the order of [games].
List<(String systemId, List<Game> games)> groupBySystem(
  Iterable<Game> games,
  List<SystemSummary> systems,
) {
  final groups = <String, List<Game>>{};
  for (final g in games) {
    (groups[g.systemId] ??= []).add(g);
  }
  final order = <String>[
    for (final s in systems)
      if (groups.containsKey(s.systemId)) s.systemId,
  ];
  final extra =
      groups.keys.where((id) => !order.contains(id)).toList()
        ..sort((a, b) => systemName(a).compareTo(systemName(b)));
  return [
    for (final id in [...order, ...extra]) (id, groups[id]!),
  ];
}

/// Library page view state (selected system tab and sort), kept while the
/// app runs so the page comes back the way it was left.
@immutable
class LibraryView {
  const LibraryView({this.systemId, this.sort = GameSort.title});

  /// Selected system tab, `null` for "All".
  final String? systemId;
  final String sort;
}

final libraryViewProvider = NotifierProvider<LibraryViewNotifier, LibraryView>(
  LibraryViewNotifier.new,
);

class LibraryViewNotifier extends Notifier<LibraryView> {
  @override
  LibraryView build() => const LibraryView();

  void selectSystem(String? systemId) =>
      state = LibraryView(systemId: systemId, sort: state.sort);

  void toggleSort() => state = LibraryView(
    systemId: state.systemId,
    sort: state.sort == GameSort.title ? GameSort.recent : GameSort.title,
  );
}
