import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rs_core/rs_core.dart';
import 'package:rs_theme/rs_theme.dart';
import 'package:rs_ui/rs_ui.dart';

import '../install/download_queue.dart';
import '../install/install_models.dart';
import '../library/format.dart';
import '../library/library_providers.dart';

/// `Queued`, `Downloading`, `Paused`, `Installed`, `Failed`.
String installPhaseLabel(InstallPhase phase) {
  final name = phase.name;
  return '${name[0].toUpperCase()}${name.substring(1)}';
}

/// Download queue. Install folders live in Settings. The shell draws the top bar.
class DownloadsPage extends ConsumerWidget {
  const DownloadsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.rsTokens;
    final text = Theme.of(context).textTheme;
    final records = ref.watch(downloadQueueProvider);
    final games = ref.watch(gamesProvider(GamesQuery.all)).value?.games;
    final gutter = context.rsPageGutter;

    if (records.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: gutter),
          child: Text(
            'No games are installed or downloading.',
            textAlign: TextAlign.center,
            style: text.bodyLarge?.copyWith(color: t.textSecondary),
          ),
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.only(top: t.spacing.lg, bottom: t.spacing.xxl),
      children: [
        for (final record in records)
          _DownloadRow(
            key: ValueKey('${record.serverId}/${record.gameId}'),
            record: record,
            title: _titleFor(record, games),
          ),
      ],
    );
  }
}

String _titleFor(InstallRecord record, List<Game>? games) {
  if (games == null) return record.gameId;
  for (final game in games) {
    if (game.id == record.gameId) return game.title;
  }
  return record.gameId;
}

class _DownloadRow extends ConsumerWidget {
  const _DownloadRow({super.key, required this.record, required this.title});

  final InstallRecord record;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.rsTokens;
    final text = Theme.of(context).textTheme;
    final gutter = context.rsPageGutter;
    final phase = record.phase;
    final queue = downloadQueueProvider.notifier;
    final id = record.gameId;

    return Padding(
      padding: EdgeInsets.fromLTRB(gutter, 0, gutter, t.spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.titleMedium?.copyWith(color: t.textPrimary),
          ),
          SizedBox(height: t.spacing.xs),
          Text(
            installPhaseLabel(phase),
            style: text.bodyLarge?.copyWith(color: t.textSecondary),
          ),
          if (record.error case final error? when error.isNotEmpty) ...[
            SizedBox(height: t.spacing.xs),
            Text(
              error,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: text.bodyMedium?.copyWith(color: t.danger),
            ),
          ],
          if (record.totalBytes > 0) ...[
            SizedBox(height: t.spacing.sm),
            RsProgressBar(
              value: _fraction(record),
              trailing:
                  '${formatBytes(record.receivedBytes)} / ${formatBytes(record.totalBytes)}',
            ),
          ],
          SizedBox(height: t.spacing.sm),
          Wrap(
            spacing: t.spacing.md,
            runSpacing: t.spacing.sm,
            children: [
              if (phase == InstallPhase.downloading)
                RsButton(
                  label: 'Pause',
                  icon: Icons.pause_rounded,
                  onPressed: () => ref.read(queue).pause(id),
                ),
              if (phase == InstallPhase.paused || phase == InstallPhase.failed)
                RsButton(
                  label: 'Resume',
                  icon: Icons.play_arrow_rounded,
                  onPressed: () => ref.read(queue).resume(id),
                ),
              if (phase != InstallPhase.installed)
                RsButton(
                  label: 'Remove',
                  icon: Icons.close_rounded,
                  onPressed: () => ref.read(queue).cancel(id),
                ),
              if (phase == InstallPhase.installed)
                RsButton(
                  label: 'Uninstall',
                  icon: Icons.delete_outline_rounded,
                  variant: RsButtonVariant.danger,
                  onPressed: () => ref.read(queue).uninstallGame(id),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// `receivedBytes / totalBytes`, clamped to 0..1. [InstallRecord.totalBytes]
/// is greater than zero when this is shown.
double _fraction(InstallRecord record) {
  final total = record.totalBytes;
  if (total <= 0) return 0;
  final value = record.receivedBytes / total;
  if (value <= 0) return 0;
  if (value >= 1) return 1;
  return value;
}
