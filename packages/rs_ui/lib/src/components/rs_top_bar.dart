import 'package:flutter/widgets.dart';

import '../component_set.dart';
import '../input/rs_tab_host.dart';

/// One destination in an [RsTopBar].
@immutable
class RsNavItem {
  const RsNavItem({required this.label, this.icon});

  final String label;

  /// Shown instead of the label at compact widths, when set.
  final IconData? icon;
}

/// Big Picture top bar: navigation items on the left; clock, notifications
/// bell and user avatar on the right. LB / RB ([RsTabIntent]) move the
/// selection, anywhere on the page (see [RsTabHost]).
class RsTopBar extends StatefulWidget {
  const RsTopBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    this.showClock = true,
    this.notificationCount = 0,
    this.onNotifications,
    this.userName,
    this.avatar,
    this.onAvatar,
    this.trailing = const [],
  });

  final List<RsNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  final bool showClock;

  /// Unread count on the bell badge; `0` hides the badge.
  final int notificationCount;

  /// `null` hides the bell.
  final VoidCallback? onNotifications;

  /// Used for the avatar's initials and semantics. `null` and no [avatar]
  /// hides the avatar.
  final String? userName;
  final ImageProvider? avatar;
  final VoidCallback? onAvatar;

  /// Extra widgets before the clock (for example a search button).
  final List<Widget> trailing;

  @override
  State<RsTopBar> createState() => _RsTopBarState();
}

class _RsTopBarState extends State<RsTopBar> with RsTabHostClient<RsTopBar> {
  @override
  int get tabPriority => RsTabHost.navPriority;

  @override
  bool onTab(int direction) => rsCycleSelection(
    count: widget.items.length,
    selected: widget.selectedIndex,
    direction: direction,
    onSelected: widget.onSelected,
  );

  @override
  Widget build(BuildContext context) =>
      wrapTabActions(RsComponents.of(context).topBar(context, widget));
}

/// Same as [RsTopBar]; the name used in the architecture docs.
typedef RsNavBar = RsTopBar;

/// Shared LB / RB behavior: move [selected] by [direction], clamped (no
/// wrap-around, like Big Picture). Consumes the intent at the ends too.
bool rsCycleSelection({
  required int count,
  required int selected,
  required int direction,
  required ValueChanged<int> onSelected,
}) {
  if (count < 2) return false;
  final next = (selected + direction).clamp(0, count - 1);
  if (next != selected) onSelected(next);
  return true;
}
