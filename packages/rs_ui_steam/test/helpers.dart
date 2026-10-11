import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rs_theme/rs_theme.dart';
import 'package:rs_ui/rs_ui.dart';
import 'package:rs_ui_steam/rs_ui_steam.dart';

/// Wraps [child] like the client does: MaterialApp plumbing, Steam set and
/// input scope above the navigator.
Widget steamApp(
  Widget child, {
  ThemeMode mode = ThemeMode.dark,
  bool center = false,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: RsThemeBuilder.light(const RsThemeSettings()),
  darkTheme: RsThemeBuilder.dark(const RsThemeSettings()),
  themeMode: mode,
  builder: (context, nav) => RsComponents(
    set: const SteamComponentSet(),
    child: RsInputScope(child: nav!),
  ),
  home: Material(
    type: MaterialType.transparency,
    child: center ? Center(child: child) : child,
  ),
);

/// Sets the logical screen size for the current test.
void setScreen(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Draw focus highlights as if a keyboard / controller were in use.
void useTraditionalFocus() {
  FocusManager.instance.highlightStrategy =
      FocusHighlightStrategy.alwaysTraditional;
  addTearDown(
    () => FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.automatic,
  );
}

const phone = Size(360, 740);
const desktop = Size(1440, 900);
const tv4k = Size(2560, 1440);
