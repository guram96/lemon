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
    this.onAccent = const Color(0xFFFFFFFF),
    this.focusGlow = const Color(0x59C7D5E0),
    this.barBackground = const Color(0xE60B0F14),
    this.scrim = const Color(0xCC05070A),
    this.track = const Color(0x26FFFFFF),
    this.shadow = const Color(0x8C000000),
    this.success = const Color(0xFF5CB82D),
    this.warning = const Color(0xFFE5A50A),
    this.glyphs = const RsGlyphColors(),
    this.art = const RsArtStyle(),
    this.spacing = const RsSpacing(),
    this.radii = const RsRadii(),
    this.motion = const RsMotion(),
    this.sizes = const RsSizes(),
    this.breakpoints = const RsBreakpoints(),
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

  /// Outline around focused tiles.
  final Color focusRing;

  /// Soft glow drawn around focused capsules and buttons.
  final Color focusGlow;

  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  /// Brand accent: links, progress, selected toggles, badges.
  final Color accent;

  /// Content drawn on [accent], for example a notification count.
  final Color onAccent;

  /// The green "Play" / "Install" call to action and its content color.
  final Color play;
  final Color onPlay;

  final Color danger;
  final Color success;
  final Color warning;
  final Color divider;

  /// Translucent fill of the top bar and the button-hint bar.
  final Color barBackground;

  /// Backdrop behind dialogs.
  final Color scrim;

  /// Unfilled part of progress bars, step indicators and switches.
  final Color track;

  /// Drop shadows under capsules, dialogs and toasts.
  final Color shadow;

  /// Controller glyph colors for button hints.
  final RsGlyphColors glyphs;

  /// Parameters for generated fallback artwork.
  final RsArtStyle art;

  final RsSpacing spacing;
  final RsRadii radii;
  final RsMotion motion;
  final RsSizes sizes;
  final RsBreakpoints breakpoints;

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
    Color? focusGlow,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? accent,
    Color? onAccent,
    Color? play,
    Color? onPlay,
    Color? danger,
    Color? success,
    Color? warning,
    Color? divider,
    Color? barBackground,
    Color? scrim,
    Color? track,
    Color? shadow,
    RsGlyphColors? glyphs,
    RsArtStyle? art,
    RsSpacing? spacing,
    RsRadii? radii,
    RsMotion? motion,
    RsSizes? sizes,
    RsBreakpoints? breakpoints,
  }) => RsTokens(
    background: background ?? this.background,
    backgroundGradientEnd: backgroundGradientEnd ?? this.backgroundGradientEnd,
    surface: surface ?? this.surface,
    surfaceRaised: surfaceRaised ?? this.surfaceRaised,
    focusSurface: focusSurface ?? this.focusSurface,
    onFocusSurface: onFocusSurface ?? this.onFocusSurface,
    focusRing: focusRing ?? this.focusRing,
    focusGlow: focusGlow ?? this.focusGlow,
    textPrimary: textPrimary ?? this.textPrimary,
    textSecondary: textSecondary ?? this.textSecondary,
    textMuted: textMuted ?? this.textMuted,
    accent: accent ?? this.accent,
    onAccent: onAccent ?? this.onAccent,
    play: play ?? this.play,
    onPlay: onPlay ?? this.onPlay,
    danger: danger ?? this.danger,
    success: success ?? this.success,
    warning: warning ?? this.warning,
    divider: divider ?? this.divider,
    barBackground: barBackground ?? this.barBackground,
    scrim: scrim ?? this.scrim,
    track: track ?? this.track,
    shadow: shadow ?? this.shadow,
    glyphs: glyphs ?? this.glyphs,
    art: art ?? this.art,
    spacing: spacing ?? this.spacing,
    radii: radii ?? this.radii,
    motion: motion ?? this.motion,
    sizes: sizes ?? this.sizes,
    breakpoints: breakpoints ?? this.breakpoints,
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
      focusGlow: c(focusGlow, other.focusGlow),
      textPrimary: c(textPrimary, other.textPrimary),
      textSecondary: c(textSecondary, other.textSecondary),
      textMuted: c(textMuted, other.textMuted),
      accent: c(accent, other.accent),
      onAccent: c(onAccent, other.onAccent),
      play: c(play, other.play),
      onPlay: c(onPlay, other.onPlay),
      danger: c(danger, other.danger),
      success: c(success, other.success),
      warning: c(warning, other.warning),
      divider: c(divider, other.divider),
      barBackground: c(barBackground, other.barBackground),
      scrim: c(scrim, other.scrim),
      track: c(track, other.track),
      shadow: c(shadow, other.shadow),
      glyphs: RsGlyphColors.lerp(glyphs, other.glyphs, t),
      art: RsArtStyle.lerp(art, other.art, t),
      spacing: RsSpacing.lerp(spacing, other.spacing, t),
      radii: RsRadii.lerp(radii, other.radii, t),
      motion: t < 0.5 ? motion : other.motion,
      sizes: RsSizes.lerp(sizes, other.sizes, t),
      breakpoints: t < 0.5 ? breakpoints : other.breakpoints,
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
    this.fast = const Duration(milliseconds: 90),
    this.focus = const Duration(milliseconds: 140),
    this.page = const Duration(milliseconds: 250),
    this.slow = const Duration(milliseconds: 420),
    this.spin = const Duration(milliseconds: 1100),
    this.toastHold = const Duration(seconds: 5),
    this.curve = Curves.easeOutCubic,
    this.emphasizedCurve = Curves.easeOutQuart,
    this.exitCurve = Curves.easeInCubic,
    this.focusScale = 1.06,
    this.pressScale = 0.97,
  });

  /// Press feedback and tiny state changes.
  final Duration fast;

  /// Focus highlight, scale and glow.
  final Duration focus;

  /// Page, dialog and toast transitions.
  final Duration page;

  /// Background cross-fades and hero art.
  final Duration slow;

  /// One revolution of a spinner / one sweep of an indeterminate bar.
  final Duration spin;

  /// How long a transient toast stays on screen.
  final Duration toastHold;

  final Curve curve;

  /// Entrances that should feel springy (toasts, dialogs).
  final Curve emphasizedCurve;

  /// Exits.
  final Curve exitCurve;

  /// How much a focused tile grows.
  final double focusScale;

  /// How much a pressed control shrinks.
  final double pressScale;
}

