import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:rs_theme/rs_theme.dart';
import 'package:rs_ui/rs_ui.dart';

import 'steam_style.dart';

/// Game artwork with generated fallback. The real image fades in over the
/// generated art once it has loaded; on error the generated art stays.
class SteamGameArt extends StatelessWidget {
  const SteamGameArt(this.config, {super.key});

  final RsGameArt config;

  @override
  Widget build(BuildContext context) {
    final t = context.rsTokens;
    final generated = SteamGeneratedArt(
      title: config.title,
      systemId: config.systemId,
      systemName: config.systemName,
      layout: config.layout,
    );
    final image = config.image;
    if (image == null) return generated;
    return Stack(
      fit: StackFit.expand,
      children: [
        generated,
        Image(
          image: image,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          frameBuilder: (_, child, frame, sync) => sync
              ? child
              : AnimatedOpacity(
                  opacity: frame == null ? 0 : 1,
                  duration: t.motion.page,
                  curve: t.motion.curve,
                  child: child,
                ),
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

/// Palette derived deterministically from a system and a title.
@immutable
class SteamArtPalette {
  factory SteamArtPalette.of(RsArtStyle art, String? systemId, String title) {
    final systemHash = steamHash(systemId ?? title);
    final titleHash = steamHash(title);
    // The system picks the color family; the title nudges it so games in one
    // system don't all look identical.
    final jitter = ((titleHash & 0xFF) / 255 - 0.5) * art.hueSpread * 0.6;
    final hue = ((systemHash % 360) + jitter) % 360;
    final hue2 = (hue + art.hueSpread) % 360;
    return SteamArtPalette._(
      start: HSLColor.fromAHSL(1, hue, art.saturation, art.lightness).toColor(),
      end: HSLColor.fromAHSL(
        1,
        hue2,
        art.saturation * 0.85,
        art.lightnessEnd,
      ).toColor(),
      glow: HSLColor.fromAHSL(
        1,
        hue,
        math.min(1, art.saturation * 1.2),
        math.min(1, art.lightness + 0.22),
      ).toColor(),
      pattern: (titleHash >> 8) % 3,
      mirrored: (titleHash >> 12).isOdd,
    );
  }

  const SteamArtPalette._({
    required this.start,
    required this.end,
    required this.glow,
    required this.pattern,
    required this.mirrored,
  });

  final Color start, end, glow;

  /// 0 stripes, 1 rings, 2 dots.
  final int pattern;
  final bool mirrored;
}

/// Generated capsule / hero art: gradient, light glow, a subtle pattern, a
/// giant faded monogram, and the title and system name.
class SteamGeneratedArt extends StatelessWidget {
  const SteamGeneratedArt({
    super.key,
    required this.title,
    required this.layout,
    this.systemId,
    this.systemName,
  });

  final String title;
  final String? systemId;
  final String? systemName;
  final RsArtLayout layout;

  @override
  Widget build(BuildContext context) {
    final t = context.rsTokens;
    final palette = SteamArtPalette.of(t.art, systemId, title);
    return LayoutBuilder(
      builder: (context, box) {
        final size = box.biggest;
        final w = size.width.isFinite ? size.width : t.sizes.capsuleWidth;
        final h = size.height.isFinite ? size.height : w * 1.5;
        return ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: palette.mirrored
                        ? Alignment.topRight
                        : Alignment.topLeft,
                    end: palette.mirrored
                        ? Alignment.bottomLeft
                        : Alignment.bottomRight,
                    colors: [palette.start, palette.end],
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: palette.mirrored
                        ? const Alignment(-0.7, -0.8)
                        : const Alignment(0.7, -0.8),
                    radius: 1.1,
                    colors: [
                      palette.glow.withValues(alpha: 0.55),
                      palette.glow.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
              CustomPaint(
                painter: _PatternPainter(
                  pattern: palette.pattern,
                  color: t.art.onArt.withValues(alpha: 0.06),
                  unit: math.min(w, h) / 9,
                ),
              ),
              if (layout != RsArtLayout.background)
                _Monogram(title: title, height: h, tokens: t),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.35, 1],
                    colors: [
                      t.art.shade.withValues(alpha: 0),
                      t.art.shade.withValues(
                        alpha: layout == RsArtLayout.background ? 0.3 : 0.6,
                      ),
                    ],
                  ),
                ),
              ),
              if (layout != RsArtLayout.background)
                _Caption(
                  title: title,
                  systemName: systemName ?? systemId,
                  layout: layout,
                  width: w,
                  height: h,
                  tokens: t,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Monogram extends StatelessWidget {
  const _Monogram({
    required this.title,
    required this.height,
    required this.tokens,
  });

  final String title;
  final double height;
  final RsTokens tokens;

  @override
  Widget build(BuildContext context) {
    final letter = title.trim().isEmpty
        ? '?'
        : title.trim().characters.first.toUpperCase();
    return Positioned(
      right: -height * 0.08,
      top: -height * 0.12,
      child: Text(
        letter,
        maxLines: 1,
        style: TextStyle(
          fontSize: height * 0.75,
          height: 1,
          fontWeight: FontWeight.w900,
          color: tokens.art.onArt.withValues(alpha: 0.08),
        ),
      ),
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption({
    required this.title,
    required this.systemName,
    required this.layout,
    required this.width,
    required this.height,
    required this.tokens,
  });

  final String title;
  final String? systemName;
  final RsArtLayout layout;
  final double width, height;
  final RsTokens tokens;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    final text = SteamStyle.text(context);
    final wide = layout == RsArtLayout.wide;
    final pad = math.max(t.spacing.sm, math.min(width, height) * 0.08);
    final titleSize = wide
        ? (height * 0.17).clamp(12.0, 44.0)
        : (width * 0.12).clamp(11.0, 36.0);
    final shadows = [
      Shadow(color: t.art.shade.withValues(alpha: 0.6), blurRadius: 8),
    ];
    final system = systemName;
    return Padding(
      padding: EdgeInsets.all(pad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (system != null)
            Row(
              children: [
                Container(
                  width: titleSize * 0.9,
                  height: math.max(2, titleSize * 0.12),
                  margin: EdgeInsets.only(right: t.spacing.xs + 2),
                  decoration: BoxDecoration(
                    color: t.art.onArt.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(t.radii.pill),
                  ),
                ),
                Expanded(
                  child: Text(
                    system.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.labelSmall?.copyWith(
                      color: t.art.onArt.withValues(alpha: 0.8),
                      fontSize: (titleSize * 0.42).clamp(8.0, 14.0),
                      shadows: shadows,
                    ),
                  ),
                ),
              ],
            ),
          const Spacer(),
          Text(
            title,
            maxLines: wide ? 2 : 4,
            overflow: TextOverflow.ellipsis,
            style: text.displaySmall?.copyWith(
              color: t.art.onArt,
              fontSize: titleSize,
              height: 1.08,
              fontWeight: FontWeight.w800,
              letterSpacing: -titleSize * 0.02,
              shadows: shadows,
            ),
          ),
        ],
      ),
    );
  }
}

class _PatternPainter extends CustomPainter {
  _PatternPainter({
    required this.pattern,
    required this.color,
    required this.unit,
  });

  final int pattern;
  final Color color;
  final double unit;

  @override
  void paint(Canvas canvas, Size size) {
    if (unit <= 0) return;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1, unit / 10);
    switch (pattern) {
      case 0:
        // Diagonal stripes.
        for (var x = -size.height; x < size.width; x += unit) {
          canvas.drawLine(
            Offset(x, size.height),
            Offset(x + size.height, 0),
            paint,
          );
        }
      case 1:
        // Concentric rings from the bottom-left corner.
        final center = Offset(0, size.height);
        final maxR = size.longestSide * 1.5;
        for (var r = unit; r < maxR; r += unit * 1.4) {
          canvas.drawCircle(center, r, paint);
        }
      default:
        // Dot grid.
        paint.style = PaintingStyle.fill;
        final radius = math.max(1.0, unit / 9);
        for (var y = unit / 2; y < size.height; y += unit) {
          for (var x = unit / 2; x < size.width; x += unit) {
            canvas.drawCircle(Offset(x, y), radius, paint);
          }
        }
    }
  }

  @override
  bool shouldRepaint(_PatternPainter old) =>
      old.pattern != pattern || old.color != color || old.unit != unit;
}
