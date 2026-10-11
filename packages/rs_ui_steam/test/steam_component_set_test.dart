import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rs_ui/rs_ui.dart';
import 'package:rs_ui_steam/rs_ui_steam.dart';

import 'helpers.dart';

void main() {
  for (final mode in [ThemeMode.dark, ThemeMode.light]) {
    testWidgets('renders the basic controls in ${mode.name} mode', (
      tester,
    ) async {
      await tester.pumpWidget(
        steamApp(
          mode: mode,
          center: true,
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
      steamApp(
        center: true,
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

  group('SteamGallery', () {
    for (final (name, size) in [
      ('phone', phone),
      ('desktop', desktop),
      ('4K TV', tv4k),
    ]) {
      for (final dark in [true, false]) {
        testWidgets('renders every component on $name, dark: $dark', (
          tester,
        ) async {
          setScreen(tester, size);
          await tester.pumpWidget(
            MaterialApp(home: SteamGallery(initialDark: dark)),
          );
          await tester.pump(const Duration(milliseconds: 500));
          expect(tester.takeException(), isNull);
          expect(find.text('Chrono Trigger'), findsWidgets);

          // Scroll through the whole page so every section builds.
          for (var i = 0; i < 30; i++) {
            await tester.drag(
              find.byType(Scrollable).first,
              const Offset(0, -400),
            );
            await tester.pump(const Duration(milliseconds: 50));
          }
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('toasts can be added and dismissed', (tester) async {
      setScreen(tester, desktop);
      await tester.pumpWidget(const MaterialApp(home: SteamGallery()));
      await tester.pump();
      // Install button (autofocused) adds a progress toast.
      await tester.tap(find.text('Install'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Scanning library…'), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(RsToastStack),
          matching: find.byIcon(Icons.close_rounded),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      expect(find.text('Scanning library…'), findsNothing);
    });

    testWidgets('hint bar switches the theme', (tester) async {
      setScreen(tester, desktop);
      await tester.pumpWidget(const MaterialApp(home: SteamGallery()));
      await tester.pump();
      await tester.tap(find.text('Light mode'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Dark mode'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}
