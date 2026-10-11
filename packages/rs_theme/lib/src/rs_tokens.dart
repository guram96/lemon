import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Semantic design tokens. Component sets and features read every color,
/// spacing, radius and motion value from here. Never hardcode them.
@immutable
class RsTokens extends ThemeExtension<RsTokens> {
  const RsTokens({
    required this.background,
    required this.backgroundGradientEnd,
    required this.surface,
    required this.surfaceRaised,
    required this.focusSurface,
    required this.onFocusSurface,
    required this.focusRing,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.accent,
    required this.play,
    required this.onPlay,
    required this.danger,
    required this.divider,
    this.spacing = const RsSpacing(),
    this.radii = const RsRadii(),
    this.motion = const RsMotion(),
  });

  /// Page background, and the bottom of the page gradient.
  final Color background;
  final Color backgroundGradientEnd;

  /// Resting panels, buttons and tiles.
  final Color surface;

  /// Menus, dialogs and anything drawn above [surface].
  final Color surfaceRaised;

  /// Fill of a focused control (Big Picture's bright highlight) and its content color.
  final Color focusSurface;
  final Color onFocusSurface;

  /// Glow / outline around focused tiles.
  final Color focusRing;

  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  /// Brand accent: links, progress, selected toggles.
  final Color accent;

  /// The green "Play" / "Install" call to action and its content color.
  final Color play;
  final Color onPlay;

  final Color danger;
  final Color divider;

  final RsSpacing spacing;
  final RsRadii radii;
  final RsMotion motion;

  static RsTokens of(BuildContext context) =>
      Theme.of(context).extension<RsTokens>() ??
      (throw FlutterError(
        'RsTokens missing from ThemeData. Build the theme with RsThemeBuilder.',
      ));

  @override
  RsTokens copyWith({
    Color? background,
    Color? backgroundGradientEnd,
    Color? surface,
    Color? surfaceRaised,
    Color? focusSurface,
    Color? onFocusSurface,
    Color? focusRing,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? accent,
    Color? play,
    Color? onPlay,
    Color? danger,
    Color? divider,
    RsSpacing? spacing,
    RsRadii? radii,
    RsMotion? motion,
  }) => RsTokens(
    background: background ?? this.background,
    backgroundGradientEnd: backgroundGradientEnd ?? this.backgroundGradientEnd,
    surface: surface ?? this.surface,
    surfaceRaised: surfaceRaised ?? this.surfaceRaised,
    focusSurface: focusSurface ?? this.focusSurface,
    onFocusSurface: onFocusSurface ?? this.onFocusSurface,
    focusRing: focusRing ?? this.focusRing,
    textPrimary: textPrimary ?? this.textPrimary,
    textSecondary: textSecondary ?? this.textSecondary,
    textMuted: textMuted ?? this.textMuted,
    accent: accent ?? this.accent,
    play: play ?? this.play,
    onPlay: onPlay ?? this.onPlay,
    danger: danger ?? this.danger,
    divider: divider ?? this.divider,
    spacing: spacing ?? this.spacing,
    radii: radii ?? this.radii,
    motion: motion ?? this.motion,
  );

  @override
  RsTokens lerp(RsTokens? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return RsTokens(
      background: c(background, other.background),
      backgroundGradientEnd: c(
        backgroundGradientEnd,
        other.backgroundGradientEnd,
      ),
      surface: c(surface, other.surface),
      surfaceRaised: c(surfaceRaised, other.surfaceRaised),
      focusSurface: c(focusSurface, other.focusSurface),
      onFocusSurface: c(onFocusSurface, other.onFocusSurface),
      focusRing: c(focusRing, other.focusRing),
      textPrimary: c(textPrimary, other.textPrimary),
      textSecondary: c(textSecondary, other.textSecondary),
      textMuted: c(textMuted, other.textMuted),
      accent: c(accent, other.accent),
      play: c(play, other.play),
      onPlay: c(onPlay, other.onPlay),
      danger: c(danger, other.danger),
      divider: c(divider, other.divider),
      spacing: RsSpacing.lerp(spacing, other.spacing, t),
      radii: RsRadii.lerp(radii, other.radii, t),
      motion: t < 0.5 ? motion : other.motion,
    );
  }
}

/// Spacing scale in logical pixels.
@immutable
class RsSpacing {
  const RsSpacing({
    this.xs = 4,
    this.sm = 8,
    this.md = 16,
    this.lg = 24,
    this.xl = 32,
    this.xxl = 48,
  });

  final double xs, sm, md, lg, xl, xxl;

  static RsSpacing lerp(RsSpacing a, RsSpacing b, double t) => RsSpacing(
    xs: lerpDouble(a.xs, b.xs, t)!,
    sm: lerpDouble(a.sm, b.sm, t)!,
    md: lerpDouble(a.md, b.md, t)!,
    lg: lerpDouble(a.lg, b.lg, t)!,
    xl: lerpDouble(a.xl, b.xl, t)!,
    xxl: lerpDouble(a.xxl, b.xxl, t)!,
  );
}

/// Corner radii in logical pixels.
@immutable
class RsRadii {
  const RsRadii({this.sm = 3, this.md = 6, this.lg = 12, this.pill = 999});

  final double sm, md, lg, pill;

  static RsRadii lerp(RsRadii a, RsRadii b, double t) => RsRadii(
    sm: lerpDouble(a.sm, b.sm, t)!,
    md: lerpDouble(a.md, b.md, t)!,
    lg: lerpDouble(a.lg, b.lg, t)!,
    pill: lerpDouble(a.pill, b.pill, t)!,
  );
}

/// Animation timings for focus and transitions.
@immutable
class RsMotion {
  const RsMotion({
    this.focus = const Duration(milliseconds: 140),
    this.page = const Duration(milliseconds: 250),
    this.curve = Curves.easeOutCubic,
    this.focusScale = 1.06,
  });

  final Duration focus;
  final Duration page;
  final Curve curve;

  /// How much a focused tile grows.
  final double focusScale;
}

extension RsTokensContext on BuildContext {
  RsTokens get rsTokens => RsTokens.of(this);
}
