import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rs_client/src/settings/client_settings.dart';
import 'package:rs_theme/rs_theme.dart';

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('rs_client_settings_');
  });

  tearDown(() async {
    if (root.existsSync()) await root.delete(recursive: true);
  });

  test('round-trips theme and ui sounds', () async {
    const saved = ClientSettings(
      theme: RsThemeSettings(mode: ThemeMode.light, accent: Color(0xFF00FF00)),
      uiSounds: false,
    );
    await openClientSettingsStore(root).save(saved);
    final loaded = await openClientSettingsStore(root).load();
    expect(loaded.theme.mode, ThemeMode.light);
    expect(loaded.theme.accent, const Color(0xFF00FF00));
    expect(loaded.uiSounds, isFalse);
  });

  test('malformed client_settings.json falls back to defaults', () async {
    final file = File(
      '${root.path}${Platform.pathSeparator}$clientSettingsFileName',
    );
    await root.create(recursive: true);
    for (final text in ['{', '[]', 'not json']) {
      await file.writeAsString(text);
      final loaded = await openClientSettingsStore(root).load();
      expect(loaded.theme.mode, ThemeMode.dark);
      expect(loaded.theme.accent, RsThemeSettings.defaultAccent);
      expect(loaded.uiSounds, isTrue);
    }
  });
}
