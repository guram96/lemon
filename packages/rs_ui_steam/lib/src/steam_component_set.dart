import 'package:flutter/widgets.dart';
import 'package:rs_ui/rs_ui.dart';

import 'steam_button.dart';
import 'steam_tile.dart';
import 'steam_toggle.dart';

/// The default look: a recreation of Steam Big Picture mode.
class SteamComponentSet extends RsComponentSet {
  const SteamComponentSet();

  @override
  String get id => 'steam';

  @override
  String get displayName => 'Steam Big Picture';

  @override
  Widget button(BuildContext context, RsButton config) => SteamButton(config);

  @override
  Widget toggle(BuildContext context, RsToggle config) => SteamToggle(config);

  @override
  Widget tile(BuildContext context, RsTile config) => SteamTile(config);
}
