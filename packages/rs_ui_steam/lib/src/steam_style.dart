import 'package:flutter/material.dart';
import 'package:rs_theme/rs_theme.dart';
import 'package:rs_ui/rs_ui.dart';

/// Shared visual recipes of the Steam set, all derived from [RsTokens].
abstract final class SteamStyle {
  /// Soft bright glow around a focused capsule or control.
  static List<BoxShadow> focusGlow(RsTokens t, {double strength = 1}) => [
    BoxShadow(
      color: t.focusGlow.withValues(alpha: t.focusGlow.a * strength),
      blurRadius: t.sizes.focusGlowBlur,
      spreadRadius: t.sizes.focusRingWidth,
    ),
  ];

  /// Resting drop shadow.
  static List<BoxShadow> restShadow(RsTokens t) => [
    BoxShadow(
      color: t.shadow,
      blurRadius: t.spacing.md,
      offset: Offset(0, t.spacing.xs),
    ),
  ];

  /// Deep shadow under floating panels (dialogs, toasts).
  static List<BoxShadow> floatShadow(RsTokens t) => [
    BoxShadow(
      color: t.shadow,
      blurRadius: t.spacing.xxl,
      offset: Offset(0, t.spacing.md),
    ),
  ];

  /// Big Picture page backdrop: vertical gradient with a faint cool glow.
  static BoxDecoration pageBackground(RsTokens t) => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [t.background, t.backgroundGradientEnd],
    ),
  );

  /// Raised panel gradient (dialogs, toasts, wizard cards).
  static Gradient panelGradient(RsTokens t) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [t.surfaceRaised, t.surface],
  );

  /// Text theme of the current [Theme] (tuned in `RsThemeBuilder`).
  static TextTheme text(BuildContext context) => Theme.of(context).textTheme;

  /// Responsive width of a capsule in [layout]. Wide capsules for aspect
  /// ratios above 1.
  static double capsuleWidth(BuildContext context, double aspectRatio) {
    final t = context.rsTokens;
    final scale = t.breakpoints.scaleFor(context.rsLayout);
    final base = aspectRatio > 1
        ? t.sizes.wideCapsuleWidth
        : t.sizes.capsuleWidth;
    return base * scale;
  }

  /// Room around a capsule so its focus scale and glow are not clipped.
  static double focusBleed(RsTokens t, double extent) =>
      extent * (t.motion.focusScale - 1) / 2 + t.sizes.focusGlowBlur / 2;
}

/// Stable 32-bit FNV-1a hash, so generated art never changes between runs.
int steamHash(String input) {
  var hash = 0x811C9DC5;
  for (final unit in input.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash;
}

/// Uppercase initials, for avatars.
String steamInitials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  final letters = parts.take(2).map((p) => p.characters.first.toUpperCase());
  return letters.join();
}

/// Material plumbing for set widgets that may sit outside a `Scaffold`:
/// gives Material widgets (TextField) an ancestor and sets the default text
/// style, without drawing anything.
class SteamSurface extends StatelessWidget {
  const SteamSurface({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Material(
    type: MaterialType.transparency,
    child: DefaultTextStyle(
      style: SteamStyle.text(context).bodyMedium ?? const TextStyle(),
      child: child,
    ),
  );
}

/// Pointer-only interactive area (tap / click / hover) built on
/// [RsFocusable] that never takes d-pad focus: button hints, toasts, the
/// LB / RB glyphs of a tab strip, the password reveal toggle.
class SteamTapTarget extends StatefulWidget {
  const SteamTapTarget({
    super.key,
    required this.onTap,
    required this.builder,
    this.semanticLabel,
  });

  final VoidCallback? onTap;
  final Widget Function(BuildContext context, RsFocusState state) builder;
  final String? semanticLabel;

  @override
  State<SteamTapTarget> createState() => _SteamTapTargetState();
}

class _SteamTapTargetState extends State<SteamTapTarget> {
  final _node = FocusNode(
    debugLabel: 'SteamTapTarget',
    canRequestFocus: false,
    skipTraversal: true,
  );

  @override
  void dispose() {
    _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RsFocusable(
    focusNode: _node,
    onActivate: widget.onTap,
    semanticLabel: widget.semanticLabel,
    builder: widget.builder,
  );
}
