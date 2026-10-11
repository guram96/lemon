import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rs_core/rs_core.dart';
import 'package:rs_theme/rs_theme.dart';
import 'package:rs_ui/rs_ui.dart';

import '../connection/connection_provider.dart';
import '../library/format.dart';
import '../library/game_art.dart';
import '../library/library_providers.dart';
import '../library/library_status.dart';
import '../platform/client_capabilities.dart';

/// One game. The hero is the full-width header and starts below the top bar.
class GameDetailPage extends ConsumerWidget {
  const GameDetailPage({super.key, required this.gameId});

  /// From the `/game/:id` path.
  final String gameId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameAsync = ref.watch(gameProvider(gameId));
    final systems = ref.watch(systemsProvider).value ?? const <SystemSummary>[];
    final caps = ref.watch(clientCapabilitiesProvider);
    final api = ref.watch(apiClientProvider);

    final placeholder = libraryPlaceholder(
      gameAsync,
      title: "Couldn't load this game",
      notFoundTitle: 'Game not found',
      notFoundBody: 'It may have been removed from the library.',
      loadingLabel: 'Loading',
    );
    final t = context.rsTokens;
    if (placeholder != null) {
      return Padding(
        padding: EdgeInsets.only(top: t.sizes.topBar),
        child: placeholder,
      );
    }

    final game = gameAsync.value!;
    final name = systemName(game.systemId, systems);
    final text = Theme.of(context).textTheme;
    final gutter = context.rsPageGutter;

    return SingleChildScrollView(
      padding: EdgeInsets.only(top: t.sizes.topBar, bottom: t.spacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RsHero(
            title: game.title,
            systemId: game.systemId,
            systemName: name,
            image: gameArtwork(api, game, ArtKinds.background),
            logo: gameArtwork(api, game, ArtKinds.logo),
            subtitle: [
              name,
              if (game.releaseYear != null) '${game.releaseYear}',
            ].join(' · '),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatBytes(game.sizeBytes),
                  style: text.titleLarge?.copyWith(color: t.textPrimary),
                ),
                if (caps.canInstallGames) ...[
                  SizedBox(height: t.spacing.md),
                  const _InstallRow(),
                ],
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(gutter, t.spacing.lg, gutter, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (game.description case final description?
                    when description.isNotEmpty)
                  Text(
                    description,
                    style: text.bodyLarge?.copyWith(color: t.textSecondary),
                  ),
                _Detail(label: 'System', value: name),
                if (game.developer case final developer?
                    when developer.isNotEmpty)
                  _Detail(label: 'Developer', value: developer),
                if (game.publisher case final publisher?
                    when publisher.isNotEmpty)
                  _Detail(label: 'Publisher', value: publisher),
                if (game.releaseYear != null)
                  _Detail(label: 'Released', value: '${game.releaseYear}'),
                _Detail(label: 'Added', value: formatDate(game.addedAt)),
                if (game.files.isNotEmpty) ...[
                  SizedBox(height: t.spacing.xl),
                  Text(
                    'Files',
                    style: text.titleMedium?.copyWith(color: t.textPrimary),
                  ),
                  for (final file in game.files)
                    Padding(
                      padding: EdgeInsets.only(top: t.spacing.sm),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              fileName(file.path),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.bodyLarge?.copyWith(
                                color: t.textPrimary,
                              ),
                            ),
                          ),
                          SizedBox(width: t.spacing.md),
                          Text(
                            formatBytes(file.sizeBytes),
                            style: text.bodyMedium?.copyWith(
                              color: t.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InstallRow extends StatelessWidget {
  const _InstallRow();

  @override
  Widget build(BuildContext context) {
    final t = context.rsTokens;
    final text = Theme.of(context).textTheme;
    return Wrap(
      spacing: t.spacing.md,
      runSpacing: t.spacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const RsButton(
          label: 'Install',
          icon: Icons.download_rounded,
          variant: RsButtonVariant.primary,
          onPressed: null,
        ),
        Text(
          'Downloads arrive in M3',
          style: text.bodyLarge?.copyWith(color: t.textSecondary),
        ),
      ],
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = context.rsTokens;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(top: t.spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: text.labelMedium?.copyWith(color: t.textMuted)),
          SizedBox(height: t.spacing.xs),
          Text(value, style: text.bodyLarge?.copyWith(color: t.textPrimary)),
        ],
      ),
    );
  }
}
