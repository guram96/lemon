import 'package:flutter/widgets.dart';
import 'package:rs_ui/rs_ui.dart';

import 'steam_button.dart';
import 'steam_button_hints.dart';
import 'steam_dialog.dart';
import 'steam_game_art.dart';
import 'steam_game_card.dart';
import 'steam_glyph.dart';
import 'steam_grid.dart';
import 'steam_hero.dart';
import 'steam_list_row.dart';
import 'steam_progress.dart';
import 'steam_scaffold.dart';
import 'steam_shelf.dart';
import 'steam_tabs.dart';
import 'steam_text_field.dart';
import 'steam_tile.dart';
import 'steam_toast.dart';
import 'steam_toggle.dart';
import 'steam_top_bar.dart';
import 'steam_wizard_frame.dart';

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
  Widget textField(BuildContext context, RsTextField config) =>
      SteamTextField(config);

  @override
  Widget listRow(BuildContext context, RsListRow config) =>
      SteamListRow(config);

  @override
  Widget tabs(BuildContext context, RsTabs config) => SteamTabs(config);

  @override
  Widget tile(BuildContext context, RsTile config) => SteamTile(config);

  @override
  Widget gameArt(BuildContext context, RsGameArt config) =>
      SteamGameArt(config);

  @override
  Widget gameCard(BuildContext context, RsGameCard config) =>
      SteamGameCard(config);

  @override
  Widget shelf(BuildContext context, RsShelf config) => SteamShelf(config);

  @override
  Widget grid(BuildContext context, RsGrid config) => SteamGrid(config);

  @override
  Widget hero(BuildContext context, RsHero config) => SteamHero(config);

  @override
  Widget scaffold(BuildContext context, RsScaffold config) =>
      SteamScaffold(config);

  @override
  Widget topBar(BuildContext context, RsTopBar config) => SteamTopBar(config);

  @override
  Widget buttonHints(BuildContext context, RsButtonHints config) =>
      SteamButtonHints(config);

  @override
  Widget glyph(BuildContext context, RsGlyph config) => SteamGlyph(config);

  @override
  Widget wizardFrame(BuildContext context, RsWizardFrame config) =>
      SteamWizardFrame(config);

  @override
  Widget progressBar(BuildContext context, RsProgressBar config) =>
      SteamProgressBar(config);

  @override
  Widget spinner(BuildContext context, RsSpinner config) =>
      SteamSpinner(config);

  @override
  Widget toast(BuildContext context, RsToast config) => SteamToast(config);

  @override
  Widget toastStack(BuildContext context, RsToastStack config) =>
      SteamToastStack(config);

  @override
  Widget dialog(BuildContext context, RsDialog config) => SteamDialog(config);

  @override
  Route<T> dialogRoute<T>(
    BuildContext context,
    WidgetBuilder builder, {
    required bool dismissible,
  }) => steamDialogRoute<T>(context, builder, dismissible: dismissible);
}