/// Fixed component dimensions in logical pixels.
@immutable
class RsSizes {
  const RsSizes({
    this.topBar = 64,
    this.hintBar = 52,
    this.glyph = 24,
    this.iconSm = 16,
    this.icon = 20,
    this.iconLg = 28,
    this.avatar = 36,
    this.focusRingWidth = 2,
    this.focusGlowBlur = 28,
    this.capsuleWidth = 184,
    this.wideCapsuleWidth = 360,
    this.progressHeight = 6,
    this.spinner = 32,
    this.rowMinHeight = 64,
    this.tabHeight = 44,
    this.dialogMaxWidth = 560,
    this.toastWidth = 380,
    this.wizardMaxWidth = 820,
    this.heroHeight = 420,
  });

  final double topBar;
  final double hintBar;

  /// Controller glyph diameter in button hints.
  final double glyph;
  final double iconSm, icon, iconLg;
  final double avatar;
  final double focusRingWidth;
  final double focusGlowBlur;

  /// Width of a 2:3 cover capsule at the "expanded" layout class.
  final double capsuleWidth;

  /// Width of a wide (header) capsule at the "expanded" layout class.
  final double wideCapsuleWidth;
  final double progressHeight;
  final double spinner;
  final double rowMinHeight;
  final double tabHeight;
  final double dialogMaxWidth;
  final double toastWidth;
  final double wizardMaxWidth;
  final double heroHeight;

  static RsSizes lerp(RsSizes a, RsSizes b, double t) {
    double l(double x, double y) => lerpDouble(x, y, t)!;
    return RsSizes(
      topBar: l(a.topBar, b.topBar),
      hintBar: l(a.hintBar, b.hintBar),
      glyph: l(a.glyph, b.glyph),
      iconSm: l(a.iconSm, b.iconSm),
      icon: l(a.icon, b.icon),
      iconLg: l(a.iconLg, b.iconLg),
      avatar: l(a.avatar, b.avatar),
      focusRingWidth: l(a.focusRingWidth, b.focusRingWidth),
      focusGlowBlur: l(a.focusGlowBlur, b.focusGlowBlur),
      capsuleWidth: l(a.capsuleWidth, b.capsuleWidth),
      wideCapsuleWidth: l(a.wideCapsuleWidth, b.wideCapsuleWidth),
      progressHeight: l(a.progressHeight, b.progressHeight),
      spinner: l(a.spinner, b.spinner),
      rowMinHeight: l(a.rowMinHeight, b.rowMinHeight),
      tabHeight: l(a.tabHeight, b.tabHeight),
      dialogMaxWidth: l(a.dialogMaxWidth, b.dialogMaxWidth),
      toastWidth: l(a.toastWidth, b.toastWidth),
      wizardMaxWidth: l(a.wizardMaxWidth, b.wizardMaxWidth),
      heroHeight: l(a.heroHeight, b.heroHeight),
    );
  }
}

