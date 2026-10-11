import 'package:flutter/widgets.dart';

import 'components/rs_button.dart';
import 'components/rs_tile.dart';
import 'components/rs_toggle.dart';

/// A complete look and feel. Implementations live in their own packages
/// (for example `rs_ui_steam`) and are selected by the user in settings.
///
/// Every method receives the abstract widget as its configuration and returns
/// the concrete widget tree. Implementations must:
/// - read colors, spacing and motion from the theme (`RsTokens`), never hardcode them;
/// - wrap interactive parts in [RsFocusable] so focus and controller input stay consistent.
abstract class RsComponentSet {
  const RsComponentSet();

  /// Stable ID, persisted in user settings.
  String get id;

  /// Name shown in the settings UI.
  String get displayName;

  Widget button(BuildContext context, RsButton config);
  Widget toggle(BuildContext context, RsToggle config);
  Widget tile(BuildContext context, RsTile config);
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
