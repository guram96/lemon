import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rs_theme/rs_theme.dart';
import 'package:rs_ui/rs_ui.dart';
import 'package:rs_ui_steam/rs_ui_steam.dart';

Widget _app(Widget child, {ThemeMode mode = ThemeMode.dark}) => MaterialApp(
  theme: RsThemeBuilder.light(const RsThemeSettings()),
  darkTheme: RsThemeBuilder.dark(const RsThemeSettings()),
  themeMode: mode,
  home: RsComponents(
    set: const SteamComponentSet(),
    child: RsInputScope(child: Center(child: child)),
  ),
);

void main() {
  for (final mode in [ThemeMode.dark, ThemeMode.light]) {
    testWidgets('renders every component in ${mode.name} mode', (tester) async {
      await tester.pumpWidget(
        _app(
          mode: mode,
          SizedBox(
            width: 600,
            child: Column(
              children: [
                RsButton(
                  label: 'Play',
                  variant: RsButtonVariant.primary,
                  onPressed: () {},
                ),
                RsButton(
                  label: 'Uninstall',
                  variant: RsButtonVariant.danger,
                  onPressed: () {},
                ),
                RsToggle(
                  label: 'Dark mode',
                  description: 'Use the dark theme',
                  value: true,
                  onChanged: (_) {},
                ),
                SizedBox(
                  width: 120,
                  child: RsTile(
                    image: null,
                    title: 'Chrono Trigger',
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.text('Play'), findsOneWidget);
      expect(find.text('Dark mode'), findsOneWidget);
      expect(find.text('Chrono Trigger'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('toggle flips its value when activated', (tester) async {
    bool? changed;
    await tester.pumpWidget(
      _app(
        SizedBox(
          width: 400,
          child: RsToggle(
            label: 'Wi-Fi',
            value: false,
            onChanged: (v) => changed = v,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Wi-Fi'));
    expect(changed, isTrue);
  });
}
