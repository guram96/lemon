import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rs_theme/rs_theme.dart';

void main() {
  test('settings round-trip through JSON', () {
    const settings = RsThemeSettings(
      mode: ThemeMode.light,
      accent: Color(0xFF00FF00),
    );
    expect(RsThemeSettings.fromJson(settings.toJson()), settings);
  });

  test('unknown JSON falls back to defaults', () {
    expect(
      RsThemeSettings.fromJson(const {'mode': 'bogus'}),
      const RsThemeSettings(),
    );
  });

  test('built themes carry tokens and the chosen accent', () {
    const settings = RsThemeSettings(accent: Color(0xFFFF8800));
    for (final theme in [
      RsThemeBuilder.dark(settings),
      RsThemeBuilder.light(settings),
    ]) {
      final tokens = theme.extension<RsTokens>();
      expect(tokens, isNotNull);
      expect(tokens!.accent, settings.accent);
      expect(theme.colorScheme.primary, settings.accent);
    }
    expect(RsThemeBuilder.dark(settings).brightness, Brightness.dark);
  });

  test('tokens lerp between themes', () {
    final dark = RsThemeBuilder.dark(const RsThemeSettings())
        .extension<RsTokens>()!;
    final light = RsThemeBuilder.light(const RsThemeSettings())
        .extension<RsTokens>()!;
    expect(dark.lerp(light, 0).background, dark.background);
    expect(dark.lerp(light, 1).background, light.background);
  });
}
