import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rs_theme/rs_theme.dart';
import 'package:rs_ui/rs_ui.dart';
import 'package:rs_ui_crossblade/rs_ui_crossblade.dart';
import 'package:rs_ui_steam/rs_ui_steam.dart';

import 'theme_settings_provider.dart';

/// A selectable look: a component set plus the theme it is drawn with.
@immutable
class ClientLook {
  const ClientLook({
    required this.set,
    required this.light,
    required this.dark,
  });

  final RsComponentSet set;
  final ThemeData Function(RsThemeSettings settings) light;
  final ThemeData Function(RsThemeSettings settings) dark;

  String get id => set.id;
  String get displayName => set.displayName;
}

/// Every look shipped with the app, default first. Register new looks here.
final availableLooksProvider = Provider<List<ClientLook>>(
  (_) => const [
    ClientLook(
      set: CrossbladeComponentSet(),
      light: CrossbladeTheme.light,
      dark: CrossbladeTheme.dark,
    ),
    ClientLook(
      set: SteamComponentSet(),
      light: RsThemeBuilder.light,
      dark: RsThemeBuilder.dark,
    ),
  ],
);

/// The look selected in [RsThemeSettings.look]. Falls back to the first.
final lookProvider = Provider<ClientLook>((ref) {
  final looks = ref.watch(availableLooksProvider);
  final id = ref.watch(themeSettingsProvider.select((s) => s.look));
  return looks.firstWhere((l) => l.id == id, orElse: () => looks.first);
});

/// The active component set.
final componentSetProvider = Provider<RsComponentSet>(
  (ref) => ref.watch(lookProvider).set,
);
