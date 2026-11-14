import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rs_theme/rs_theme.dart';
import 'package:rs_ui/rs_ui.dart';
import 'package:rs_ui_crossblade/rs_ui_crossblade.dart';

Widget crossbladeApp(Widget child, {ThemeMode mode = ThemeMode.dark}) =>
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: CrossbladeTheme.light(const RsThemeSettings()),
      darkTheme: CrossbladeTheme.dark(const RsThemeSettings()),
      themeMode: mode,
      builder: (context, nav) => RsComponents(
        set: const CrossbladeComponentSet(),
        child: RsInputScope(child: nav!),
      ),
      home: child,
    );

void useTraditionalFocus() {
  FocusManager.instance.highlightStrategy =
      FocusHighlightStrategy.alwaysTraditional;
  addTearDown(
    () => FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.automatic,
  );
}

void main() {
  test('identifies itself and swaps the default accent for jewel green', () {
    const set = CrossbladeComponentSet();
    expect(set.id, 'crossblade');
    expect(set.displayName, 'Crossblade');
    expect(RsThemeSettings.defaultLook, set.id);

    final dark = CrossbladeTheme.dark(const RsThemeSettings());
    expect(dark.extension<RsTokens>()!.accent, CrossbladeTheme.green);

    const custom = Color(0xFFFF00AA);
    final picked = CrossbladeTheme.dark(const RsThemeSettings(accent: custom));
    expect(picked.extension<RsTokens>()!.accent, custom);
  });

  for (final mode in [ThemeMode.dark, ThemeMode.light]) {
    testWidgets('renders a full page in ${mode.name} mode', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      useTraditionalFocus();
      var selected = 0;
      var activated = 0;

      await tester.pumpWidget(
        crossbladeApp(
          mode: mode,
          StatefulBuilder(
            builder: (context, setState) => RsScaffold(
              topBar: RsTopBar(
                items: const [
                  RsNavItem(label: 'Home'),
                  RsNavItem(label: 'Library'),
                ],
                selectedIndex: selected,
                onSelected: (i) => setState(() => selected = i),
                notificationCount: 3,
                onNotifications: () {},
                userName: 'Player One',
                onAvatar: () {},
              ),
              hints: const RsButtonHints(
                hints: [
                  RsButtonHint(button: RsControllerButton.a, label: 'Select'),
                ],
              ),
              body: ListView(
                children: [
                  RsShelf(
                    title: 'Recently added',
                    subtitle: '2 games',
                    itemCount: 2,
                    itemBuilder: (context, i) => RsGameCard(
                      title: 'Game $i',
                      systemId: 'snes',
                      installed: i == 0,
                      progress: i == 1 ? 0.4 : null,
                      autofocus: i == 0,
                      onPressed: () => activated++,
                    ),
                  ),
                  RsButton(
                    label: 'Play',
                    variant: RsButtonVariant.primary,
                    onPressed: () {},
                  ),
                  RsButton(
                    label: 'Delete',
                    variant: RsButtonVariant.danger,
                    onPressed: () {},
                  ),
                  RsListRow(
                    title: 'Sounds',
                    switchValue: true,
                    onPressed: () {},
                  ),
                  const RsListRow(
                    title: 'Look',
                    value: 'Crossblade',
                    chevron: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Recently added'), findsOneWidget);
      expect(find.text('Play'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(activated, 1);

      await tester.sendKeyEvent(LogicalKeyboardKey.gameButtonRight1);
      await tester.pumpAndSettle();
      expect(selected, 1);
    });
  }

  testWidgets('dialog pops in and closes with back', (tester) async {
    await tester.pumpWidget(
      crossbladeApp(
        Builder(
          builder: (context) => Center(
            child: RsButton(
              label: 'Open',
              autofocus: true,
              onPressed: () => showRsDialog<void>(
                context: context,
                builder: (_) => RsDialog(
                  title: 'Sign out?',
                  icon: Icons.logout,
                  message: 'You can sign back in at any time.',
                  actions: [RsButton(label: 'Cancel', onPressed: () {})],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Sign out?'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Sign out?'), findsNothing);
  });

  test('blade border lerps and scales', () {
    const a = BladeBorder(slant: 10, radius: 4);
    final half = a.scale(0.5) as BladeBorder;
    expect(half.slant, 5);
    expect(half.radius, 2);
    final path = a.getOuterPath(const Rect.fromLTWH(0, 0, 120, 40));
    expect(path.getBounds().width, closeTo(120, 1));
    expect(path.contains(const Offset(60, 20)), isTrue);
    expect(path.contains(const Offset(1, 1)), isFalse);
  });
}
