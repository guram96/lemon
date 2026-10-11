import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rs_theme/rs_theme.dart';

import '../settings/client_settings.dart';

/// Current theme settings. Edited from the settings UI and written to
/// [clientSettingsStoreProvider].
final themeSettingsProvider =
    NotifierProvider<ThemeSettingsNotifier, RsThemeSettings>(
      ThemeSettingsNotifier.new,
    );

class ThemeSettingsNotifier extends Notifier<RsThemeSettings> {
  @override
  RsThemeSettings build() =>
      ref.watch(clientSettingsProvider.select((settings) => settings.theme));

  /// Applies [settings] immediately and persists them.
  Future<void> update(RsThemeSettings settings) =>
      ref.read(clientSettingsProvider.notifier).setTheme(settings);
}
