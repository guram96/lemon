import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:rs_theme/rs_theme.dart';
import 'package:rs_ui/rs_ui.dart';

import 'steam_style.dart';

/// Thin rounded progress bar with an accent gradient fill and an optional
/// label row above it.
class SteamProgressBar extends StatelessWidget {
  const SteamProgressBar(this.config, {super.key});

  final RsProgressBar config;

  @override
  Widget build(BuildContext context) {
    final t = context.rsTokens;
    final text = SteamStyle.text(context);
    final bar = SteamBar(value: config.value);
    if (config.label == null && config.trailing == null) return bar;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (config.label != null)
              Expanded(
                child: Text(
                  config.label!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyMedium,
                ),
              )
            else
              const Spacer(),
            if (config.trailing != null)
              Text(
                config.trailing!,
                style: text.bodyMedium?.copyWith(
                  color: t.textMuted,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
          ],
        ),
        SizedBox(height: t.spacing.sm),
        bar,
      ],
    );
  }
}

/// The bar itself; `value == null` sweeps.
class SteamBar extends StatefulWidget {
  const SteamBar({super.key, required this.value, this.height});

  final double? value;
  final double? height;

  @override
  State<SteamBar> createState() => _SteamBarState();
}

class _SteamBarState extends State<SteamBar>
    with SingleTickerProviderStateMixin {
  AnimationController? _sweep;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(SteamBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    if (widget.value == null) {
      _sweep ??= AnimationController(
        vsync: this,
        duration: context.rsTokens.motion.spin * 1.4,
      )..repeat();
    } else {
      _sweep?.dispose();
      _sweep = null;
    }
  }

  @override
  void dispose() {
    _sweep?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.rsTokens;
    final h = widget.height ?? t.sizes.progressHeight;
    final fill = BoxDecoration(
      gradient: LinearGradient(
        colors: [t.accent, Color.lerp(t.accent, t.onAccent, 0.3)!],
      ),
      borderRadius: BorderRadius.circular(t.radii.pill),
    );
    final value = widget.value;
    final sweep = _sweep;
    return Semantics(
      value: value == null ? null : '${(value * 100).round()}%',
      child: Container(
        height: h,
        decoration: BoxDecoration(
          color: t.track,
          borderRadius: BorderRadius.circular(t.radii.pill),
        ),
        clipBehavior: Clip.antiAlias,
        child: sweep == null
            ? Align(
                alignment: Alignment.centerLeft,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: value!.clamp(0, 1)),
                  duration: t.motion.page,
                  curve: t.motion.curve,
                  builder: (_, v, _) => FractionallySizedBox(
                    widthFactor: v,
                    heightFactor: 1,
                    child: DecoratedBox(decoration: fill),
                  ),
                ),
              )
            : AnimatedBuilder(
                animation: sweep,
                builder: (_, _) {
                  final x = t.motion.curve.transform(sweep.value) * 2.6 - 1.3;
                  return Align(
                    alignment: Alignment(x, 0),
                    child: FractionallySizedBox(
                      widthFactor: 0.35,
                      heightFactor: 1,
                      child: DecoratedBox(decoration: fill),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

/// Steam-style spinner: two accent arcs rotating at different speeds.
class SteamSpinner extends StatefulWidget {
  const SteamSpinner(this.config, {super.key});

  final RsSpinner config;

  @override
  State<SteamSpinner> createState() => _SteamSpinnerState();
}

class _SteamSpinnerState extends State<SteamSpinner>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller ??= AnimationController(
      vsync: this,
      duration: context.rsTokens.motion.spin,
    )..repeat();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.rsTokens;
    final size = widget.config.size ?? t.sizes.spinner;
    final spinner = Semantics(
      label: widget.config.label ?? 'Loading',
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _SpinnerPainter(
            animation: _controller!,
            color: t.accent,
            track: t.track,
          ),
        ),
      ),
    );
    final label = widget.config.label;
    if (label == null) return spinner;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        spinner,
        SizedBox(width: t.spacing.md),
        Flexible(child: Text(label, style: SteamStyle.text(context).bodyLarge)),
      ],
    );
  }
}

class _SpinnerPainter extends CustomPainter {
  _SpinnerPainter({
    required this.animation,
    required this.color,
    required this.track,
  }) : super(repaint: animation);

  final Animation<double> animation;
  final Color color, track;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width / 9;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final v = animation.value;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 2, false, paint..color = track);
    // The sweep breathes between a short and a long arc while rotating.
    final length = math.pi * (0.35 + 0.9 * (0.5 - (v - 0.5).abs()) * 2);
    canvas.drawArc(
      rect,
      v * math.pi * 2 * 2 - math.pi / 2,
      length,
      false,
      paint..color = color,
    );
  }

  @override
  bool shouldRepaint(_SpinnerPainter old) =>
      old.color != color || old.track != track;
}
