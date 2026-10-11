import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'rs_intents.dart';

/// Maps keyboard and controller buttons to app intents. Place once near the
/// app root, below `WidgetsApp` (which already maps arrows to directional
/// focus and Enter / Space to [ActivateIntent]).
///
/// Controllers that report as key events (Android, most Bluetooth pads) work
/// through these bindings. Desktop gamepad support via a plugin will feed the
/// same intents.
class RsInputScope extends StatelessWidget {
  const RsInputScope({super.key, required this.child});

  final Widget child;

  static const shortcuts = <ShortcutActivator, Intent>{
    // Confirm
    SingleActivator(LogicalKeyboardKey.gameButtonA): ActivateIntent(),
    // Back
    SingleActivator(LogicalKeyboardKey.gameButtonB): RsBackIntent(),
    SingleActivator(LogicalKeyboardKey.escape): RsBackIntent(),
    SingleActivator(LogicalKeyboardKey.backspace): RsBackIntent(),
    SingleActivator(LogicalKeyboardKey.goBack): RsBackIntent(),
    // Menus
    SingleActivator(LogicalKeyboardKey.gameButtonStart): RsMenuIntent(),
    SingleActivator(LogicalKeyboardKey.gameButtonSelect): RsOptionsIntent(),
    SingleActivator(LogicalKeyboardKey.contextMenu): RsOptionsIntent(),
    // Tabs. No single-letter keyboard keys here: they would swallow typing in text fields.
    SingleActivator(LogicalKeyboardKey.gameButtonLeft1): RsTabIntent(-1),
    SingleActivator(LogicalKeyboardKey.gameButtonRight1): RsTabIntent(1),
    SingleActivator(LogicalKeyboardKey.pageUp): RsTabIntent(-1),
    SingleActivator(LogicalKeyboardKey.pageDown): RsTabIntent(1),
  };

  @override
  Widget build(BuildContext context) =>
      Shortcuts(shortcuts: shortcuts, child: child);
}
