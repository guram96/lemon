import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:rs_theme/rs_theme.dart';

import 'crossblade_style.dart';

/// Full-screen Crossblade backdrop: a midnight gradient, a green jewel glow
/// and a sapphire glow in opposite corners, a faint dot grid, drifting
/// sparkles, and flowing XMB-style ribbons of light across the middle.
///
/// The ribbons move only when ambient motion is allowed
/// ([CrossbladeStyle.ambientMotion]); otherwise a still frame is drawn.
class CrossbladeBackdrop extends StatefulWidget {
  const CrossbladeBackdrop({
    super.key,
    this.sky = true,
    this.ribbonLevel = 0.58,
  });

  /// Whether to paint the opaque sky (gradient, glows, grid, vignette).
  /// Without it only the ribbons and sparkles are drawn, as an overlay.
  final bool sky;

  /// Vertical center of the ribbons, as a fraction of the height.
  final double ribbonLevel;

  @override
  State<CrossbladeBackdrop> createState() => _CrossbladeBackdropState();
}

class _CrossbladeBackdropState extends State<CrossbladeBackdrop>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_onTick);
  final _time = ValueNotifier<double>(12);

  void _onTick(Duration elapsed) =>
      _time.value = 12 + elapsed.inMicroseconds / 1e6;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final run = CrossbladeStyle.ambientMotion(context);
    if (run && !_ticker.isActive) {
      _ticker.start();
    } else if (!run && _ticker.isActive) {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.rsTokens;
    final dark = t.background.computeLuminance() < 0.3;
    return RepaintBoundary(
      child: CustomPaint(
        painter: _BackdropPainter(
          time: _time,
          top: t.background,
          bottom: t.backgroundGradientEnd,
          green: t.focusSurface,
          sapphire: Color.lerp(
            const Color(0xFF2F6BFF),
            t.backgroundGradientEnd,
            dark ? 0 : 0.2,
          )!,
          light: dark ? const Color(0xFFFFFFFF) : const Color(0xFF0B2A6B),
          dark: dark,
          sky: widget.sky,
          level: widget.ribbonLevel,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _BackdropPainter extends CustomPainter {
  _BackdropPainter({
    required this.time,
    required this.top,
    required this.bottom,
    required this.green,
    required this.sapphire,
    required this.light,
    required this.dark,
    required this.sky,
    required this.level,
  }) : super(repaint: time);

  final ValueNotifier<double> time;
  final Color top, bottom, green, sapphire, light;
  final bool dark;
  final bool sky;
  final double level;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final s = time.value;
    final rect = Offset.zero & size;

    if (sky) _paintSky(canvas, rect, s);
    _paintRibbons(canvas, rect, s);
    if (sky) _paintVignette(canvas, rect);
  }

  void _paintSky(Canvas canvas, Rect rect, double s) {
    final w = rect.width;
    final h = rect.height;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [top, Color.lerp(top, bottom, 0.55)!, bottom],
          stops: const [0, 0.55, 1],
        ).createShader(rect),
    );

    // Corner glows: green jewel low left, sapphire high right.
    void glow(Offset c, double r, Color color, double alpha) {
      final g = Rect.fromCircle(center: c, radius: r);
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [
              color.withValues(alpha: alpha),
              color.withValues(alpha: 0),
            ],
          ).createShader(g),
      );
    }

    final breathe = 0.85 + 0.15 * math.sin(s * 0.6);
    glow(
      Offset(w * 0.08, h * 1.02),
      math.max(w, h) * 0.62,
      green,
      (dark ? 0.32 : 0.26) * breathe,
    );
    glow(
      Offset(w * 0.95, h * -0.05),
      math.max(w, h) * 0.55,
      sapphire,
      dark ? 0.42 : 0.3,
    );

    // Dot grid, fading out towards the bottom.
    final grid = Paint()..color = light.withValues(alpha: dark ? 0.05 : 0.07);
    const step = 26.0;
    for (var y = step / 2; y < h * 0.62; y += step) {
      final fade = 1 - y / (h * 0.62);
      final row = (y / step).floor();
      grid.color = light.withValues(alpha: (dark ? 0.055 : 0.07) * fade);
      for (var x = (row.isOdd ? step / 2 : 0.0); x < w; x += step) {
        canvas.drawCircle(Offset(x, y), 1.1, grid);
      }
    }
  }

  /// XMB ribbons and sparkles. Each ribbon is a soft band plus a bundle of
  /// fine lines.
  void _paintRibbons(Canvas canvas, Rect rect, double s) {
    final w = rect.width;
    final h = rect.height;
    final ribbons = [
      (h * level, h * 0.075, 0.55, 0.0, light, 1.0),
      (h * (level + 0.04), h * 0.06, -0.38, 1.7, sapphire, 0.9),
      (h * (level - 0.03), h * 0.05, 0.27, 3.1, green, 0.7),
    ];
    final blend = dark ? BlendMode.plus : BlendMode.srcOver;
    for (final (baseY, amp, speed, phase, color, weight) in ribbons) {
      double y(double x, double offset) {
        final u = x / w * math.pi * 2;
        return baseY +
            math.sin(u * 0.9 + s * speed + phase + offset) * amp +
            math.sin(u * 2.1 - s * speed * 0.6 + phase * 2) * amp * 0.35;
      }

      // Band.
      final band = Path()..moveTo(0, y(0, 0));
      const samples = 90;
      for (var i = 1; i <= samples; i++) {
        final x = w * i / samples;
        band.lineTo(x, y(x, 0));
      }
      for (var i = samples; i >= 0; i--) {
        final x = w * i / samples;
        band.lineTo(x, y(x, 0.55) + amp * 0.5);
      }
      band.close();
      canvas.drawPath(
        band,
        Paint()
          ..blendMode = blend
          ..shader = LinearGradient(
            colors: [
              color.withValues(alpha: 0),
              color.withValues(alpha: (dark ? 0.09 : 0.08) * weight),
              color.withValues(alpha: (dark ? 0.05 : 0.04) * weight),
              color.withValues(alpha: 0),
            ],
            stops: const [0, 0.35, 0.7, 1],
          ).createShader(rect)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );

      // Fine lines.
      for (var l = 0; l < 6; l++) {
        final off = l * 0.11;
        final line = Path()..moveTo(0, y(0, off));
        for (var i = 1; i <= samples; i++) {
          final x = w * i / samples;
          line.lineTo(x, y(x, off) + l * 2.2);
        }
        canvas.drawPath(
          line,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = l == 0 ? 1.6 : 0.8
            ..blendMode = blend
            ..shader = LinearGradient(
              colors: [
                color.withValues(alpha: 0),
                color.withValues(alpha: (l == 0 ? 0.5 : 0.22) * weight),
                color.withValues(alpha: (l == 0 ? 0.35 : 0.14) * weight),
                color.withValues(alpha: 0),
              ],
              stops: const [0, 0.3, 0.75, 1],
            ).createShader(rect),
        );
      }
    }

    // Drifting sparkles (PS2 boot-screen dust).
    final rnd = math.Random(7);
    final sparkle = Paint()..blendMode = blend;
    for (var i = 0; i < 46; i++) {
      final sx = rnd.nextDouble();
      final sy = rnd.nextDouble();
      final v = 0.004 + rnd.nextDouble() * 0.012;
      final r = 0.6 + rnd.nextDouble() * 1.6;
      final x = (sx + math.sin(s * 0.2 + i) * 0.01) * w;
      final y = ((sy - s * v) % 1) * h;
      final twinkle = 0.5 + 0.5 * math.sin(s * (1 + rnd.nextDouble() * 2) + i);
      sparkle
        ..color = (i % 5 == 0 ? green : light).withValues(
          alpha: (dark ? 0.5 : 0.35) * twinkle,
        )
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r);
      canvas.drawCircle(Offset(x, y), r, sparkle);
    }
  }

  void _paintVignette(Canvas canvas, Rect rect) {
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          radius: 1.0,
          colors: [
            top.withValues(alpha: 0),
            top.withValues(alpha: dark ? 0.55 : 0.2),
          ],
          stops: const [0.55, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_BackdropPainter old) =>
      old.top != top ||
      old.bottom != bottom ||
      old.green != green ||
      old.sapphire != sapphire ||
      old.light != light ||
      old.dark != dark ||
      old.sky != sky ||
      old.level != level;
}
