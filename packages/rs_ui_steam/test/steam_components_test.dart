import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rs_theme/rs_theme.dart';
import 'package:rs_ui/rs_ui.dart';
import 'package:rs_ui_steam/src/steam_game_art.dart';

import 'helpers.dart';

/// Reads the scale of the [AnimatedScale] inside the widget found by [of].
double _scaleOf(WidgetTester tester, Finder of) => tester
    .widget<AnimatedScale>(
      find.descendant(of: of, matching: find.byType(AnimatedScale)).first,
    )
    .scale;

RsTokens _tokens(WidgetTester tester, Finder f) =>
    RsTokens.of(tester.element(f));

void main() {
  group('RsButton', () {
    testWidgets('renders, highlights on focus, activates with A', (
      tester,
    ) async {
      useTraditionalFocus();
      var presses = 0;
      await tester.pumpWidget(
        steamApp(
          center: true,
          RsButton(
            label: 'Play',
            icon: Icons.play_arrow_rounded,
            variant: RsButtonVariant.primary,
            autofocus: true,
            onPressed: () => presses++,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer).first,
      );
      expect((container.decoration! as BoxDecoration).boxShadow, isNotEmpty);
      await tester.sendKeyEvent(LogicalKeyboardKey.gameButtonA);
      await tester.tap(find.text('Play'));
      expect(presses, 2);
    });
  });

  group('RsTextField', () {
    testWidgets('typing and Backspace edit the text instead of going back', (
      tester,
    ) async {
      var backs = 0;
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        steamApp(
          Actions(
            actions: {
              RsBackIntent: CallbackAction<RsBackIntent>(
                onInvoke: (_) => backs++,
              ),
            },
            child: RsTextField(
              label: 'Username',
              controller: controller,
              autofocus: true,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.enterText(find.byType(EditableText), 'admin');
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();
      expect(controller.text, 'admi');
      expect(backs, 0);
      // Escape still means back.
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      expect(backs, 1);
    });

    testWidgets('Tab and arrow down move to the next field', (tester) async {
      final a = FocusNode();
      final b = FocusNode();
      final c = FocusNode();
      addTearDown(() {
        a.dispose();
        b.dispose();
        c.dispose();
      });
      await tester.pumpWidget(
        steamApp(
          Column(
            children: [
              RsTextField(label: 'A', focusNode: a, autofocus: true),
              RsTextField(label: 'B', focusNode: b),
              RsTextField(label: 'C', focusNode: c),
            ],
          ),
        ),
      );
      await tester.pump();
      expect(a.hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(b.hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(c.hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(b.hasFocus, isTrue);
    });

    testWidgets('shows errors and reveals passwords', (tester) async {
      await tester.pumpWidget(
        steamApp(
          const Column(
            children: [
              RsTextField(label: 'Password', obscure: true, hint: 'Secret'),
              RsTextField(label: 'Server', errorText: 'Unreachable'),
            ],
          ),
        ),
      );
      expect(find.text('Unreachable'), findsOneWidget);
      EditableText password() =>
          tester.widget<EditableText>(find.byType(EditableText).first);
      expect(password().obscureText, isTrue);
      await tester.tap(find.byIcon(Icons.visibility_rounded));
      await tester.pump();
      expect(password().obscureText, isFalse);
    });
  });

  group('RsListRow', () {
    testWidgets('activates, shows value, switch and chevron', (tester) async {
      var presses = 0;
      await tester.pumpWidget(
        steamApp(
          Column(
            children: [
              RsListRow(
                icon: Icons.folder_outlined,
                title: 'Data folder',
                subtitle: 'Where the database lives',
                value: '/data',
                chevron: true,
                autofocus: true,
                onPressed: () => presses++,
              ),
              const RsListRow(title: 'Info', switchValue: true),
            ],
          ),
        ),
      );
      await tester.pump();
      expect(find.text('/data'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.tap(find.text('Data folder'));
      expect(presses, 2);

      // Info rows without an action are still reachable with the d-pad.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      final focused = FocusManager.instance.primaryFocus!.context!;
      expect(
        find
            .ancestor(of: find.text('Info'), matching: find.byType(RsListRow))
            .evaluate()
            .single,
        isNotNull,
      );
      expect(focused.findAncestorWidgetOfExactType<RsListRow>()?.title, 'Info');
    });
  });

  group('RsTabs', () {
    testWidgets('tap selects; LB / RB switch while focus is elsewhere', (
      tester,
    ) async {
      var selected = 0;
      Widget build() => steamApp(
        RsScaffold(
          body: Column(
            children: [
              RsTabs(
                tabs: const [
                  RsTab(label: 'All', count: 3),
                  RsTab(label: 'SNES', count: 2),
                  RsTab(label: 'PSX', count: 1),
                ],
                selectedIndex: selected,
                onChanged: (i) => selected = i,
              ),
              RsButton(label: 'grid', autofocus: true, onPressed: () {}),
            ],
          ),
        ),
      );
      await tester.pumpWidget(build());
      await tester.pump();
      expect(find.text('ALL'), findsOneWidget);
      await tester.tap(find.text('PSX'));
      expect(selected, 2);
      await tester.pumpWidget(build());
      await tester.sendKeyEvent(LogicalKeyboardKey.gameButtonLeft1);
      expect(selected, 1);
      await tester.pumpWidget(build());
      await tester.pump();
      // Tapping the RB glyph also works.
      await tester.tap(find.text('RB'));
      expect(selected, 2);
    });
  });

  group('RsTopBar', () {
    testWidgets('items, clock, badge and avatar; LB / RB cycle', (
      tester,
    ) async {
      setScreen(tester, desktop);
      var nav = 0;
      var bell = 0;
      Widget build() => steamApp(
        RsScaffold(
          topBar: RsTopBar(
            items: const [
              RsNavItem(label: 'Home'),
              RsNavItem(label: 'Library'),
            ],
            selectedIndex: nav,
            onSelected: (i) => nav = i,
            notificationCount: 120,
            onNotifications: () => bell++,
            userName: 'Ada Lovelace',
          ),
          body: Center(
            child: RsButton(label: 'x', autofocus: true, onPressed: () {}),
          ),
        ),
      );
      await tester.pumpWidget(build());
      await tester.pump();
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('99+'), findsOneWidget);
      expect(find.text('AL'), findsOneWidget);
      expect(find.textContaining(':'), findsOneWidget); // clock
      await tester.sendKeyEvent(LogicalKeyboardKey.gameButtonRight1);
      expect(nav, 1);
      await tester.tap(find.text('Home'));
      expect(nav, 0);
      await tester.tap(find.byIcon(Icons.notifications_rounded));
      expect(bell, 1);
    });

    testWidgets('compact width shows icons and hides the clock', (
      tester,
    ) async {
      setScreen(tester, phone);
      await tester.pumpWidget(
        steamApp(
          RsScaffold(
            topBar: RsTopBar(
              items: const [
                RsNavItem(label: 'Home', icon: Icons.home_rounded),
                RsNavItem(label: 'Library', icon: Icons.grid_view_rounded),
              ],
              selectedIndex: 0,
              onSelected: (_) {},
              userName: 'Ada',
            ),
            body: const SizedBox.expand(),
          ),
        ),
      );
      expect(find.byIcon(Icons.home_rounded), findsOneWidget);
      expect(find.text('Home'), findsNothing);
      expect(find.textContaining(':'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('RsButtonHints / RsGlyph', () {
    testWidgets('hints render, are tappable, never take focus', (tester) async {
      var backs = 0;
      await tester.pumpWidget(
        steamApp(
          Column(
            children: [
              RsButton(label: 'only', autofocus: true, onPressed: () {}),
              const Spacer(),
              RsButtonHints(
                leading: const [
                  RsButtonHint(button: RsControllerButton.start, label: 'Menu'),
                ],
                hints: [
                  const RsButtonHint(
                    button: RsControllerButton.a,
                    label: 'Select',
                  ),
                  RsButtonHint(
                    button: RsControllerButton.b,
                    label: 'Back',
                    onPressed: () => backs++,
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Select'), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
      await tester.tap(find.text('Back'));
      expect(backs, 1);
      final before = FocusManager.instance.primaryFocus;
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus, before);
    });

    testWidgets('every button renders in every glyph style', (tester) async {
      await tester.pumpWidget(
        steamApp(
          Wrap(
            children: [
              for (final style in RsGlyphStyle.values)
                for (final b in RsControllerButton.values)
                  RsGlyph(button: b, style: style),
            ],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('L1'), findsOneWidget); // PlayStation bumper
      expect(find.text('ZR'), findsOneWidget); // Nintendo trigger
      expect(find.text('PgDn'), findsOneWidget); // keyboard RB
    });
  });

  group('RsGameCard / RsGameArt', () {
    testWidgets('generated art shows title and system; focus scales up', (
      tester,
    ) async {
      useTraditionalFocus();
      var presses = 0;
      await tester.pumpWidget(
        steamApp(
          center: true,
          SizedBox(
            width: 200,
            child: RsGameCard(
              title: 'Chrono Trigger',
              systemId: 'snes',
              systemName: 'Super Nintendo',
              installed: true,
              showSystemBadge: true,
              progress: 0.5,
              onPressed: () => presses++,
            ),
          ),
        ),
      );
      final card = find.byType(RsGameCard);
      expect(find.text('Chrono Trigger'), findsOneWidget);
      expect(find.text('SUPER NINTENDO'), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(_scaleOf(tester, card), 1);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(_scaleOf(tester, card), _tokens(tester, card).motion.focusScale);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(presses, 1);
    });

    testWidgets('broken images fall back to generated art', (tester) async {
      await tester.pumpWidget(
        steamApp(
          center: true,
          SizedBox(
            width: 300,
            child: RsGameCard(
              title: 'Shenmue',
              systemId: 'dreamcast',
              layout: RsArtLayout.wide,
              image: MemoryImage(Uint8List.fromList([0, 1, 2, 3])),
              onPressed: () {},
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Shenmue'), findsOneWidget);
      final size = tester.getSize(find.byType(RsGameCard));
      expect(size.width / size.height, closeTo(460 / 215, 0.01));
      expect(tester.takeException(), isNull);
    });

    test('generated palettes are deterministic per system and title', () {
      const art = RsArtStyle();
      final a = SteamArtPalette.of(art, 'snes', 'Chrono Trigger');
      final b = SteamArtPalette.of(art, 'snes', 'Chrono Trigger');
      final c = SteamArtPalette.of(art, 'psx', 'Chrono Trigger');
      expect(a.start, b.start);
      expect(a.end, b.end);
      expect(a.start, isNot(c.start));
    });

    testWidgets('background art has no caption', (tester) async {
      await tester.pumpWidget(
        steamApp(
          const SizedBox(
            width: 400,
            height: 200,
            child: RsGameArt(
              title: 'Tetris',
              systemId: 'gb',
              layout: RsArtLayout.background,
            ),
          ),
        ),
      );
      expect(find.text('Tetris'), findsNothing);
    });
  });

  group('RsShelf', () {
    testWidgets('d-pad scrolls the focused item into view', (tester) async {
      setScreen(tester, phone);
      final nodes = List.generate(12, (_) => FocusNode());
      addTearDown(() {
        for (final n in nodes) {
          n.dispose();
        }
      });
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        steamApp(
          Column(
            children: [
              RsShelf(
                title: 'Recently added',
                subtitle: '12 games',
                controller: controller,
                itemCount: 12,
                itemBuilder: (_, i) => RsGameCard(
                  title: 'Game $i',
                  systemId: 'snes',
                  focusNode: nodes[i],
                  autofocus: i == 0,
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Recently added'), findsOneWidget);
      expect(nodes[0].hasFocus, isTrue);
      for (var i = 0; i < 5; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pumpAndSettle();
      }
      expect(nodes[5].hasFocus, isTrue);
      expect(controller.offset, greaterThan(0));
      final rect = tester.getRect(find.text('Game 5'));
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(phone.width));
    });

    testWidgets('empty shelves show the empty text', (tester) async {
      await tester.pumpWidget(
        steamApp(
          RsShelf(
            title: 'Installed',
            itemCount: 0,
            itemBuilder: (_, _) => const SizedBox(),
            emptyText: 'Nothing installed yet',
          ),
        ),
      );
      expect(find.text('Nothing installed yet'), findsOneWidget);
    });
  });

  group('RsGrid', () {
    testWidgets('d-pad down moves a row and keeps it in view', (tester) async {
      setScreen(tester, desktop);
      final nodes = List.generate(60, (_) => FocusNode());
      addTearDown(() {
        for (final n in nodes) {
          n.dispose();
        }
      });
      await tester.pumpWidget(
        steamApp(
          RsGrid(
            itemCount: 60,
            itemBuilder: (_, i) => RsGameCard(
              title: 'Game $i',
              systemId: 'psx',
              focusNode: nodes[i],
              autofocus: i == 0,
              onPressed: () {},
            ),
          ),
        ),
      );
      await tester.pump();
      // Count the columns of the first row.
      final top = tester.getRect(find.byType(RsGameCard).first).top;
      final columns = find
          .byType(RsGameCard)
          .evaluate()
          .where((e) => tester.getRect(find.byWidget(e.widget)).top == top)
          .length;
      expect(columns, greaterThan(3));

      for (var i = 0; i < 4; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
      }
      final index = nodes.indexWhere((n) => n.hasFocus);
      expect(index, columns * 4);
      final rect = tester.getRect(find.text('Game $index'));
      expect(rect.bottom, lessThanOrEqualTo(desktop.height));
    });

    testWidgets('shows the empty widget', (tester) async {
      await tester.pumpWidget(
        steamApp(
          RsGrid(
            itemCount: 0,
            itemBuilder: (_, _) => const SizedBox(),
            empty: const Text('No games'),
          ),
        ),
      );
      expect(find.text('No games'), findsOneWidget);
    });
  });

  group('RsDialog', () {
    testWidgets('opens with focus on the first action; Escape closes', (
      tester,
    ) async {
      String? result;
      await tester.pumpWidget(
        steamApp(
          Builder(
            builder: (context) => Center(
              child: RsButton(
                label: 'Open',
                autofocus: true,
                onPressed: () async {
                  result = await showRsDialog<String>(
                    context: context,
                    builder: (context) => RsDialog(
                      icon: Icons.delete_outline_rounded,
                      title: 'Delete?',
                      message: 'This cannot be undone.',
                      actions: [
                        RsButton(
                          label: 'Cancel',
                          onPressed: () => Navigator.of(context).pop('no'),
                        ),
                        RsButton(
                          label: 'Delete',
                          variant: RsButtonVariant.danger,
                          onPressed: () => Navigator.of(context).pop('yes'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Delete?'), findsOneWidget);
      final focused = FocusManager.instance.primaryFocus!.context!;
      expect(
        focused.findAncestorWidgetOfExactType<RsButton>()?.label,
        'Cancel',
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(result, 'yes');

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Delete?'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Delete?'), findsNothing);
      expect(result, isNull);
    });

    testWidgets('stacks actions on phones without overflow', (tester) async {
      setScreen(tester, phone);
      await tester.pumpWidget(
        steamApp(
          RsDialog(
            title: 'A long dialog title that wraps on phones',
            content: const Text('Body'),
            actions: [
              RsButton(label: 'Cancel', onPressed: () {}),
              RsButton(label: 'Continue', onPressed: () {}),
            ],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final cancel = tester.getRect(find.text('Cancel'));
      final cont = tester.getRect(find.text('Continue'));
      expect(cont.top, greaterThan(cancel.bottom));
    });
  });

  group('RsProgressBar / RsSpinner', () {
    testWidgets('determinate, indeterminate and spinner render', (
      tester,
    ) async {
      await tester.pumpWidget(
        steamApp(
          const Column(
            children: [
              RsProgressBar(value: 0.5, label: 'Scanning', trailing: '1 / 2'),
              RsProgressBar(),
              RsSpinner(label: 'Loading'),
            ],
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Scanning'), findsOneWidget);
      expect(find.text('1 / 2'), findsOneWidget);
      expect(find.text('Loading'), findsOneWidget);
      expect(tester.takeException(), isNull);
      final fill = tester.widget<FractionallySizedBox>(
        find.byType(FractionallySizedBox).first,
      );
      expect(fill.widthFactor, closeTo(0.5, 0.01));
    });
  });

  group('RsToast / RsToastStack', () {
    testWidgets('slides in bottom-right, taps pass through, slides out', (
      tester,
    ) async {
      setScreen(tester, desktop);
      var under = 0;
      var toastTaps = 0;
      Widget build(List<RsToast> toasts) => steamApp(
        Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              child: RsButton(label: 'Under', onPressed: () => under++),
            ),
            Positioned.fill(child: RsToastStack(toasts: toasts)),
          ],
        ),
      );
      final toast = RsToast(
        key: const ValueKey('scan'),
        title: 'Scanning library…',
        body: '312 / 1 204',
        progress: 0.3,
        onPressed: () => toastTaps++,
      );
      await tester.pumpWidget(build([toast]));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final rect = tester.getRect(find.byType(RsToast));
      expect(rect.right, greaterThan(desktop.width - 100));
      expect(rect.bottom, greaterThan(desktop.height - 200));

      await tester.tap(find.text('Scanning library…'));
      await tester.tap(find.text('Under'));
      expect(toastTaps, 1);
      expect(under, 1);

      await tester.pumpWidget(build(const []));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      expect(find.byType(RsToast), findsNothing);
    });
  });

  group('RsWizardFrame', () {
    for (final (name, size) in [('phone', phone), ('desktop', desktop)]) {
      testWidgets('renders steps, content and footer on $name', (tester) async {
        setScreen(tester, size);
        var next = 0;
        await tester.pumpWidget(
          steamApp(
            RsWizardFrame(
              steps: const ['Account', 'Data', 'Library', 'Review'],
              currentStep: 1,
              icon: Icons.folder_open_rounded,
              title: 'Choose a data folder',
              subtitle: 'The database and artwork are stored here.',
              primaryAction: RsButton(
                label: 'Continue',
                autofocus: true,
                variant: RsButtonVariant.primary,
                onPressed: () => next++,
              ),
              secondaryAction: RsButton(label: 'Back', onPressed: () {}),
              child: Column(
                children: [
                  for (var i = 0; i < 8; i++)
                    RsListRow(title: 'Row $i', onPressed: () {}),
                ],
              ),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.text('Choose a data folder'), findsOneWidget);
        if (size == phone) {
          expect(find.text('STEP 2 OF 4 · DATA'), findsOneWidget);
        } else {
          expect(find.text('2  DATA'), findsOneWidget);
        }
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        expect(next, 1);
      });
    }

    testWidgets('changing step keeps form state', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      Widget build(int step) => steamApp(
        RsWizardFrame(
          steps: const ['One', 'Two'],
          currentStep: step,
          title: 'Step $step',
          child: RsTextField(controller: controller, label: 'Name'),
        ),
      );
      await tester.pumpWidget(build(0));
      await tester.enterText(find.byType(EditableText), 'Ada');
      await tester.pumpWidget(build(1));
      await tester.pumpAndSettle();
      expect(find.text('Step 1'), findsOneWidget);
      expect(controller.text, 'Ada');
    });
  });

  group('RsHero', () {
    testWidgets('generated art, title, subtitle and child', (tester) async {
      setScreen(tester, desktop);
      var plays = 0;
      await tester.pumpWidget(
        steamApp(
          ListView(
            children: [
              RsHero(
                title: 'Super Mario 64',
                systemId: 'n64',
                systemName: 'Nintendo 64',
                subtitle: 'Nintendo 64 · 1996',
                logo: MemoryImage(Uint8List.fromList([1, 2, 3])),
                child: RsButton(
                  label: 'Play',
                  variant: RsButtonVariant.primary,
                  onPressed: () => plays++,
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Nintendo 64 · 1996'), findsOneWidget);
      await tester.tap(find.text('Play'));
      expect(plays, 1);
      expect(tester.takeException(), isNull);
    });
  });

  group('RsScaffold', () {
    testWidgets('lays out top bar, body and hints', (tester) async {
      setScreen(tester, desktop);
      await tester.pumpWidget(
        steamApp(
          RsScaffold(
            topBar: RsTopBar(
              items: const [RsNavItem(label: 'Home')],
              selectedIndex: 0,
              onSelected: (_) {},
              showClock: false,
            ),
            hints: const RsButtonHints(
              hints: [RsButtonHint(button: RsControllerButton.a, label: 'OK')],
            ),
            body: const Center(child: Text('Body')),
          ),
        ),
      );
      final top = tester.getRect(find.text('Home'));
      final body = tester.getRect(find.text('Body'));
      final hints = tester.getRect(find.text('OK'));
      expect(top.bottom, lessThan(body.top));
      expect(body.bottom, lessThan(hints.top));
    });

    testWidgets('body can extend behind the top bar', (tester) async {
      setScreen(tester, desktop);
      await tester.pumpWidget(
        steamApp(
          RsScaffold(
            extendBodyBehindTopBar: true,
            background: const ColoredBox(color: Color(0xFF123456)),
            topBar: RsTopBar(
              items: const [RsNavItem(label: 'Home')],
              selectedIndex: 0,
              onSelected: (_) {},
            ),
            body: const Align(
              alignment: Alignment.topLeft,
              child: Text('Hero'),
            ),
          ),
        ),
      );
      expect(tester.getRect(find.text('Hero')).top, 0);
    });
  });
}
