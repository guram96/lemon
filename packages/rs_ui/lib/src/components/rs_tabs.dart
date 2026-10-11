import 'package:flutter/widgets.dart';

import '../component_set.dart';
import '../input/rs_tab_host.dart';
import 'rs_top_bar.dart';

/// One tab of an [RsTabs] strip.
@immutable
class RsTab {
  const RsTab({required this.label, this.count, this.icon});

  final String label;

  /// Optional item count shown after the label.
  final int? count;
  final IconData? icon;
}

/// Horizontal tab strip (for example the system filter in the library).
/// LB / RB switch tabs from anywhere on the page and take priority over the
/// top bar (see [RsTabHost]).
class RsTabs extends StatefulWidget {
  const RsTabs({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onChanged,
    this.showBumperHints = true,
  });

  final List<RsTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  /// Shows LB / RB glyphs at the ends of the strip.
  final bool showBumperHints;

  @override
  State<RsTabs> createState() => _RsTabsState();
}

class _RsTabsState extends State<RsTabs> with RsTabHostClient<RsTabs> {
  @override
  int get tabPriority => RsTabHost.tabsPriority;

  @override
  bool onTab(int direction) => rsCycleSelection(
    count: widget.tabs.length,
    selected: widget.selectedIndex,
    direction: direction,
    onSelected: widget.onChanged,
  );

  @override
  Widget build(BuildContext context) =>
      wrapTabActions(RsComponents.of(context).tabs(context, widget));
}
