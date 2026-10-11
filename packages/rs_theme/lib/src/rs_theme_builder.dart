import 'package:flutter/material.dart';

import 'rs_theme_settings.dart';
import 'rs_tokens.dart';

/// Builds [ThemeData] (with [RsTokens] attached) from [RsThemeSettings].
abstract final class RsThemeBuilder {
  static ThemeData light(RsThemeSettings settings) =>
      _build(Brightness.light, _lightTokens(settings.accent));

  static ThemeData dark(RsThemeSettings settings) =>
      _build(Brightness.dark, _darkTokens(settings.accent));

  /// Dark palette modelled on Steam Big Picture mode (2023+ / Steam Deck UI).
  static RsTokens _darkTokens(Color accent) => RsTokens(
    background: const Color(0xFF0E1218),
    backgroundGradientEnd: const Color(0xFF1A202A),
    surface: const Color(0xFF23262E),
    surfaceRaised: const Color(0xFF2E333D),
    focusSurface: const Color(0xFFDCDEDF),
    onFocusSurface: const Color(0xFF0E1218),
    focusRing: const Color(0xFFFFFFFF),
    focusGlow: const Color(0x66B8C9DA),
    textPrimary: const Color(0xFFFFFFFF),
    textSecondary: const Color(0xFFDCDEDF),
    textMuted: const Color(0xFF8B929A),
    accent: accent,
    onAccent: const Color(0xFFFFFFFF),
    play: const Color(0xFF5CB82D),
    onPlay: const Color(0xFFFFFFFF),
    danger: const Color(0xFFE5484D),
    success: const Color(0xFF5CB82D),
    warning: const Color(0xFFE5A50A),
    divider: const Color(0x1FFFFFFF),
    barBackground: const Color(0xE60B0F14),
    scrim: const Color(0xCC05070A),
    track: const Color(0x26FFFFFF),
    shadow: const Color(0x8C000000),
    glyphs: const RsGlyphColors(),
    art: const RsArtStyle(),
  );

  static RsTokens _lightTokens(Color accent) => RsTokens(
    background: const Color(0xFFF1F3F5),
    backgroundGradientEnd: const Color(0xFFDDE2E8),
    surface: const Color(0xFFFFFFFF),
    surfaceRaised: const Color(0xFFFFFFFF),
    focusSurface: const Color(0xFF1B2838),
    onFocusSurface: const Color(0xFFFFFFFF),
    focusRing: const Color(0xFF1B2838),
    focusGlow: const Color(0x4D1B2838),
    textPrimary: const Color(0xFF0E1218),
    textSecondary: const Color(0xFF2E333D),
    textMuted: const Color(0xFF5F6872),
    accent: accent,
    onAccent: const Color(0xFFFFFFFF),
    play: const Color(0xFF4AA021),
    onPlay: const Color(0xFFFFFFFF),
    danger: const Color(0xFFCD2B31),
    success: const Color(0xFF3D8B1D),
    warning: const Color(0xFFB97800),
    divider: const Color(0x1F000000),
    barBackground: const Color(0xEBFFFFFF),
    scrim: const Color(0x8C101820),
    track: const Color(0x1F000000),
    shadow: const Color(0x33101820),
    glyphs: const RsGlyphColors(
      fill: Color(0xFF2B3039),
      onFill: Color(0xFFFFFFFF),
      south: Color(0xFF7BDB4C),
      east: Color(0xFFFF6B67),
      west: Color(0xFF5AAEFF),
      north: Color(0xFFFFCF4A),
    ),
    art: const RsArtStyle(lightness: 0.44, lightnessEnd: 0.2),
  );

  /// System font (SF Pro, Segoe UI, Roboto, …) tuned towards Motiva Sans:
  /// heavy display weights with tight tracking, airy body text and wide-set
  /// uppercase labels.
  static TextTheme _textTheme(RsTokens t) {
    TextStyle s(
      double size,
      FontWeight weight,
      Color color, {
      double spacing = 0,
      double height = 1.25,
    }) => TextStyle(
      fontSize: size,
      fontWeight: weight,
      letterSpacing: spacing,
      height: height,
      color: color,
    );
    return TextTheme(
      displayLarge: s(56, FontWeight.w800, t.textPrimary, spacing: -1.2),
      displayMedium: s(44, FontWeight.w800, t.textPrimary, spacing: -0.8),
      displaySmall: s(34, FontWeight.w700, t.textPrimary, spacing: -0.4),
      headlineLarge: s(30, FontWeight.w700, t.textPrimary, spacing: -0.3),
      headlineMedium: s(26, FontWeight.w700, t.textPrimary, spacing: -0.2),
      headlineSmall: s(22, FontWeight.w700, t.textPrimary, spacing: -0.1),
      titleLarge: s(20, FontWeight.w700, t.textPrimary),
      titleMedium: s(16, FontWeight.w600, t.textPrimary, spacing: 0.1),
      titleSmall: s(14, FontWeight.w600, t.textPrimary, spacing: 0.1),
      bodyLarge: s(16, FontWeight.w400, t.textSecondary, height: 1.45),
      bodyMedium: s(14, FontWeight.w400, t.textSecondary, height: 1.4),
      bodySmall: s(12.5, FontWeight.w400, t.textMuted, height: 1.35),
      labelLarge: s(15, FontWeight.w700, t.textPrimary, spacing: 0.3),
      labelMedium: s(12, FontWeight.w700, t.textSecondary, spacing: 0.9),
      labelSmall: s(11, FontWeight.w700, t.textMuted, spacing: 1.2),
    );
  }

  static ThemeData _build(Brightness brightness, RsTokens t) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: t.accent,
          brightness: brightness,
        ).copyWith(
          primary: t.accent,
          onPrimary: t.onAccent,
          surface: t.surface,
          onSurface: t.textPrimary,
          error: t.danger,
        );
    return ThemeData(
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: t.background,
      textTheme: _textTheme(t),
      iconTheme: IconThemeData(color: t.textSecondary, size: t.sizes.icon),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: t.accent,
        selectionColor: t.accent.withValues(alpha: 0.35),
        selectionHandleColor: t.accent,
      ),
      // Component sets draw their own focus; disable Material's defaults.
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      focusColor: Colors.transparent,
      hoverColor: Colors.transparent,
      extensions: [t],
    );
  }
}
