import 'package:flutter/material.dart';
import 'package:rs_theme/rs_theme.dart';

/// Shared visual recipes of the Crossblade set, all derived from [RsTokens].
abstract final class CrossbladeStyle {
  /// Whether endless ambient motion (waves, breathing glows) should run.
  ///
  /// Off when the platform asks for reduced motion, and under a test
  /// binding, so `pumpAndSettle` can settle.
  static bool ambientMotion(BuildContext context) =>
      WidgetsBinding.instance is WidgetsFlutterBinding &&
      !MediaQuery.disableAnimationsOf(context);

  /// Neon glow around a focused element. [pulse] (0–1) breathes it.
  static List<BoxShadow> glow(
    RsTokens t, {
    double strength = 1,
    double pulse = 0.5,
  }) {
    final a = t.focusGlow.a * strength * (0.75 + pulse * 0.25);
    return [
      BoxShadow(
        color: t.focusGlow.withValues(alpha: a),
        blurRadius: t.sizes.focusGlowBlur * (0.8 + pulse * 0.4),
        spreadRadius: t.sizes.focusRingWidth * (1 + pulse),
      ),
      BoxShadow(
        color: t.focusRing.withValues(alpha: 0.35 * strength),
        blurRadius: t.sizes.focusRingWidth * 3,
      ),
    ];
  }

  /// Deep shadow under resting tiles and floating panels.
  static List<BoxShadow> depth(RsTokens t, {double scale = 1}) => [
    BoxShadow(
      color: t.shadow,
      blurRadius: t.spacing.lg * scale,
      offset: Offset(0, t.spacing.sm * scale),
    ),
  ];

  /// Glossy 2000s console fill: lit top, darker belly, a hint of rim light.
  static LinearGradient gloss(Color base, {double shine = 0.35}) =>
      LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: const [0, 0.48, 0.52, 1],
        colors: [
          Color.lerp(base, const Color(0xFFFFFFFF), shine)!,
          Color.lerp(base, const Color(0xFFFFFFFF), shine * 0.35)!,
          base,
          Color.lerp(base, const Color(0xFF000000), 0.28)!,
        ],
      );

  /// Translucent glass panel fill (resting buttons, rows, dialogs).
  static LinearGradient glass(RsTokens t) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color.lerp(t.surfaceRaised, t.textPrimary, 0.06)!, t.surface],
  );

  /// Thin bright rim along the top of a glass panel.
  static Border rim(RsTokens t, {double alpha = 1}) =>
      Border.all(color: t.divider.withValues(alpha: t.divider.a * alpha));

  /// Text theme of the current [Theme].
  static TextTheme text(BuildContext context) => Theme.of(context).textTheme;
}

/// A parallelogram with rounded corners: the shape of an Xbox 360 blade.
class BladeBorder extends OutlinedBorder {
  const BladeBorder({
    this.slant = 10,
    this.radius = 4,
    super.side = BorderSide.none,
  });

  /// Horizontal offset of the top edge relative to the bottom edge.
  final double slant;
  final double radius;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  Path _path(Rect r) {
    final s = slant.clamp(0, r.width / 3).toDouble();
    final k = radius.clamp(0, r.height / 3).toDouble();
    final pts = [
      Offset(r.left + s, r.top),
      Offset(r.right, r.top),
      Offset(r.right - s, r.bottom),
      Offset(r.left, r.bottom),
    ];
    Offset toward(Offset a, Offset b, double d) {
      final v = b - a;
      return a + v / v.distance * d;
    }

    final start = toward(pts[0], pts[1], k);
    final path = Path()..moveTo(start.dx, start.dy);
    for (var i = 1; i <= pts.length; i++) {
      final corner = pts[i % 4];
      final a = toward(corner, pts[i - 1], k);
      final b = toward(corner, pts[(i + 1) % 4], k);
      path
        ..lineTo(a.dx, a.dy)
        ..quadraticBezierTo(corner.dx, corner.dy, b.dx, b.dy);
    }
    return path..close();
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      _path(rect.deflate(side.width));

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => _path(rect);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none || side.width == 0) return;
    canvas.drawPath(
      _path(rect.deflate(side.width / 2)),
      side.toPaint()..style = PaintingStyle.stroke,
    );
  }

  @override
  ShapeBorder scale(double t) =>
      BladeBorder(slant: slant * t, radius: radius * t, side: side.scale(t));

  @override
  BladeBorder copyWith({BorderSide? side}) =>
      BladeBorder(slant: slant, radius: radius, side: side ?? this.side);

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) => a is BladeBorder
      ? BladeBorder(
          slant: Tween(begin: a.slant, end: slant).transform(t),
          radius: Tween(begin: a.radius, end: radius).transform(t),
          side: BorderSide.lerp(a.side, side, t),
        )
      : super.lerpFrom(a, t);

  @override
  bool operator ==(Object other) =>
      other is BladeBorder &&
      other.slant == slant &&
      other.radius == radius &&
      other.side == side;

  @override
  int get hashCode => Object.hash(slant, radius, side);
}

