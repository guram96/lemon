import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:rs_theme/rs_theme.dart';
import 'package:rs_ui/rs_ui.dart';

/// Controller glyph in the chosen [RsGlyphStyle].
class SteamGlyph extends StatelessWidget {
  const SteamGlyph(this.config, {super.key});

  final RsGlyph config;

  @override
  Widget build(BuildContext context) {
    final t = context.rsTokens;
    final size = config.size ?? t.sizes.glyph;
    final style = config.effectiveStyle(context);
    final g = t.glyphs;
    final b = config.button;

    if (style == RsGlyphStyle.keyboard) {
      final arrow = _arrowIcon(b);
      return _Keycap(
        label: _keyboardLabel(b),
        icon: arrow,
        size: size,
        tokens: t,
      );
    }

    switch (b) {
      case RsControllerButton.a:
      case RsControllerButton.b:
      case RsControllerButton.x:
      case RsControllerButton.y:
        final Widget face = switch (style) {
          RsGlyphStyle.playstation => CustomPaint(
            size: Size.square(size * 0.42),
            painter: _PsSymbolPainter(button: b, color: g.onFill),
          ),
          _ => Text(
            _faceLetter(b, style),
            style: TextStyle(
              color: style == RsGlyphStyle.xbox
                  ? switch (b) {
                      RsControllerButton.a => g.south,
                      RsControllerButton.b => g.east,
                      RsControllerButton.x => g.west,
                      _ => g.north,
                    }
                  : g.onFill,
              fontSize: size * 0.56,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        };
        return _Circle(size: size, tokens: t, child: face);
      case RsControllerButton.lb:
      case RsControllerButton.rb:
      case RsControllerButton.lt:
      case RsControllerButton.rt:
        return _Pill(
          label: _shoulderLabel(b, style),
          size: size,
          tokens: t,
          trigger: b == RsControllerButton.lt || b == RsControllerButton.rt,
        );
      case RsControllerButton.start:
      case RsControllerButton.select:
        return _Circle(
          size: size,
          tokens: t,
          child: Icon(
            b == RsControllerButton.start
                ? Icons.menu_rounded
                : Icons.filter_none_rounded,
            size: size * 0.55,
            color: g.onFill,
          ),
        );
      case RsControllerButton.dpad:
      case RsControllerButton.dpadUp:
      case RsControllerButton.dpadDown:
      case RsControllerButton.dpadLeft:
      case RsControllerButton.dpadRight:
        return _Circle(
          size: size,
          tokens: t,
          child: Icon(
            _arrowIcon(b) ?? Icons.gamepad_rounded,
            size: size * 0.7,
            color: g.onFill,
          ),
        );
      case RsControllerButton.leftStick:
      case RsControllerButton.rightStick:
        return _Circle(
          size: size,
          tokens: t,
          ring: true,
          child: Text(
            b == RsControllerButton.leftStick ? 'L' : 'R',
            style: TextStyle(
              color: g.onFill,
              fontSize: size * 0.46,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        );
    }
  }

  static IconData? _arrowIcon(RsControllerButton b) => switch (b) {
    RsControllerButton.dpadUp => Icons.keyboard_arrow_up_rounded,
    RsControllerButton.dpadDown => Icons.keyboard_arrow_down_rounded,
    RsControllerButton.dpadLeft => Icons.keyboard_arrow_left_rounded,
    RsControllerButton.dpadRight => Icons.keyboard_arrow_right_rounded,
    RsControllerButton.dpad => Icons.open_with_rounded,
    _ => null,
  };

  static String _faceLetter(RsControllerButton b, RsGlyphStyle style) {
    if (style == RsGlyphStyle.nintendo) {
      // Nintendo positions: south B, east A, west Y, north X.
      return switch (b) {
        RsControllerButton.a => 'B',
        RsControllerButton.b => 'A',
        RsControllerButton.x => 'Y',
        _ => 'X',
      };
    }
    return b.name.toUpperCase();
  }

  static String _shoulderLabel(RsControllerButton b, RsGlyphStyle style) =>
      switch ((style, b)) {
        (RsGlyphStyle.playstation, RsControllerButton.lb) => 'L1',
        (RsGlyphStyle.playstation, RsControllerButton.rb) => 'R1',
        (RsGlyphStyle.playstation, RsControllerButton.lt) => 'L2',
        (RsGlyphStyle.playstation, RsControllerButton.rt) => 'R2',
        (RsGlyphStyle.nintendo, RsControllerButton.lb) => 'L',
        (RsGlyphStyle.nintendo, RsControllerButton.rb) => 'R',
        (RsGlyphStyle.nintendo, RsControllerButton.lt) => 'ZL',
        (RsGlyphStyle.nintendo, RsControllerButton.rt) => 'ZR',
        _ => b.name.toUpperCase(),
      };

  /// Keys bound in `RsInputScope` (and Flutter's defaults for arrows).
  static String _keyboardLabel(RsControllerButton b) => switch (b) {
    RsControllerButton.a => 'Enter',
    RsControllerButton.b => 'Esc',
    RsControllerButton.x => 'X',
    RsControllerButton.y => 'Y',
    RsControllerButton.lb => 'PgUp',
    RsControllerButton.rb => 'PgDn',
    RsControllerButton.lt => 'Home',
    RsControllerButton.rt => 'End',
    RsControllerButton.start => 'Start',
    RsControllerButton.select => 'Menu',
    RsControllerButton.dpad => 'Arrows',
    RsControllerButton.dpadUp => 'Up',
    RsControllerButton.dpadDown => 'Down',
    RsControllerButton.dpadLeft => 'Left',
    RsControllerButton.dpadRight => 'Right',
    RsControllerButton.leftStick => 'L',
    RsControllerButton.rightStick => 'R',
  };
}

class _Circle extends StatelessWidget {
  const _Circle({
    required this.size,
    required this.tokens,
    required this.child,
    this.ring = false,
  });

  final double size;
  final RsTokens tokens;
  final Widget child;
  final bool ring;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: tokens.glyphs.fill,
      shape: BoxShape.circle,
      border: ring
          ? Border.all(color: tokens.glyphs.onFill, width: size / 14)
          : null,
    ),
    child: child,
  );
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.size,
    required this.tokens,
    required this.trigger,
  });

