import 'package:flutter/widgets.dart';

import 'components/rs_button.dart';
import 'components/rs_button_hints.dart';
import 'components/rs_dialog.dart';
import 'components/rs_game_card.dart';
import 'components/rs_glyph.dart';
import 'components/rs_grid.dart';
import 'components/rs_hero.dart';
import 'components/rs_list_row.dart';
import 'components/rs_progress.dart';
import 'components/rs_scaffold.dart';
import 'components/rs_shelf.dart';
import 'components/rs_tabs.dart';
import 'components/rs_text_field.dart';
import 'components/rs_tile.dart';
import 'components/rs_toast.dart';
import 'components/rs_toggle.dart';
import 'components/rs_top_bar.dart';
import 'components/rs_wizard_frame.dart';

/// A complete look and feel. Implementations live in their own packages
/// (for example `rs_ui_steam`) and are selected by the user in settings.
///
/// Every method receives the abstract widget as its configuration and returns
/// the concrete widget tree. Implementations must:
/// - read colors, spacing and motion from the theme (`RsTokens`), never hardcode them;
/// - wrap interactive parts in [RsFocusable] so focus and controller input stay consistent.
///
/// Shared behavior (LB / RB routing, dialog focus trapping and back
/// handling) lives in the abstract widgets, so sets only draw.
abstract class RsComponentSet {
  const RsComponentSet();

  /// Stable ID, persisted in user settings.
  String get id;

  /// Name shown in the settings UI.
  String get displayName;

  // Controls
  Widget button(BuildContext context, RsButton config);
  Widget toggle(BuildContext context, RsToggle config);
  Widget textField(BuildContext context, RsTextField config);
  Widget listRow(BuildContext context, RsListRow config);
  Widget tabs(BuildContext context, RsTabs config);

  // Artwork
  Widget tile(BuildContext context, RsTile config);
  Widget gameArt(BuildContext context, RsGameArt config);
  Widget gameCard(BuildContext context, RsGameCard config);
  Widget shelf(BuildContext context, RsShelf config);
  Widget grid(BuildContext context, RsGrid config);
  Widget hero(BuildContext context, RsHero config);

  // Page chrome
  Widget scaffold(BuildContext context, RsScaffold config);
  Widget topBar(BuildContext context, RsTopBar config);
  Widget buttonHints(BuildContext context, RsButtonHints config);
  Widget glyph(BuildContext context, RsGlyph config);
  Widget wizardFrame(BuildContext context, RsWizardFrame config);

  // Feedback
  Widget progressBar(BuildContext context, RsProgressBar config);
  Widget spinner(BuildContext context, RsSpinner config);
  Widget toast(BuildContext context, RsToast config);
  Widget toastStack(BuildContext context, RsToastStack config);

  // Overlays
  Widget dialog(BuildContext context, RsDialog config);

  /// The route [showRsDialog] pushes: backdrop, transition, dismissal.
  /// [builder] already includes the shared dialog behavior.
  Route<T> dialogRoute<T>(
    BuildContext context,
    WidgetBuilder builder, {
    required bool dismissible,
  });
}

/// Provides the active [RsComponentSet] to the widget tree.
class RsComponents extends InheritedWidget {
  const RsComponents({super.key, required this.set, required super.child});

  final RsComponentSet set;

  static RsComponentSet of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<RsComponents>();
    assert(scope != null, 'No RsComponents found above this widget.');
    return scope!.set;
  }

  @override
  bool updateShouldNotify(RsComponents oldWidget) => set != oldWidget.set;
}