/// Width classes, from a phone in portrait to a 4K TV.
enum RsLayoutClass { compact, medium, expanded, large }

/// Layout breakpoints (logical pixels of available width) and how much
/// artwork and gutters grow in each class.
@immutable
class RsBreakpoints {
  const RsBreakpoints({
    this.medium = 600,
    this.expanded = 1024,
    this.large = 1800,
    this.compactScale = 0.7,
    this.mediumScale = 0.85,
    this.largeScale = 1.3,
  });

  /// Minimum width of each class; anything narrower is [RsLayoutClass.compact].
  final double medium, expanded, large;

  /// Artwork scale per class ([RsLayoutClass.expanded] is 1).
  final double compactScale, mediumScale, largeScale;

  RsLayoutClass classify(double width) {
    if (width >= large) return RsLayoutClass.large;
    if (width >= expanded) return RsLayoutClass.expanded;
    if (width >= medium) return RsLayoutClass.medium;
    return RsLayoutClass.compact;
  }

  double scaleFor(RsLayoutClass layout) => switch (layout) {
    RsLayoutClass.compact => compactScale,
    RsLayoutClass.medium => mediumScale,
    RsLayoutClass.expanded => 1,
    RsLayoutClass.large => largeScale,
  };
}

/// Controller glyph colors. Positions follow the Xbox layout: south (A),
/// east (B), west (X), north (Y).
@immutable
class RsGlyphColors {
  const RsGlyphColors({
    this.fill = const Color(0xFF2B3039),
    this.onFill = const Color(0xFFE6E8EA),
    this.south = const Color(0xFF6BCB3C),
    this.east = const Color(0xFFF0524F),
    this.west = const Color(0xFF3D9BFF),
    this.north = const Color(0xFFF5C02C),
  });

  /// Glyph background and its neutral foreground.
  final Color fill, onFill;
  final Color south, east, west, north;

  static RsGlyphColors lerp(RsGlyphColors a, RsGlyphColors b, double t) {
    Color c(Color x, Color y) => Color.lerp(x, y, t)!;
    return RsGlyphColors(
      fill: c(a.fill, b.fill),
      onFill: c(a.onFill, b.onFill),
      south: c(a.south, b.south),
      east: c(a.east, b.east),
      west: c(a.west, b.west),
      north: c(a.north, b.north),
    );
  }
}

/// Parameters for generated artwork (games without scraped art). The hue
/// comes from the game; saturation and lightness come from here.
@immutable
class RsArtStyle {
  const RsArtStyle({
    this.saturation = 0.5,
    this.lightness = 0.36,
    this.lightnessEnd = 0.13,
    this.hueSpread = 46,
    this.onArt = const Color(0xFFFFFFFF),
    this.shade = const Color(0xFF000000),
  });

  final double saturation;

  /// Lightness of the bright and dark ends of the gradient.
  final double lightness, lightnessEnd;

  /// Degrees between the two gradient hues.
  final double hueSpread;

  /// Text drawn on generated art, and the shade used for legibility.
  final Color onArt, shade;

  static RsArtStyle lerp(RsArtStyle a, RsArtStyle b, double t) => RsArtStyle(
    saturation: lerpDouble(a.saturation, b.saturation, t)!,
    lightness: lerpDouble(a.lightness, b.lightness, t)!,
    lightnessEnd: lerpDouble(a.lightnessEnd, b.lightnessEnd, t)!,
    hueSpread: lerpDouble(a.hueSpread, b.hueSpread, t)!,
    onArt: Color.lerp(a.onArt, b.onArt, t)!,
    shade: Color.lerp(a.shade, b.shade, t)!,
  );
}

extension RsTokensContext on BuildContext {
  RsTokens get rsTokens => RsTokens.of(this);

  /// Layout class for the current screen width.
  RsLayoutClass get rsLayout =>
      rsTokens.breakpoints.classify(MediaQuery.sizeOf(this).width);

  /// Horizontal page gutter for the current layout class. Shelves, grids and
  /// page content use it so their left edges line up.
  double get rsPageGutter {
    final s = rsTokens.spacing;
    return switch (rsLayout) {
      RsLayoutClass.compact => s.md,
      RsLayoutClass.medium => s.lg,
      RsLayoutClass.expanded => s.xxl,
      RsLayoutClass.large => s.xxl + s.lg,
    };
  }
}
