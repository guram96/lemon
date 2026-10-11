import 'package:flutter/material.dart';
import 'package:rs_core/rs_core.dart';
import 'package:rs_theme/rs_theme.dart';

/// Meaning of a status line or callout, mapped to theme tokens.
enum Tone { ok, info, warning, danger, muted }

extension on Tone {
  Color color(RsTokens t) => switch (this) {
    Tone.ok => t.success,
    Tone.info => t.accent,
    Tone.warning => t.warning,
    Tone.danger => t.danger,
    Tone.muted => t.textMuted,
  };
}

/// One line of feedback: tinted icon + text.
class StatusLine extends StatelessWidget {
  const StatusLine({
    super.key,
    required this.icon,
    required this.text,
    this.tone = Tone.muted,
  });

  final IconData icon;
  final String text;
  final Tone tone;

  @override
  Widget build(BuildContext context) {
    final t = context.rsTokens;
    final style = Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: t.spacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: t.sizes.icon, color: tone.color(t)),
          SizedBox(width: t.spacing.sm),
          Expanded(
            child: Text(
              text,
              style: style?.copyWith(
                color: tone == Tone.muted ? t.textMuted : t.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tinted panel with an icon, a title and a body.
class Callout extends StatelessWidget {
  const Callout({
    super.key,
    required this.tone,
    required this.icon,
    required this.title,
    this.message,
    this.child,
  });

  final Tone tone;
  final IconData icon;
  final String title;
  final String? message;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final t = context.rsTokens;
    final text = Theme.of(context).textTheme;
    final color = tone.color(t);
    return Container(
      padding: EdgeInsets.all(t.spacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(t.radii.md),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: t.sizes.icon),
          SizedBox(width: t.spacing.sm + t.spacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: text.titleSmall?.copyWith(color: t.textPrimary),
                ),
                if (message != null) ...[
                  SizedBox(height: t.spacing.xs),
                  Text(
                    message!,
                    style: text.bodyMedium?.copyWith(color: t.textSecondary),
                  ),
                ],
                if (child != null) ...[SizedBox(height: t.spacing.sm), child!],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact, non-interactive "Super Nintendo · 12" chip.
class SystemChip extends StatelessWidget {
  const SystemChip({super.key, required this.systemId, required this.count});

  final String systemId;
  final int count;

  @override
  Widget build(BuildContext context) {
    final t = context.rsTokens;
    final style = Theme.of(context).textTheme.labelMedium;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: t.spacing.sm + t.spacing.xs,
        vertical: t.spacing.xs + t.spacing.xs / 2,
      ),
      decoration: BoxDecoration(
        color: t.surfaceRaised,
        borderRadius: BorderRadius.circular(t.radii.pill),
        border: Border.all(color: t.divider),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: systemName(systemId),
              style: TextStyle(color: t.textPrimary),
            ),
            TextSpan(
              text: '  $count',
              style: TextStyle(color: t.textMuted),
            ),
          ],
        ),
        style: style,
      ),
    );
  }
}

/// Wraps [SystemChip]s for a system → count map, biggest first.
class SystemChips extends StatelessWidget {
  const SystemChips({super.key, required this.counts});

  final Map<String, int> counts;

  @override
  Widget build(BuildContext context) {
    final t = context.rsTokens;
    final entries = counts.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        return byCount != 0 ? byCount : a.key.compareTo(b.key);
      });
    return Wrap(
      spacing: t.spacing.sm,
      runSpacing: t.spacing.sm,
      children: [
        for (final e in entries) SystemChip(systemId: e.key, count: e.value),
      ],
    );
  }
}

/// Display name of an EmulationStation system ID.
String systemName(String systemId) =>
    GameSystems.byId(systemId)?.name ?? systemId;

/// `1.2 TB`, `340 GB`, `12 MB`.
String formatBytes(int bytes) {
  const units = ['B', 'KB', 'MB', 'GB', 'TB', 'PB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1000 && unit < units.length - 1) {
    value /= 1000;
    unit++;
  }
  final digits = unit == 0 || value >= 100 ? 0 : 1;
  return '${value.toStringAsFixed(digits)} ${units[unit]}';
}

String plural(int n, String one, [String? many]) =>
    '$n ${n == 1 ? one : (many ?? '${one}s')}';

/// Fades and lifts [child] in once, after [delay] — for staggered entrances.
class Entrance extends StatefulWidget {
  const Entrance({super.key, required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  late Animation<double> _curved;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) return;
    final motion = context.rsTokens.motion;
    // The delay is part of the animation (no timers): it starts at once and
    // stays transparent until its interval begins.
    final total = widget.delay + motion.slow;
    final start = widget.delay.inMicroseconds / total.inMicroseconds;
    final c = _controller = AnimationController(vsync: this, duration: total)
      ..forward();
    _curved = CurvedAnimation(
      parent: c,
      curve: Interval(start, 1, curve: motion.emphasizedCurve),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _curved,
    child: SlideTransition(
      position: Tween(
        begin: const Offset(0, 0.08),
        end: Offset.zero,
      ).animate(_curved),
      child: widget.child,
    ),
  );
}
