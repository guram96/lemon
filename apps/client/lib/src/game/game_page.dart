import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rs_core/rs_core.dart';
import 'package:rs_theme/rs_theme.dart';
import 'package:rs_ui/rs_ui.dart';

import '../connection/connection_provider.dart';
import '../downloads/downloads_page.dart';
import '../install/download_queue.dart';
import '../install/install_models.dart';
import '../install/install_store.dart';
import '../launch/emulator_detector.dart';
import '../launch/game_launcher.dart';
import '../launch/launch_models.dart';
import '../launch/launch_picker.dart';
import '../launch/launch_store.dart';
import '../library/format.dart';
import '../library/game_art.dart';
import '../library/library_providers.dart';
import '../library/library_status.dart';
import '../platform/client_capabilities.dart';
import '../storage/credential_store.dart';

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
                  _InstallRow(game: game),
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

class _InstallRow extends ConsumerStatefulWidget {
  const _InstallRow({required this.game});

  final Game game;

  @override
  ConsumerState<_InstallRow> createState() => _InstallRowState();
}

class _InstallRowState extends ConsumerState<_InstallRow> {
  String? _serverId;
  var _credentialsReady = false;
  String? _launchNote;

  @override
  void initState() {
    super.initState();
    if (ref.read(clientCapabilitiesProvider).canLaunchGames) {
      unawaited(_loadServerId());
    }
  }

  Future<void> _loadServerId() async {
    final stored = await ref.read(credentialStoreProvider).load();
    if (!mounted) return;
    setState(() {
      _serverId = stored.serverId;
      _credentialsReady = true;
    });
  }

  Future<void> _onPlay(LaunchChoice? choice) async {
    final game = widget.game;
    if (choice == null) {
      await showLaunchPicker(context: context, ref: ref, game: game);
      return;
    }
    final caps = ref.read(clientCapabilitiesProvider);
    final folder = ref
        .read(destinationsProvider)
        .value
        ?.folderFor(game.systemId);
    final record = _recordFor(game.id, ref.read(downloadQueueProvider));
    final detected = ref.read(detectedEmulatorsProvider);
    final result = await ref
        .read(gameLauncherProvider)
        .launch(
          platform: caps.platform,
          game: game,
          record: record,
          folder: folder,
          choice: choice,
          detected: detected,
        );
    if (!mounted) return;
    setState(() {
      _launchNote = switch (result) {
        LaunchStarted() => null,
        LaunchFailed(:final message) => message,
        LaunchUnsupported() => "This device can't start an emulator.",
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final t = context.rsTokens;
    final text = Theme.of(context).textTheme;
    final caps = ref.watch(clientCapabilitiesProvider);
    final folder = ref
        .watch(destinationsProvider)
        .value
        ?.folderFor(game.systemId);
    final record = _recordFor(game.id, ref.watch(downloadQueueProvider));
    final showLaunch =
        record?.phase == InstallPhase.installed && caps.canLaunchGames;

    LaunchOptions? loaded;
    if (showLaunch) {
      final options = ref.watch(launchOptionsProvider);
      if (options case AsyncData<LaunchOptions>(:final value)) {
        loaded = value;
      }
    }
    final choice = loaded?.resolve(game.systemId, _serverId ?? '', game.id);
    final playEnabled = loaded != null && _credentialsReady;

    final Widget? button;
    final String? note;
    if (record == null) {
      if (folder == null) {
        button = const RsButton(
          label: 'Install',
          icon: Icons.download_rounded,
          variant: RsButtonVariant.primary,
          onPressed: null,
        );
        note = 'Pick a folder on the Downloads page.';
      } else {
        button = RsButton(
          label: 'Install',
          icon: Icons.download_rounded,
          variant: RsButtonVariant.primary,
          onPressed: () =>
              ref.read(downloadQueueProvider.notifier).enqueue(game),
        );
        note = null;
      }
    } else if (record.phase == InstallPhase.installed) {
      button = RsButton(
        label: 'Uninstall',
        icon: Icons.delete_outline_rounded,
        variant: RsButtonVariant.danger,
        onPressed: () =>
            ref.read(downloadQueueProvider.notifier).uninstallGame(game.id),
      );
      note = _launchNote;
    } else {
      // Queued, downloading, paused, or failed: the job already exists.
      button = null;
      note = installPhaseLabel(record.phase);
    }

    return Wrap(
      spacing: t.spacing.md,
      runSpacing: t.spacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (showLaunch)
          RsButton(
            label: 'Play',
            icon: Icons.play_arrow_rounded,
            variant: RsButtonVariant.primary,
            onPressed: playEnabled ? () => unawaited(_onPlay(choice)) : null,
          ),
        ?button,
        if (showLaunch)
          RsButton(
            label: 'Emulator',
            variant: RsButtonVariant.standard,
            onPressed: () => unawaited(
              showLaunchPicker(context: context, ref: ref, game: game),
            ),
          ),
        if (note != null)
          Text(note, style: text.bodyLarge?.copyWith(color: t.textSecondary)),
      ],
    );
  }
}

InstallRecord? _recordFor(String gameId, List<InstallRecord> records) {
  for (final record in records) {
    if (record.gameId == gameId) return record;
  }
  return null;
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