  final String label;
  final double size;
  final RsTokens tokens;
  final bool trigger;

  @override
  Widget build(BuildContext context) {
    final r = Radius.circular(size / 2);
    final small = Radius.circular(size / 5);
    return Container(
      height: size,
      constraints: BoxConstraints(minWidth: size * 1.5),
      padding: EdgeInsets.symmetric(horizontal: size / 4),
      decoration: BoxDecoration(
        color: tokens.glyphs.fill,
        // Bumpers are rounded on top, triggers at the bottom.
        borderRadius: trigger
            ? BorderRadius.only(
                topLeft: small,
                topRight: small,
                bottomLeft: r,
                bottomRight: r,
              )
            : BorderRadius.only(
                topLeft: r,
                topRight: r,
                bottomLeft: small,
                bottomRight: small,
              ),
      ),
      child: Center(
        widthFactor: 1,
        child: Text(
          label,
          style: TextStyle(
            color: tokens.glyphs.onFill,
            fontSize: size * 0.44,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _Keycap extends StatelessWidget {
  const _Keycap({
    required this.label,
    required this.size,
    required this.tokens,
    this.icon,
  });

  final String label;

  /// Drawn instead of [label] (arrow keys).
  final IconData? icon;
  final double size;
  final RsTokens tokens;

  @override
  Widget build(BuildContext context) => Container(
    height: size,
    constraints: BoxConstraints(minWidth: size),
    padding: EdgeInsets.symmetric(horizontal: size / 4),
    decoration: BoxDecoration(
      color: tokens.glyphs.fill,
      borderRadius: BorderRadius.circular(tokens.radii.sm + 1),
      border: Border(
        bottom: BorderSide(color: tokens.shadow, width: size / 10),
      ),
    ),
    child: Center(
      widthFactor: 1,
      child: icon != null
          ? Icon(
              icon,
              size: size * 0.7,
              color: tokens.glyphs.onFill,
              semanticLabel: label,
            )
          : Text(
              label,
              style: TextStyle(
                color: tokens.glyphs.onFill,
                fontSize: size * 0.44,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
    ),
  );
}

/// PlayStation ✕ ○ □ △, drawn so they don't depend on font coverage.
class _PsSymbolPainter extends CustomPainter {
  _PsSymbolPainter({required this.button, required this.color});

  final RsControllerButton button;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width / 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final r = Offset.zero & size;
    switch (button) {
      case RsControllerButton.a:
        canvas
          ..drawLine(r.topLeft, r.bottomRight, p)
          ..drawLine(r.topRight, r.bottomLeft, p);
      case RsControllerButton.b:
        canvas.drawCircle(r.center, size.width / 2, p);
      case RsControllerButton.x:
        canvas.drawRect(r.deflate(size.width * 0.04), p);
      default:
        final h = size.height * math.sqrt(3) / 2;
        final top = (size.height - h) / 2;
        canvas.drawPath(
          Path()
            ..moveTo(size.width / 2, top)
            ..lineTo(size.width, top + h)
            ..lineTo(0, top + h)
            ..close(),
          p,
        );
    }
  }

  @override
  bool shouldRepaint(_PsSymbolPainter old) =>
      old.button != button || old.color != color;
}