/// The glowing jewel at the heart of the dashboard: a glassy green sphere
/// with a hard specular highlight and an inner "X" of light.
class CrossbladeOrb extends StatelessWidget {
  const CrossbladeOrb({super.key, required this.size, this.glow = 1});

  final double size;

  /// Outer glow strength, 0–1.
  final double glow;

  @override
  Widget build(BuildContext context) {
    final t = context.rsTokens;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _OrbPainter(
          color: t.focusSurface,
          glow: glow,
          ink: t.onFocusSurface,
        ),
      ),
    );
  }
}

class _OrbPainter extends CustomPainter {
  _OrbPainter({required this.color, required this.glow, required this.ink});

  final Color color;
  final double glow;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    const white = Color(0xFFFFFFFF);
    if (glow > 0) {
      canvas.drawCircle(
        c,
        r * 1.05,
        Paint()
          ..color = color.withValues(alpha: 0.55 * glow)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.6),
      );
    }
    // Body.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.4),
          radius: 1.1,
          colors: [
            Color.lerp(color, white, 0.55)!,
            color,
            Color.lerp(color, const Color(0xFF000000), 0.55)!,
          ],
          stops: const [0, 0.45, 1],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    // Inner X of light.
    final x = Paint()
      ..color = white.withValues(alpha: 0.85)
      ..strokeWidth = r * 0.22
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.06);
    final d = r * 0.42;
    canvas
      ..drawLine(c + Offset(-d, -d), c + Offset(d, d), x)
      ..drawLine(c + Offset(d, -d), c + Offset(-d, d), x);
    // Specular highlight.
    final hl = Rect.fromCenter(
      center: c + Offset(-r * 0.22, -r * 0.48),
      width: r * 1.1,
      height: r * 0.62,
    );
    canvas.drawOval(
      hl,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [white.withValues(alpha: 0.85), white.withValues(alpha: 0)],
        ).createShader(hl),
    );
    // Rim.
    canvas.drawCircle(
      c,
      r - 0.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = ink.withValues(alpha: 0.45),
    );
  }

  @override
  bool shouldRepaint(_OrbPainter old) =>
      old.color != color || old.glow != glow || old.ink != ink;
}

/// Runs [builder] with a 0–1 value that breathes while [active] and ambient
/// motion is allowed; otherwise it holds at 0.5.
class CrossbladePulse extends StatefulWidget {
  const CrossbladePulse({
    super.key,
    required this.active,
    required this.builder,
    this.period = const Duration(milliseconds: 1600),
  });

  final bool active;
  final Duration period;
  final Widget Function(BuildContext context, double pulse) builder;

  @override
  State<CrossbladePulse> createState() => _CrossbladePulseState();
}

class _CrossbladePulseState extends State<CrossbladePulse>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: widget.period,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(CrossbladePulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final run = widget.active && CrossbladeStyle.ambientMotion(context);
    if (run && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!run && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) => widget.builder(
      context,
      _controller.isAnimating
          ? Curves.easeInOut.transform(_controller.value)
          : 0.5,
    ),
  );
}
