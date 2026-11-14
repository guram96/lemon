import 'package:flutter/material.dart';
import 'package:rs_theme/rs_theme.dart';
import 'package:rs_ui/rs_ui.dart';
import 'package:rs_ui_steam/rs_ui_steam.dart';

import 'crossblade_backdrop.dart';
import 'crossblade_button.dart';
import 'crossblade_dialog.dart';
import 'crossblade_game_card.dart';
import 'crossblade_list_row.dart';
import 'crossblade_scaffold.dart';
import 'crossblade_shelf.dart';
import 'crossblade_top_bar.dart';

/// Crossblade: Xbox 360 blades and the original Xbox jewel glow, over a
/// flowing PS3 XMB wave backdrop.
///
/// The page chrome, buttons, capsules, shelves, rows and dialogs are drawn
/// here. The rest (text fields, tabs, toasts, glyphs, progress, wizard)
/// comes from the Steam set and picks up the Crossblade palette through
/// the theme.
class CrossbladeComponentSet extends SteamComponentSet {
  const CrossbladeComponentSet();

  @override
  String get id => 'crossblade';

  @override
  String get displayName => 'Crossblade';

  @override
  Widget button(BuildContext context, RsButton config) =>
      CrossbladeButton(config);

  @override
  Widget listRow(BuildContext context, RsListRow config) =>
      CrossbladeListRow(config);

  @override
  Widget gameArt(BuildContext context, RsGameArt config) {
    final art = super.gameArt(context, config);
    if (config.layout != RsArtLayout.background) return art;
    // Backdrops get the XMB ribbons flowing over the artwork.
    return Stack(
      fit: StackFit.expand,
      children: [
        art,
        const IgnorePointer(
          child: CrossbladeBackdrop(sky: false, ribbonLevel: 0.36),
        ),
      ],
    );
  }

  @override
  Widget gameCard(BuildContext context, RsGameCard config) =>
      CrossbladeGameCard(config, art: super.gameArt);

  @override
  Widget shelf(BuildContext context, RsShelf config) => CrossbladeShelf(config);

  @override
  Widget scaffold(BuildContext context, RsScaffold config) =>
      CrossbladeScaffold(config);

  @override
  Widget topBar(BuildContext context, RsTopBar config) =>
      CrossbladeTopBar(config);

  @override
  Widget wizardFrame(BuildContext context, RsWizardFrame config) {
    // The base frame paints an opaque page gradient; clear it so the
    // animated backdrop shows through.
    final theme = Theme.of(context);
    final t = context.rsTokens;
    final clear = t.background.withValues(alpha: 0);
    return Stack(
      fit: StackFit.expand,
      children: [
        const CrossbladeBackdrop(),
        Theme(
          data: theme.copyWith(
            extensions: [
              t.copyWith(background: clear, backgroundGradientEnd: clear),
            ],
          ),
          child: super.wizardFrame(context, config),
        ),
      ],
    );
  }

  @override
  Widget dialog(BuildContext context, RsDialog config) =>
      CrossbladeDialog(config);

  @override
  Route<T> dialogRoute<T>(
    BuildContext context,
    WidgetBuilder builder, {
    required bool dismissible,
  }) => crossbladeDialogRoute<T>(context, builder, dismissible: dismissible);
}
