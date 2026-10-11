import 'package:flutter/material.dart';

import 'rs_theme_settings.dart';
import 'rs_tokens.dart';

/// Builds [ThemeData] (with [RsTokens] attached) from [RsThemeSettings].
abstract final class RsThemeBuilder {
  static ThemeData light(RsThemeSettings settings) =>
      _build(Brightness.light, _lightTokens(settings.accent));

  static ThemeData dark(RsThemeSettings settings) =>
      _build(Brightness.dark, _darkTokens(settings.accent));

  /// Dark palette modelled on Steam Big Picture mode.
  static RsTokens _darkTokens(Color accent) => RsTokens(
    background: const Color(0xFF0E1218),
    backgroundGradientEnd: const Color(0xFF171D25),
    surface: const Color(0xFF23262E),
    surfaceRaised: const Color(0xFF2E333D),
    focusSurface: const Color(0xFFDCDEDF),
    onFocusSurface: const Color(0xFF0E1218),
    focusRing: const Color(0xFFFFFFFF),
    textPrimary: const Color(0xFFFFFFFF),
    textSecondary: const Color(0xFFDCDEDF),
    textMuted: const Color(0xFF8B929A),
    accent: accent,
    play: const Color(0xFF5CB82D),
    onPlay: const Color(0xFFFFFFFF),
    danger: const Color(0xFFE5484D),
    divider: const Color(0x1FFFFFFF),
  );

  static RsTokens _lightTokens(Color accent) => RsTokens(
    background: const Color(0xFFF1F3F5),
    backgroundGradientEnd: const Color(0xFFE2E6EA),
    surface: const Color(0xFFFFFFFF),
    surfaceRaised: const Color(0xFFFFFFFF),
    focusSurface: const Color(0xFF1B2838),
    onFocusSurface: const Color(0xFFFFFFFF),
    focusRing: const Color(0xFF1B2838),
    textPrimary: const Color(0xFF0E1218),
    textSecondary: const Color(0xFF2E333D),
    textMuted: const Color(0xFF5F6872),
    accent: accent,
    play: const Color(0xFF4AA021),
    onPlay: const Color(0xFFFFFFFF),
    danger: const Color(0xFFCD2B31),
    divider: const Color(0x1F000000),
  );

  static ThemeData _build(Brightness brightness, RsTokens t) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: t.accent,
          brightness: brightness,
        ).copyWith(
          primary: t.accent,
          surface: t.surface,
          onSurface: t.textPrimary,
          error: t.danger,
        );
    final base = ThemeData(
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: t.background,
      // Component sets draw their own focus; disable Material's defaults.
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      focusColor: Colors.transparent,
      hoverColor: Colors.transparent,
      extensions: [t],
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: t.textSecondary,
        displayColor: t.textPrimary,
      ),
    );
  }
}
