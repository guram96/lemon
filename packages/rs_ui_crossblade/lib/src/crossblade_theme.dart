import 'package:flutter/material.dart';
import 'package:rs_theme/rs_theme.dart';

/// Crossblade palette: a midnight PS3 XMB sky, Xbox "jewel" green for focus
/// and selection, and glassy blue-black panels.
abstract final class CrossbladeTheme {
  /// Xbox jewel green. Used as the accent unless the user picked their own.
  static const green = Color(0xFF8BE11E);

  /// PS2 / PS3 sapphire, the second brand color of the look (waves, rings).
  static const sapphire = Color(0xFF2F6BFF);

  static ThemeData dark(RsThemeSettings settings) {
    final t = _dark(_accent(settings));
    return RsThemeBuilder.fromTokens(Brightness.dark, t, textTheme: _text(t));
  }

  static ThemeData light(RsThemeSettings settings) {
    final t = _light(_accent(settings));
    return RsThemeBuilder.fromTokens(Brightness.light, t, textTheme: _text(t));
  }

  /// Steam blue is the shared default accent; Crossblade swaps it for green.
  static Color _accent(RsThemeSettings s) =>
      s.accent == RsThemeSettings.defaultAccent ? green : s.accent;

  static const _radii = RsRadii(sm: 6, md: 12, lg: 22);
  static const _motion = RsMotion(
    focus: Duration(milliseconds: 180),
    focusScale: 1.08,
    pressScale: 0.95,
  );
  static const _sizes = RsSizes(
    topBar: 76,
    hintBar: 56,
    focusRingWidth: 2.5,
    focusGlowBlur: 34,
    rowMinHeight: 66,
    tabHeight: 46,
  );

  static RsTokens _dark(Color accent) => RsTokens(
    background: const Color(0xFF03050C),
    backgroundGradientEnd: const Color(0xFF0B1A3D),
    surface: const Color(0xB3122039),
    surfaceRaised: const Color(0xF0172A4D),
    focusSurface: accent,
    onFocusSurface: const Color(0xFF071204),
    focusRing: Color.lerp(accent, const Color(0xFFFFFFFF), 0.45)!,
    focusGlow: accent.withValues(alpha: 0.62),
    textPrimary: const Color(0xFFFFFFFF),
    textSecondary: const Color(0xFFCAD6F2),
    textMuted: const Color(0xFF7A8BB4),
    accent: accent,
    onAccent: const Color(0xFF071204),
    play: const Color(0xFF4CC417),
    onPlay: const Color(0xFFFFFFFF),
    danger: const Color(0xFFFF3B4E),
    success: const Color(0xFF6BE01F),
    warning: const Color(0xFFFFB81F),
    divider: const Color(0x2493B4FF),
    barBackground: const Color(0xCC050B1C),
    scrim: const Color(0xD9020510),
    track: const Color(0x2E93B4FF),
    shadow: const Color(0xB3000000),
    glyphs: const RsGlyphColors(
      fill: Color(0xFF1B2A4A),
      onFill: Color(0xFFFFFFFF),
      south: Color(0xFF6BE01F),
      east: Color(0xFFFF3B4E),
      west: Color(0xFF2F8BFF),
      north: Color(0xFFFFC21F),
    ),
    art: const RsArtStyle(
      saturation: 0.72,
      lightness: 0.4,
      lightnessEnd: 0.1,
      hueSpread: 70,
    ),
    radii: _radii,
    motion: _motion,
    sizes: _sizes,
  );

  static RsTokens _light(Color accent) {
    final ink = Color.lerp(accent, const Color(0xFF000000), 0.35)!;
    return RsTokens(
      background: const Color(0xFFEAF0FA),
      backgroundGradientEnd: const Color(0xFFB9CCEB),
      surface: const Color(0xCCFFFFFF),
      surfaceRaised: const Color(0xF7FFFFFF),
      focusSurface: accent,
      onFocusSurface: const Color(0xFF071204),
      focusRing: ink,
      focusGlow: accent.withValues(alpha: 0.55),
      textPrimary: const Color(0xFF07112A),
      textSecondary: const Color(0xFF26355A),
      textMuted: const Color(0xFF5B6A8E),
      accent: ink,
      onAccent: const Color(0xFFFFFFFF),
      play: const Color(0xFF3DA811),
      onPlay: const Color(0xFFFFFFFF),
      danger: const Color(0xFFD9203A),
      success: const Color(0xFF3B9A0F),
      warning: const Color(0xFFC07F00),
      divider: const Color(0x2907112A),
      barBackground: const Color(0xD9F4F8FF),
      scrim: const Color(0x99101C38),
      track: const Color(0x2607112A),
      shadow: const Color(0x40102040),
      glyphs: const RsGlyphColors(
        fill: Color(0xFF26355A),
        onFill: Color(0xFFFFFFFF),
        south: Color(0xFF5CC81A),
        east: Color(0xFFFF4A5C),
        west: Color(0xFF3D8BFF),
        north: Color(0xFFFFC21F),
      ),
      art: const RsArtStyle(
        saturation: 0.66,
        lightness: 0.46,
        lightnessEnd: 0.22,
        hueSpread: 70,
      ),
      radii: _radii,
      motion: _motion,
      sizes: _sizes,
    );
  }

  /// Heavy italic display type with a sporty early-2000s dashboard feel,
  /// wide-tracked labels.
  static TextTheme _text(RsTokens t) {
    final base = RsThemeBuilder.textThemeFor(t);
    TextStyle? display(TextStyle? s) => s?.copyWith(
      fontWeight: FontWeight.w900,
      fontStyle: FontStyle.italic,
      letterSpacing: -0.6,
    );
    TextStyle? wide(TextStyle? s, double spacing) =>
        s?.copyWith(fontWeight: FontWeight.w800, letterSpacing: spacing);
    return base.copyWith(
      displayLarge: display(base.displayLarge),
      displayMedium: display(base.displayMedium),
      displaySmall: display(base.displaySmall),
      headlineLarge: display(base.headlineLarge),
      headlineMedium: display(base.headlineMedium),
      headlineSmall: display(base.headlineSmall),
      titleLarge: base.titleLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: 0.2,
      ),
      labelLarge: wide(base.labelLarge, 1.1),
      labelMedium: wide(base.labelMedium, 1.6),
      labelSmall: wide(base.labelSmall, 1.8),
    );
  }
}
