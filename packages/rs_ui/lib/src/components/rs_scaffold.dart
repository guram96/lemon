import 'package:flutter/widgets.dart';

import '../component_set.dart';
import '../input/rs_tab_host.dart';

/// Page frame: optional top bar, body, optional bottom button-hint bar, over
/// the set's page background.
///
/// Installs an [RsTabHost], so LB / RB reach the page's [RsTopBar] or
/// [RsTabs] wherever focus is on the page.
class RsScaffold extends StatelessWidget {
  const RsScaffold({
    super.key,
    required this.body,
    this.topBar,
    this.hints,
    this.background,
    this.extendBodyBehindTopBar = false,
  });

  final Widget body;

  /// Usually an [RsTopBar].
  final Widget? topBar;

  /// Usually an [RsButtonHints].
  final Widget? hints;

  /// Drawn full-bleed behind everything, above the default gradient (for
  /// example the focused game's art on the home page).
  final Widget? background;

  /// Lets [body] start at the top edge, under the top bar (for heroes).
  final bool extendBodyBehindTopBar;

  @override
  Widget build(BuildContext context) =>
      RsTabHost(child: RsComponents.of(context).scaffold(context, this));
}
