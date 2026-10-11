import 'package:flutter/widgets.dart';

/// Go back / close (controller B, Escape, Backspace).
class RsBackIntent extends Intent {
  const RsBackIntent();
}

/// Open the main menu (controller Start / Guide).
class RsMenuIntent extends Intent {
  const RsMenuIntent();
}

/// Open the context menu for the focused item (controller Select / Options).
class RsOptionsIntent extends Intent {
  const RsOptionsIntent();
}

/// Switch tab / section left or right (controller LB / RB).
class RsTabIntent extends Intent {
  const RsTabIntent(this.direction);

  /// `-1` for previous, `1` for next.
  final int direction;
}
