import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rs_theme/rs_theme.dart';

/// Current theme settings. Edited from the settings UI.
// TODO(settings): persist locally once the settings feature exists.
final themeSettingsProvider =
    NotifierProvider<ThemeSettingsNotifier, RsThemeSettings>(
      ThemeSettingsNotifier.new,
    );

class ThemeSettingsNotifier extends Notifier<RsThemeSettings> {
  @override
  RsThemeSettings build() => const RsThemeSettings();

  void update(RsThemeSettings settings) => state = settings;
}
