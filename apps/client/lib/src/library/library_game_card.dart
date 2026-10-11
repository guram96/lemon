import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rs_core/rs_core.dart';
import 'package:rs_ui/rs_ui.dart';

import '../connection/connection_provider.dart';
import 'game_art.dart';
import 'library_providers.dart';

/// One focusable capsule. Give it a [Key] of the game id so a refetch keeps
/// the same card.
class LibraryGameCard extends ConsumerWidget {
  const LibraryGameCard({
    super.key,
    required this.game,
    required this.systems,
    required this.onPressed,
    this.layout = RsArtLayout.cover,
    this.showSystemBadge = false,
    this.autofocus = false,
    this.onFocusChanged,
  });

  final Game game;
  final List<SystemSummary> systems;
  final VoidCallback onPressed;
  final RsArtLayout layout;
  final bool showSystemBadge;
  final bool autofocus;
  final ValueChanged<bool>? onFocusChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.watch(apiClientProvider);
    final kinds = layout == RsArtLayout.wide ? ArtKinds.wide : ArtKinds.cover;
    return RsGameCard(
      title: game.title,
      systemId: game.systemId,
      systemName: systemName(game.systemId, systems),
      image: gameArtwork(api, game, kinds),
      layout: layout,
      showSystemBadge: showSystemBadge,
      autofocus: autofocus,
      onFocusChanged: onFocusChanged,
      onPressed: onPressed,
    );
  }
}
