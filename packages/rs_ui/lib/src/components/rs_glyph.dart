import 'package:flutter/widgets.dart';

import '../component_set.dart';

/// Controller buttons, named by their position on an Xbox-style pad.
/// [a] is always the confirm (south) button and [b] back (east).
enum RsControllerButton {
  a,
  b,
  x,
  y,
  lb,
  rb,
  lt,
  rt,

  /// Start / Menu (≡).
  start,

  /// Select / View (⧉).
  select,
  dpad,
  dpadUp,
  dpadDown,
  dpadLeft,
  dpadRight,
  leftStick,
  rightStick,
}

/// How controller glyphs are drawn.
enum RsGlyphStyle {
  /// Xbox / Steam default: lettered face buttons, LB / RB bumpers.
  xbox,

  /// PlayStation: ✕ ○ □ △, L1 / R1.
  playstation,

  /// Nintendo: letters in Nintendo positions (south is B).
  nintendo,

  /// Keyboard keycaps (Enter, Esc, PgUp, …) matching `RsInputScope`.
  keyboard,
}

/// Sets the default [RsGlyphStyle] for every glyph below it, for example
/// from the last input device used.
class RsGlyphStyleScope extends InheritedWidget {
  const RsGlyphStyleScope({
    super.key,
    required this.style,
    required super.child,
  });

  final RsGlyphStyle style;

  /// The nearest style, or [RsGlyphStyle.xbox].
  static RsGlyphStyle of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RsGlyphStyleScope>()?.style ??
      RsGlyphStyle.xbox;

  @override
  bool updateShouldNotify(RsGlyphStyleScope oldWidget) =>
      style != oldWidget.style;
}

/// A single controller-button glyph (Ⓐ, LB, ≡, …).
class RsGlyph extends StatelessWidget {
  const RsGlyph({super.key, required this.button, this.style, this.size});

  final RsControllerButton button;

  /// Defaults to the nearest [RsGlyphStyleScope].
  final RsGlyphStyle? style;

  /// Height in logical pixels; defaults to the set's hint glyph size.
  final double? size;

  RsGlyphStyle effectiveStyle(BuildContext context) =>
      style ?? RsGlyphStyleScope.of(context);

  @override
  Widget build(BuildContext context) =>
      RsComponents.of(context).glyph(context, this);
}
